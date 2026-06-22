import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/tenancy_history_model.dart';
import 'package:myapp/models/rent_record_model.dart';
import 'package:myapp/models/rent_status.dart';
import 'package:intl/intl.dart';



/// Service for tenant lifecycle: CRUD, assignment, move-in/move-out, security deposits.
/// Extracted from the monolithic DatabaseService for maintainability.
class TenantService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────
  // Tenant CRUD
  // ──────────────────────────────────────────────

  Stream<List<TenantModel>> getTenants(String ownerId) {
    return _db
        .collection('tenants')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TenantModel.fromFirestore(doc)).toList());
  }

  Stream<List<TenantModel>> getAllTenants(String ownerId) {
    return _db
        .collection('tenants')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TenantModel.fromFirestore(doc)).toList());
  }

  Stream<TenantModel?> getTenant(String tenantId) {
    return _db
        .collection('tenants')
        .doc(tenantId)
        .snapshots()
        .map((snapshot) =>
            snapshot.exists ? TenantModel.fromFirestore(snapshot) : null);
  }

  Stream<TenantModel> getTenantStream(String tenantId) {
    return _db
        .collection('tenants')
        .doc(tenantId)
        .snapshots()
        .map((doc) => TenantModel.fromFirestore(doc));
  }

  Future<TenantModel?> getTenantFuture(String tenantId) async {
    final doc = await _db.collection('tenants').doc(tenantId).get();
    if (!doc.exists) return null;
    return TenantModel.fromFirestore(doc);
  }

  Stream<List<TenantModel>> getAvailableTenants(String ownerId) {
    return _db
        .collection('tenants')
        .where('ownerId', isEqualTo: ownerId)
        .where('isAssignedToUnit', isEqualTo: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TenantModel.fromFirestore(doc)).toList());
  }

  Future<DocumentReference> addTenant(TenantModel tenant) {
    return _db.collection('tenants').add(tenant.toFirestore());
  }

  Future<void> updateTenant(TenantModel tenant) {
    return _db.collection('tenants').doc(tenant.id).update(tenant.toFirestore());
  }

  Future<void> updateTenantPhotoUrl(String tenantId, String photoUrl) {
    return _db.collection('tenants').doc(tenantId).update({'photoUrl': photoUrl});
  }

  Future<void> deleteTenant(String tenantId) async {
    final tenantRef = _db.collection('tenants').doc(tenantId);
    final tenantSnapshot = await tenantRef.get();
    final tenantData = tenantSnapshot.data();

    if (tenantData != null && tenantData['isAssignedToUnit'] == true) {
      throw Exception(
          'Cannot delete a tenant who is currently assigned to a unit. Please unassign them first.');
    }

    await tenantRef.delete();
  }

  // ──────────────────────────────────────────────
  // Tenant Assignment (Move-in / Move-out)
  // ──────────────────────────────────────────────

  Future<void> assignTenantToUnit({
    required String unitId,
    required String tenantId,
    required String propertyId,
    required String ownerId,
    double? proratedAmount,
    DateTime? proratedDueDate,
    Future<void> Function(String)? onAssigned,
  }) async {
    final batch = _db.batch();

    final tenancyHistoryRef = _db
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection('tenancyHistory')
        .doc();

    final newTenancyRecord = TenancyHistoryModel(
      id: tenancyHistoryRef.id,
      unitId: unitId,
      tenantId: tenantId,
      startDate: DateTime.now(),
    );
    batch.set(tenancyHistoryRef, newTenancyRecord.toMap());

    final unitRef = _db
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId);
    batch.update(unitRef, {
      'currentTenantId': tenantId,
      'currentTenancyHistoryId': tenancyHistoryRef.id,
      'status': 'occupied',
    });

    final tenantRef = _db.collection('tenants').doc(tenantId);
    batch.update(tenantRef, {
      'isAssignedToUnit': true,
      'propertyId': propertyId,
      'assignedUnitId': unitId,
    });

    // Create Prorated Rent record if provided
    if (proratedAmount != null && proratedAmount > 0) {
      final rentRecordRef = _db.collection('rentRecords').doc();
      final proratedRecord = RentRecordModel(
        id: rentRecordRef.id,
        tenantId: tenantId,
        propertyId: propertyId,
        unitId: unitId,
        ownerId: ownerId,
        amount: proratedAmount,
        month: DateFormat('yyyy-MM').format(DateTime.now()),
        status: RentStatus.pending,
        dueDate: proratedDueDate ?? DateTime.now(),
        title: 'Prorated Rent',
        notes: 'Prorated rent for partial month',
      );
      batch.set(rentRecordRef, proratedRecord.toFirestore());
    }

    await batch.commit();

    // Trigger rent record sync for the owner (callback from billing service)
    if (onAssigned != null) {
      await onAssigned(ownerId);
    }
  }

  Future<void> unassignTenantFromUnit({
    required String unitId,
    required String tenantId,
    required String propertyId,
  }) async {
    final batch = _db.batch();

    final unitRef = _db
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId);
    final unitSnapshot = await unitRef.get();
    final unitData = unitSnapshot.data();

    if (unitData != null && unitData['currentTenantId'] == tenantId) {
      final tenancyHistoryId = unitData['currentTenancyHistoryId'];

      // 1. Fetch Tenant and Pending Dues
      final tenantDoc = await _db.collection('tenants').doc(tenantId).get();
      final tenant = TenantModel.fromFirestore(tenantDoc);
      final tenantRef = _db.collection('tenants').doc(tenantId);

      final pendingRecordsSnap = await _db
          .collection('rentRecords')
          .where('tenantId', isEqualTo: tenantId)
          .where('status', isEqualTo: RentStatus.pending.toString())
          .get();
      final pendingRecords = pendingRecordsSnap.docs
          .map((doc) => RentRecordModel.fromFirestore(doc))
          .toList();

      double totalPending = pendingRecords.fold(0, (sum, r) => sum + r.amount);
      double securityDeposit = tenant.securityDeposit;
      double settlementAmount = securityDeposit - totalPending;

      // 2. Process Settlement in Batch
      if (tenancyHistoryId != null) {
        final tenancyHistoryRef =
            unitRef.collection('tenancyHistory').doc(tenancyHistoryId);
        batch.update(tenancyHistoryRef, {'endDate': DateTime.now()});
      }

      batch.update(unitRef, {
        'currentTenantId': null,
        'currentTenancyHistoryId': null,
        'status': 'vacant',
        'lastVacatedDate': Timestamp.now(),
      });

      // Find if tenant is assigned to other units
      final propertiesSnap = await _db.collection('properties').where('ownerId', isEqualTo: tenant.ownerId).get();
      bool assignedElsewhere = false;
      for (var propDoc in propertiesSnap.docs) {
        final unitsSnap = await propDoc.reference.collection('units').get();
        for (var uDoc in unitsSnap.docs) {
          if (uDoc.id != unitId && uDoc.data()['currentTenantId'] == tenantId) {
            assignedElsewhere = true;
            break;
          }
        }
        if (assignedElsewhere) break;
      }

      if (!assignedElsewhere) {
        batch.update(tenantRef, {
          'isAssignedToUnit': false,
          'assignedUnitId': '',
          'propertyId': '',
          'status': TenantStatus.past.toString(),
        });
      }

      // 3. Mark pending as paid via deposit if possible
      for (var doc in pendingRecordsSnap.docs) {
        batch.update(doc.reference, {
          'status': RentStatus.paid.toString(),
          'notes': 'Paid via Security Deposit'
        });
      }

      // 4. Create settlement record
      final settlementRef = _db.collection('rentRecords').doc();
      final settlementRecord = RentRecordModel(
        id: settlementRef.id,
        tenantId: tenantId,
        propertyId: propertyId,
        unitId: unitId,
        ownerId: tenant.ownerId,
        amount: settlementAmount,
        month: DateFormat('yyyy-MM').format(DateTime.now()),
        status:
            settlementAmount >= 0 ? RentStatus.paid : RentStatus.pending,
        dueDate: DateTime.now(),
        title: 'Security Deposit Settlement',
        notes: 'Deposit: $securityDeposit, Dues: $totalPending',
      );
      batch.set(settlementRef, settlementRecord.toFirestore());

      await batch.commit();
    }
  }
}
