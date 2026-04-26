import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/upcoming_due_model.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:myapp/models/tenancy_history_model.dart';
import 'dart:developer' as developer;
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/detailed_tenancy_history_model.dart';
import 'package:myapp/models/rent_record_model.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:myapp/models/action_item_model.dart';
import 'package:myapp/models/rent_status.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Users
  Future<void> setUser(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).set(data);
  }

  Future<void> updateUser(UserModel user) {
    return _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  // Properties
  Stream<List<PropertyModel>> getProperties(String ownerId) {
    return _db
        .collection('properties')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PropertyModel.fromFirestore(doc)).toList());
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
        final tenantRef = _db.collection('tenants').doc(unitData['currentTenantId']);
        batch.update(tenantRef, {'isAssignedToUnit': false});
      }
      batch.delete(doc.reference);
    }

    final propertyRef = _db.collection('properties').doc(propertyId);
    batch.delete(propertyRef);

    await batch.commit();
  }

  // Units
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

  // Tenants
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

  Future<void> updateTenantPhotoUrl(String tenantId, String photoUrl) {
    return _db.collection('tenants').doc(tenantId).update({'photoUrl': photoUrl});
  }

  Future<void> updateTenant(TenantModel tenant) {
    return _db.collection('tenants').doc(tenant.id).update(tenant.toFirestore());
  }

  Future<void> deleteTenant(String tenantId) async {
    final tenantRef = _db.collection('tenants').doc(tenantId);
    final tenantSnapshot = await tenantRef.get();
    final tenantData = tenantSnapshot.data();

    if (tenantData != null && tenantData['isAssignedToUnit'] == true) {
      throw Exception('Cannot delete a tenant who is currently assigned to a unit. Please unassign them first.');
    }

    await tenantRef.delete();
  }

  // Transactions
  Future<void> addTransaction(TransactionModel transaction) {
    developer.log('Adding transaction: ${transaction.toFirestore()}');
    return _db.collection('transactions').add(transaction.toFirestore());
  }

  Stream<List<TransactionModel>> getTransactionsForUnit(String unitId) {
    return _db
        .collection('transactions')
        .where('unitId', isEqualTo: unitId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Stream<List<TransactionModel>> getAllTransactionsForUnit(String unitId) {
    return _db
        .collection('transactions')
        .where('unitId', isEqualTo: unitId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Stream<List<TransactionModel>> allTransactions(String ownerId) {
    return allUnits(ownerId).switchMap((units) {
      if (units.isEmpty) return Stream.value(<TransactionModel>[]);
      final txStreams = units.map((u) => getTransactionsForUnit(u.id));
      return CombineLatestStream.list(txStreams).map(
        (listOfLists) => listOfLists.expand((txs) => txs).toList(),
      );
    });
  }

  // Tenancy History
  Stream<List<DetailedTenancyHistoryModel>> getTenantHistory(String unitId) {
    return _db
        .collectionGroup('tenancyHistory')
        .where('unitId', isEqualTo: unitId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final tenantIds = snapshot.docs.map((doc) => doc.data()['tenantId'] as String).toSet().toList();
      if (tenantIds.isEmpty) return [];

      final tenantsSnapshot = await _db.collection('tenants').where(FieldPath.documentId, whereIn: tenantIds).get();
      final tenants = tenantsSnapshot.docs.map((doc) => TenantModel.fromFirestore(doc)).toList();
      final tenantMap = {for (var tenant in tenants) tenant.id: tenant};

      return snapshot.docs.map((doc) {
        final history = TenancyHistoryModel.fromFirestore(doc);
        final tenant = tenantMap[history.tenantId];
        return tenant != null ? DetailedTenancyHistoryModel(tenant: tenant, history: history) : null;
      }).whereType<DetailedTenancyHistoryModel>().toList();
    });
  }

  Stream<List<UpcomingDue>> getUpcomingDues(String ownerId) {
  return _db
      .collectionGroup('units')
      .where('ownerId', isEqualTo: ownerId)
      .where('currentTenantId', isNotEqualTo: null)
      .snapshots()
      .asyncMap((unitsSnapshot) async {
        final unitDocs = unitsSnapshot.docs;
        if (unitDocs.isEmpty) return [];

        final tenantIds = unitDocs.map((doc) => doc.data()['currentTenantId'] as String).toSet().toList();
        final propertyIds = unitDocs.map((doc) => doc.data()['propertyId'] as String).toSet().toList();

        final tenantsSnapshot = await _db.collection('tenants').where(FieldPath.documentId, whereIn: tenantIds).get();
        final tenants = tenantsSnapshot.docs.map((doc) => TenantModel.fromFirestore(doc)).toList();
        final tenantMap = {for (var tenant in tenants) tenant.id: tenant};

        final propertiesSnapshot = await _db.collection('properties').where(FieldPath.documentId, whereIn: propertyIds).get();
        final properties = propertiesSnapshot.docs.map((doc) => PropertyModel.fromFirestore(doc)).toList();
        final propertyMap = {for (var prop in properties) prop.id: prop};

        final upcomingDues = <UpcomingDue>[];
        final now = DateTime.now();

        for (final unitDoc in unitDocs) {
          final unit = UnitModel.fromFirestore(unitDoc);
          final tenant = tenantMap[unit.currentTenantId];
          final property = propertyMap[unit.propertyId];

          if (tenant != null && property != null) {
            final dueDay = tenant.dueDate.day;
            final dueDate = DateTime(now.year, now.month, dueDay);
            final nextDueDate = dueDate.isBefore(now)
                ? DateTime(now.year, now.month + 1, dueDay)
                : dueDate;

            if (nextDueDate.difference(now).inDays <= 30) {
              upcomingDues.add(UpcomingDue(
                tenant: tenant,
                unit: unit,
                property: property,
                dueDate: nextDueDate,
                amount: unit.monthlyRent,
              ));
            }
          }
        }

        upcomingDues.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        return upcomingDues;
      });
}


  // Complex Operations
  Future<void> assignTenantToUnit({
    required String unitId,
    required String tenantId,
    required String propertyId, // We need propertyId to locate the unit document
  }) async {
    final batch = _db.batch();

    // 1. Create a new tenancy history record
    final tenancyHistoryRef = _db
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection('tenancyHistory')
        .doc(); // New history entry

    final newTenancyRecord = TenancyHistoryModel(
      id: tenancyHistoryRef.id,
      unitId: unitId,
      tenantId: tenantId,
      startDate: DateTime.now(),
    );
    batch.set(tenancyHistoryRef, newTenancyRecord.toMap());

    // 2. Update the unit to link the current tenant and tenancy history
    final unitRef =
        _db.collection('properties').doc(propertyId).collection('units').doc(unitId);
    batch.update(unitRef, {
      'currentTenantId': tenantId,
      'currentTenancyHistoryId': tenancyHistoryRef.id,
      'status': 'occupied',
    });

    // 3. Update the tenant to mark them as assigned
    final tenantRef = _db.collection('tenants').doc(tenantId);
    batch.update(tenantRef, {'isAssignedToUnit': true});

    await batch.commit();
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

  Future<void> unassignTenantFromUnit({
    required String unitId,
    required String tenantId,
    // propertyId is needed if units are subcollections, which they are.
    required String propertyId,
  }) async {
    final batch = _db.batch();

    final unitRef =
        _db.collection('properties').doc(propertyId).collection('units').doc(unitId);
    final unitSnapshot = await unitRef.get();
    final unitData = unitSnapshot.data();

    if (unitData != null && unitData['currentTenantId'] == tenantId) {
      final tenancyHistoryId = unitData['currentTenancyHistoryId'];

      if (tenancyHistoryId != null) {
        final tenancyHistoryRef =
            unitRef.collection('tenancyHistory').doc(tenancyHistoryId);
        batch.update(tenancyHistoryRef, {'endDate': DateTime.now()});
      }

      batch.update(unitRef, {
        'currentTenantId': null,
        'currentTenancyHistoryId': null,
        'status': 'vacant',
      });

      final tenantRef = _db.collection('tenants').doc(tenantId);
      batch.update(tenantRef, {'isAssignedToUnit': false});

      await batch.commit();
    } else {
      throw Exception('Tenant is not assigned to this unit or unit does not exist.');
    }
  }

  // Rent Records
  Stream<List<RentRecordModel>> getRentRecords(String ownerId, String month) {
    return _db
        .collectionGroup('rent_records')
        .where('ownerId', isEqualTo: ownerId)
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentRecordModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<RentRecordModel>> getAllRentRecords(String ownerId) {
    return _db
        .collectionGroup('rent_records')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentRecordModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<RentRecordModel>> getRentRecordsForTenant(String tenantId) {
    return _db
        .collection('rent_records')
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentRecordModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateRentRecord(RentRecordModel record) {
    return _db.collection('rent_records').doc(record.id).update(record.toFirestore());
  }

  Stream<List<TenantModel>> getUnpaidTenantsThisMonth(String ownerId) {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    return _db
        .collection('rent_records')
        .where('ownerId', isEqualTo: ownerId)
        .where('month', isEqualTo: currentMonth)
        .where('status', whereIn: ['pending', 'partial'])
        .snapshots()
        .asyncMap((snapshot) async {
      final tenantIds = snapshot.docs.map((doc) => doc['tenantId'] as String).toSet().toList();
      if (tenantIds.isEmpty) {
        return [];
      }
      final tenantsSnapshot = await _db
          .collection('tenants')
          .where(FieldPath.documentId, whereIn: tenantIds)
          .get();
      return tenantsSnapshot.docs
          .map((doc) => TenantModel.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<ActionItem>> getActionItems(String ownerId) {
    // Use getAllTenants stream as the trigger, then asyncMap to fetch all rent records
    return getAllTenants(ownerId).asyncMap((allTenants) async {
      final assignedTenants = allTenants
          .where((t) => t.isAssignedToUnit && t.status == TenantStatus.active)
          .toList();

      final actionItems = <ActionItem>[];
      if (assignedTenants.isEmpty) return actionItems;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextMonthStart = DateTime(now.year, now.month + 1);

      for (final tenant in assignedTenants) {
        // Fetch this tenant's rent records as a one-time future
        final recordsSnap = await _db
            .collection('rent_records')
            .where('tenantId', isEqualTo: tenant.id)
            .get();

        final records = recordsSnap.docs
            .map((d) => RentRecordModel.fromFirestore(d))
            .toList();

        final paidMonths = <String>{
          for (var r in records.where((r) => r.status == RentStatus.paid)) r.month
        };
        final recordedMonths = <String, RentRecordModel>{
          for (var r in records) r.month: r
        };

        // Walk every month from moveIn up to next month
        var cursor = DateTime(tenant.moveInDate.year, tenant.moveInDate.month);

        while (!cursor.isAfter(nextMonthStart)) {
          final monthStr = DateFormat('yyyy-MM').format(cursor);

          if (!paidMonths.contains(monthStr)) {
            final dueDay = tenant.dueDate.day;
            final daysInMonth = DateUtils.getDaysInMonth(cursor.year, cursor.month);
            final clampedDay = dueDay > daysInMonth ? daysInMonth : dueDay;
            final dueDate = DateTime(cursor.year, cursor.month, clampedDay);

            // For future months: only show if due within 7 days
            if (dueDate.isAfter(today) && dueDate.difference(today).inDays > 7) {
              cursor = DateTime(cursor.year, cursor.month + 1);
              continue;
            }

            final isOverdue = today.isAfter(dueDate);
            final existingRecord = recordedMonths[monthStr];
            final amount = existingRecord?.amount ?? tenant.rentAmount;

            actionItems.add(ActionItem(
              tenant: tenant,
              title: tenant.name,
              subtitle: '${isOverdue ? 'Overdue' : 'Due'}: ${DateFormat.yMMMd().format(dueDate)} ($monthStr)',
              amount: amount,
              isOverdue: isOverdue,
              dueDate: dueDate,
              month: monthStr,
            ));
          }

          cursor = DateTime(cursor.year, cursor.month + 1);
        }
      }

      actionItems.sort((a, b) {
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;
        return a.dueDate.compareTo(b.dueDate);
      });

      return actionItems;
    });
  }

  Future<void> recordRentPayment({
    required String tenantId,
    required String propertyId,
    required String unitId,
    required double amount,
    required String month,
  }) async {
    // 1. Create a RentRecordModel
    final rentRecord = RentRecordModel(
      id: '',
      tenantId: tenantId,
      propertyId: propertyId,
      unitId: unitId,
      amount: amount,
      month: month,
      status: RentStatus.paid,
      paymentDate: DateTime.now(),
      notes: 'Auto-recorded payment',
    );
    await _db.collection('rent_records').add(rentRecord.toFirestore());

    // 2. Create a TransactionModel
    final transaction = TransactionModel(
      id: '',
      unitId: unitId,
      propertyId: propertyId,
      description: 'Rent Payment for $month',
      amount: amount,
      date: DateTime.now(),
      type: TransactionType.income,
    );
    await addTransaction(transaction);
  }
}
