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
    developer.log('Updating user profile for ${user.uid}: ${user.toMap()}');
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

  Stream<List<TransactionModel>> allTransactions(String ownerId) {
    return _db
        .collection('transactions')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
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

  // Explicit Rent Record Sync
  Future<void> ensureRentRecordsExist(String ownerId) async {
    developer.log('ensureRentRecordsExist: checking for $ownerId');
    final units = await allUnits(ownerId).first;
    final tenants = await getAllTenants(ownerId).first;
    final tenantMap = {for (var t in tenants) t.id: t};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // We check Current Month, Previous Month (for overdue), and Next Month (if close)
    final monthsToCheck = [
      DateTime(now.year, now.month - 1, 1),
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 1),
    ];

    final batch = _db.batch();
    bool hasChanges = false;

    for (final unit in units) {
      final tenantId = unit.currentTenantId;
      if (tenantId == null || tenantId.isEmpty) continue;
      final tenant = tenantMap[tenantId];
      if (tenant == null || tenant.status != TenantStatus.active) continue;

      for (final monthDate in monthsToCheck) {
        final monthStr = DateFormat('yyyy-MM').format(monthDate);
        
        // Skip if move-in date is after this month
        if (tenant.moveInDate.isAfter(DateTime(monthDate.year, monthDate.month, DateUtils.getDaysInMonth(monthDate.year, monthDate.month)))) continue;

        final daysInMonth = DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
        final dueDay = unit.rentDueDate;
        final clampedDay = (dueDay > daysInMonth) ? daysInMonth : (dueDay <= 0 ? 1 : dueDay);
        final dueDate = DateTime(monthDate.year, monthDate.month, clampedDay);

        // Logic: 7 days before due date, we ensure the record exists
        if (today.add(const Duration(days: 7)).isAfter(dueDate) || today.isAfter(dueDate)) {
          final query = await _db
              .collection('rent_records')
              .where('unitId', isEqualTo: unit.id)
              .where('tenantId', isEqualTo: tenant.id)
              .where('month', isEqualTo: monthStr)
              .where('title', isEqualTo: 'Monthly Rent') // Only sync auto-rent
              .limit(1)
              .get();

          if (query.docs.isEmpty) {
            developer.log('Creating rent record for ${tenant.name} - $monthStr');
            final ref = _db.collection('rent_records').doc();
            final record = RentRecordModel(
              id: ref.id,
              tenantId: tenant.id,
              propertyId: unit.propertyId,
              unitId: unit.id,
              ownerId: ownerId,
              amount: unit.monthlyRent,
              month: monthStr,
              status: RentStatus.pending,
              dueDate: dueDate,
              title: 'Monthly Rent',
            );
            batch.set(ref, record.toFirestore());
            hasChanges = true;
          }
        }
      }
    }

    if (hasChanges) {
      await batch.commit();
      developer.log('ensureRentRecordsExist: batch committed');
    }
  }

  // Action Center Items (Source of Truth: rent_records)
  Stream<List<ActionItem>> getActionItems(String ownerId) {
    return CombineLatestStream.combine4(
      _db.collection('rent_records').where('ownerId', isEqualTo: ownerId).snapshots(),
      getAllTenants(ownerId),
      getProperties(ownerId),
      allUnits(ownerId),
      (recordsSnap, tenants, properties, units) {
        final records = recordsSnap.docs.map((doc) => RentRecordModel.fromFirestore(doc)).toList();
        final tenantMap = {for (var t in tenants) t.id: t};
        final propertyMap = {for (var p in properties) p.id: p};
        final unitMap = {for (var u in units) u.id: u};
        
        final today = DateTime.now();
        final limitDate = today.add(const Duration(days: 7));

        return records
            .where((r) => r.status != RentStatus.paid)
            .where((r) => r.dueDate.isBefore(limitDate))
            .map((r) {
              final tenant = tenantMap[r.tenantId];
              final prop = propertyMap[r.propertyId];
              final unit = unitMap[r.unitId];
              final isOverdue = today.isAfter(r.dueDate);

              return ActionItem(
                tenant: tenant ?? TenantModel(
                  id: r.tenantId, 
                  name: 'Unknown', 
                  ownerId: ownerId, 
                  propertyId: r.propertyId, 
                  moveInDate: DateTime.now(),
                  dueDate: r.dueDate,
                  assignedUnitId: r.unitId,
                ),
                title: tenant != null ? '${tenant.name} (${r.title})' : r.title,
                subtitle: [
                  '${isOverdue ? 'Overdue' : 'Due'}: ${DateFormat('d MMM yyyy').format(r.dueDate)}',
                  if (prop != null) prop.name,
                  'Unit ${unit?.unitNumber ?? 'N/A'}', 
                ].join(' · '),
                amount: r.amount,
                isOverdue: isOverdue,
                dueDate: r.dueDate,
                month: r.month,
                propertyName: prop?.name ?? '',
                unitNumber: unit?.unitNumber ?? '', 
                rentRecordId: r.id,
                propertyId: r.propertyId,
                unitId: r.unitId,
              );
            })
            .toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      },
    );
  }

  Future<void> recordRentPayment({
    required ActionItem item,
    required String ownerId,
  }) async {
    if (item.rentRecordId == null) return;

    final batch = _db.batch();

    // 1. Update Rent Record to Paid
    final recordRef = _db.collection('rent_records').doc(item.rentRecordId);
    batch.update(recordRef, {
      'status': 'paid',
      'paymentDate': Timestamp.now(),
    });

    // 2. Create Transaction for financial tracking
    final txRef = _db.collection('transactions').doc();
    final transaction = TransactionModel(
      id: txRef.id,
      unitId: item.unitId,
      propertyId: item.propertyId,
      ownerId: ownerId,
      tenantId: item.tenant.id,
      description: 'Payment for ${item.title} (${item.month})',
      amount: item.amount,
      date: DateTime.now(),
      type: TransactionType.income,
      month: item.month,
    );
    batch.set(txRef, transaction.toFirestore());

    await batch.commit();
  }

  Future<void> assignTenantToUnit({
    required String unitId,
    required String tenantId,
    required String propertyId,
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

    final unitRef =
        _db.collection('properties').doc(propertyId).collection('units').doc(unitId);
    batch.update(unitRef, {
      'currentTenantId': tenantId,
      'currentTenancyHistoryId': tenancyHistoryRef.id,
      'status': 'occupied',
    });

    final tenantRef = _db.collection('tenants').doc(tenantId);
    batch.update(tenantRef, {'isAssignedToUnit': true});

    await batch.commit();
  }

  Future<void> unassignTenantFromUnit({
    required String unitId,
    required String tenantId,
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
    }
  }

  Future<void> addPropertyExpense({
    required String propertyId,
    required String ownerId,
    required double totalAmount,
    required String description,
    required List<String> unitIds,
    required String month,
    bool billToTenants = false,
  }) async {
    if (unitIds.isEmpty) return;
    final perUnitAmount = totalAmount / unitIds.length;
    final expenseDate = DateFormat('yyyy-MM').parse(month);
    final transactionDate = DateTime(expenseDate.year, expenseDate.month, 1);

    final batch = _db.batch();
    
    // 1. Create Expense Transactions (Real money out)
    for (final uid in unitIds) {
      final ref = _db.collection('transactions').doc();
      final transaction = TransactionModel(
        id: ref.id,
        unitId: uid,
        propertyId: propertyId,
        ownerId: ownerId,
        description: '$description (Expense)',
        amount: perUnitAmount,
        date: transactionDate,
        type: TransactionType.expense,
        month: month,
      );
      batch.set(ref, transaction.toFirestore());
    }

    // 2. If billable, create RentRecordModel entries (Money expected in)
    if (billToTenants) {
      // We need to find the tenants for these units
      final unitsSnap = await _db.collection('properties').doc(propertyId).collection('units').get();
      final unitMap = {for (var doc in unitsSnap.docs) doc.id: UnitModel.fromFirestore(doc)};
      
      for (final uid in unitIds) {
        final unit = unitMap[uid];
        if (unit != null && unit.currentTenantId != null) {
          final recordRef = _db.collection('rent_records').doc();
          final record = RentRecordModel(
            id: recordRef.id,
            tenantId: unit.currentTenantId!,
            propertyId: propertyId,
            unitId: uid,
            ownerId: ownerId,
            amount: perUnitAmount,
            month: month,
            status: RentStatus.pending,
            dueDate: transactionDate.add(const Duration(days: 14)), // Default 2 weeks to pay
            title: description,
          );
          batch.set(recordRef, record.toFirestore());
        }
      }
    }

    await batch.commit();
  }
}
