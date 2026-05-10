import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/tenancy_history_model.dart';
import 'package:myapp/models/detailed_tenancy_history_model.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:rxdart/rxdart.dart';

/// Service for property and unit CRUD operations.
/// Extracted from the monolithic DatabaseService for maintainability.
class PropertyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────
  // Properties
  // ──────────────────────────────────────────────

  Stream<List<PropertyModel>> getProperties(String ownerId) {
    return _db
        .collection('properties')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PropertyModel.fromFirestore(doc)).toList());
  }

  Stream<PropertyModel> getPropertyStream(String propertyId) {
    return _db
        .collection('properties')
        .doc(propertyId)
        .snapshots()
        .map((doc) => PropertyModel.fromFirestore(doc));
  }

  Future<void> addProperty(PropertyModel property) {
    return _db.collection('properties').add(property.toFirestore());
  }

  Future<void> updateProperty(PropertyModel property) {
    return _db
        .collection('properties')
        .doc(property.id)
        .update(property.toFirestore());
  }

  Future<void> deleteProperty(String propertyId) async {
    final unitsSnapshot = await _db
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .get();

    final batch = _db.batch();

    for (var doc in unitsSnapshot.docs) {
      final unitData = doc.data();
      if (unitData['currentTenantId'] != null) {
        final tenantRef =
            _db.collection('tenants').doc(unitData['currentTenantId']);
        batch.update(tenantRef, {'isAssignedToUnit': false});
      }
      batch.delete(doc.reference);
    }

    final propertyRef = _db.collection('properties').doc(propertyId);
    batch.delete(propertyRef);

    await batch.commit();
  }

  // ──────────────────────────────────────────────
  // Units
  // ──────────────────────────────────────────────

  Stream<List<UnitModel>> getUnits(String propertyId) {
    return _db
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UnitModel.fromFirestore(doc)).toList());
  }

  Stream<List<UnitModel>> allUnits(String ownerId) {
    return getProperties(ownerId).switchMap((properties) {
      if (properties.isEmpty) {
        return Stream.value(<UnitModel>[]);
      }
      final unitStreams = properties.map((prop) => getUnits(prop.id));
      return CombineLatestStream.list(unitStreams).map(
        (listOfLists) => listOfLists.expand((units) => units).toList(),
      );
    });
  }

  Stream<UnitModel> getUnitStream(String unitId, String propertyId) {
    return _db
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .snapshots()
        .map((snapshot) => UnitModel.fromFirestore(snapshot));
  }

  Future<void> addUnit(UnitModel unit, String ownerId) {
    final newUnit = unit.copyWith(ownerId: ownerId);
    return _db
        .collection('properties')
        .doc(newUnit.propertyId)
        .collection('units')
        .add(newUnit.toFirestore());
  }

  Future<void> updateUnit(UnitModel unit) {
    return _db
        .collection('properties')
        .doc(unit.propertyId)
        .collection('units')
        .doc(unit.id)
        .update(unit.toFirestore());
  }

  Future<void> deleteUnit(String id, String propertyId) async {
    final unitRef = _db
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(id);

    final unitSnapshot = await unitRef.get();
    final unitData = unitSnapshot.data();

    final batch = _db.batch();

    if (unitData != null && unitData['currentTenantId'] != null) {
      final tenantId = unitData['currentTenantId'];
      final tenantRef = _db.collection('tenants').doc(tenantId);
      batch.update(tenantRef, {'isAssignedToUnit': false});
    }

    batch.delete(unitRef);
    await batch.commit();
  }

  // ──────────────────────────────────────────────
  // Tenancy History
  // ──────────────────────────────────────────────

  Stream<List<TenancyHistoryModel>> getTenancyHistory(
      String propertyId, String unitId) {
    return _db
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection('tenancyHistory')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TenancyHistoryModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<DetailedTenancyHistoryModel>> getTenantHistory(String unitId) {
    return _db
        .collectionGroup('tenancyHistory')
        .where('unitId', isEqualTo: unitId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final tenantIds = snapshot.docs
          .map((doc) => doc.data()['tenantId'] as String)
          .toSet()
          .toList();
      if (tenantIds.isEmpty) return [];

      final tenantsSnapshot = await _db
          .collection('tenants')
          .where(FieldPath.documentId, whereIn: tenantIds)
          .get();
      final tenants = tenantsSnapshot.docs
          .map((doc) => TenantModel.fromFirestore(doc))
          .toList();
      final tenantMap = {for (var tenant in tenants) tenant.id: tenant};

      return snapshot.docs.map((doc) {
        final history = TenancyHistoryModel.fromFirestore(doc);
        final tenant = tenantMap[history.tenantId];
        return tenant != null
            ? DetailedTenancyHistoryModel(tenant: tenant, history: history)
            : null;
      }).whereType<DetailedTenancyHistoryModel>().toList();
    });
  }

  // ──────────────────────────────────────────────
  // Maintenance Contacts
  // ──────────────────────────────────────────────

  Stream<List<MaintenanceContact>> getNearbyMaintenanceContacts(
      String city, String excludePropertyId) {
    return _db
        .collection('properties')
        .where('city', isEqualTo: city)
        .snapshots()
        .map((snap) {
      List<MaintenanceContact> nearby = [];
      for (var doc in snap.docs) {
        if (doc.id == excludePropertyId) continue;
        final prop = PropertyModel.fromFirestore(doc);
        nearby.addAll(prop.maintenanceContacts);
      }
      return nearby;
    });
  }
}
