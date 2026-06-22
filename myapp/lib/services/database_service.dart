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
import 'package:myapp/models/notification_model.dart';
import 'package:myapp/models/rent_status.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get currentOwnerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Users
  Future<void> setUser(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).set(data);
  }

  Future<void> updateUser(UserModel user) {
    developer.log('Updating user profile for ${user.uid}: ${user.toMap()}');
    return _db
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Properties
  Stream<List<PropertyModel>> getProperties(String ownerId) {
    final ownedStream = _db
        .collection('properties')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromFirestore(doc))
            .where((p) => p.societyId == null)
            .toList());

    final coOwnedStream = _db
        .collection('properties')
        .where('coOwnerIds', arrayContains: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromFirestore(doc))
            .where((p) => p.societyId == null)
            .toList());

    return CombineLatestStream.combine2(ownedStream, coOwnedStream,
        (List<PropertyModel> owned, List<PropertyModel> coOwned) {
      final allProps = [...owned, ...coOwned];
      final uniqueProps = <String, PropertyModel>{};
      for (var p in allProps) {
        uniqueProps[p.id] = p;
      }
      return uniqueProps.values.toList();
    });
  }

  Future<void> inviteCoOwner(String propertyId, String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw Exception(
          'User with email $email not found. They must sign up first.');
    }

    final uid = query.docs.first.id;
    final property = await _db.collection('properties').doc(propertyId).get();
    if (!property.exists) throw Exception('Property not found.');

    final ownerId = property.data()?['ownerId'];
    if (ownerId == uid)
      throw Exception('This user is already the primary owner.');

    List<String> coOwnerIds =
        List<String>.from(property.data()?['coOwnerIds'] ?? []);
    if (coOwnerIds.contains(uid))
      throw Exception('This user is already a co-owner.');

    coOwnerIds.add(uid);
    await _db
        .collection('properties')
        .doc(propertyId)
        .update({'coOwnerIds': coOwnerIds});
  }

  Stream<List<PropertyModel>> getSocietyProperties(String societyId) {
    return _db
        .collection('properties')
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromFirestore(doc))
            .toList());
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

  Stream<List<Map<String, dynamic>>> allUnitsWithPropertyInfo(String ownerId) {
    return getProperties(ownerId).switchMap((properties) {
      if (properties.isEmpty) {
        return Stream.value(<Map<String, dynamic>>[]);
      }
      final unitStreams = properties.map((prop) {
        return getUnits(prop.id).map((units) {
          return units
              .map((u) => {
                    'unit': u,
                    'propertyName': prop.name,
                    'propertyId': prop.id,
                    'propertyAddress': prop.address,
                  })
              .toList();
        });
      }).toList();

      return CombineLatestStream.list(unitStreams).map((listOfLists) {
        return listOfLists.expand((x) => x).toList();
      });
    });
  }

  Stream<List<Map<String, dynamic>>> societyUnitsWithPropertyInfo(
      String societyId) {
    return getSocietyProperties(societyId).switchMap((properties) {
      if (properties.isEmpty) {
        return Stream.value(<Map<String, dynamic>>[]);
      }
      final unitStreams = properties.map((prop) {
        return getUnits(prop.id).map((units) {
          return units
              .map((u) => {
                    'unit': u,
                    'propertyName': prop.name,
                    'propertyId': prop.id,
                    'propertyAddress': prop.address,
                  })
              .toList();
        });
      }).toList();

      return CombineLatestStream.list(unitStreams).map((listOfLists) {
        return listOfLists.expand((x) => x).toList();
      });
    });
  }

  Stream<List<UnitModel>> allUnits(String ownerId) {
    return allUnitsWithPropertyInfo(ownerId)
        .map((list) => list.map((m) => m['unit'] as UnitModel).toList());
  }

  Stream<List<UnitModel>> getSocietyUnits(String societyId) {
    return societyUnitsWithPropertyInfo(societyId)
        .map((list) => list.map((m) => m['unit'] as UnitModel).toList());
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
  Stream<List<RentRecordModel>> getRentRecordsForTenant(String tenantId) {
    return _db
        .collection('rentRecords')
        .where('tenantId', isEqualTo: tenantId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RentRecordModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<RentRecordModel>> getAllRentRecords(String ownerId) {
    return getProperties(ownerId).switchMap((properties) {
      if (properties.isEmpty) return Stream.value(<RentRecordModel>[]);
      final streams = properties.map((prop) => _db
          .collection('rentRecords')
          .where('propertyId', isEqualTo: prop.id)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => RentRecordModel.fromFirestore(doc))
              .toList()));
      return CombineLatestStream.list(streams)
          .map((listOfLists) => listOfLists.expand((x) => x).toList());
    });
  }

  Future<void> updateRentRecord(RentRecordModel record) {
    return _db
        .collection('rentRecords')
        .doc(record.id)
        .update(record.toFirestore());
  }

  Stream<List<TenantModel>> getTenants(String ownerId) {
    return getProperties(ownerId).switchMap((properties) {
      final streams = <Stream<List<TenantModel>>>[];

      // 1. All tenants owned by the user (assigned and unassigned)
      streams.add(_db
          .collection('tenants')
          .where('ownerId', isEqualTo: ownerId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TenantModel.fromFirestore(doc))
              .toList()));

      // 2. All tenants for properties the user owns or co-owns
      for (var prop in properties) {
        streams.add(_db
            .collection('tenants')
            .where('propertyId', isEqualTo: prop.id)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => TenantModel.fromFirestore(doc))
                .toList()));
      }

      return CombineLatestStream.list(streams).map((listOfLists) {
        final allTenants = listOfLists.expand((x) => x).toList();
        final uniqueTenants = <String, TenantModel>{};
        for (var t in allTenants) {
          uniqueTenants[t.id] = t;
        }
        return uniqueTenants.values.toList();
      });
    });
  }

  Stream<List<TenantModel>> getAllTenants(String ownerId) {
    return getTenants(ownerId);
  }

  Stream<TenantModel?> getTenant(String tenantId) {
    return _db.collection('tenants').doc(tenantId).snapshots().map((snapshot) =>
        snapshot.exists ? TenantModel.fromFirestore(snapshot) : null);
  }

  Stream<List<TenantModel>> getAvailableTenants(String ownerId) {
    return getTenants(ownerId).map((tenants) {
      return tenants
          .where((t) => !t.isAssignedToUnit && t.status == TenantStatus.active)
          .toList();
    });
  }

  Future<DocumentReference> addTenant(TenantModel tenant) {
    return _db.collection('tenants').add(tenant.toFirestore());
  }

  Future<void> updateTenantPhotoUrl(String tenantId, String photoUrl) {
    return _db
        .collection('tenants')
        .doc(tenantId)
        .update({'photoUrl': photoUrl});
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

  Future<void> updateTenant(TenantModel tenant) {
    return _db
        .collection('tenants')
        .doc(tenant.id)
        .update(tenant.toFirestore());
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
    return getProperties(ownerId).switchMap((properties) {
      if (properties.isEmpty) return Stream.value(<TransactionModel>[]);
      final streams = properties.map((prop) => _db
          .collection('transactions')
          .where('propertyId', isEqualTo: prop.id)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList()));
      return CombineLatestStream.list(streams).map((listOfLists) {
        final list = listOfLists.expand((x) => x).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      });
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

      return snapshot.docs
          .map((doc) {
            final history = TenancyHistoryModel.fromFirestore(doc);
            final tenant = tenantMap[history.tenantId];
            return tenant != null
                ? DetailedTenancyHistoryModel(tenant: tenant, history: history)
                : null;
          })
          .whereType<DetailedTenancyHistoryModel>()
          .toList();
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

    await _checkAnnualRentIncreases(ownerId, tenants, units);

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

        final trackingStartDate =
            tenant.rentTrackingStartDate ?? tenant.moveInDate;

        // Skip if month is before tracking start month
        final trackingStartMonth =
            DateTime(trackingStartDate.year, trackingStartDate.month, 1);
        if (monthDate.isBefore(trackingStartMonth)) continue;

        final daysInMonth =
            DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
        final dueDay = unit.rentDueDate;
        final clampedDay =
            (dueDay > daysInMonth) ? daysInMonth : (dueDay <= 0 ? 1 : dueDay);
        final dueDate = DateTime(monthDate.year, monthDate.month, clampedDay);

        // Skip standard rent for tracking start month if the due date is before tracking start date
        if (monthDate.year == trackingStartDate.year &&
            monthDate.month == trackingStartDate.month) {
          if (dueDate.isBefore(trackingStartDate)) {
            developer.log(
                'Skipping standard rent for $monthStr because due date $dueDate is before tracking start date $trackingStartDate');
            continue;
          }
        }

        // Logic: 7 days before due date, we ensure the record exists
        if (today.add(const Duration(days: 7)).isAfter(dueDate) ||
            today.isAfter(dueDate)) {
          final query = await _db
              .collection('rentRecords')
              .where('unitId', isEqualTo: unit.id)
              .where('tenantId', isEqualTo: tenant.id)
              .where('month', isEqualTo: monthStr)
              .get();

          // Do not generate standard rent if any rent record (Monthly Rent or Prorated Rent) already exists for this month
          final hasRentRecord = query.docs.any((doc) {
            final t = doc.data()['title'] as String?;
            return t == 'Monthly Rent' || t == 'Prorated Rent';
          });

          if (!hasRentRecord) {
            developer
                .log('Creating rent record for ${tenant.name} - $monthStr');
            final ref = _db.collection('rentRecords').doc();
            final record = RentRecordModel(
              id: ref.id,
              tenantId: tenant.id,
              propertyId: unit.propertyId,
              unitId: unit.id,
              ownerId: tenant
                  .ownerId, // Set to primary ownerId, not logged-in co-owner
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
      getAllRentRecords(ownerId),
      getAllTenants(ownerId),
      getProperties(ownerId),
      allUnits(ownerId),
      (List<RentRecordModel> records, tenants, properties, units) {
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
            tenant: tenant ??
                TenantModel(
                  id: r.tenantId,
                  name: 'Unknown',
                  ownerId: ownerId,
                  propertyId: r.propertyId,
                  moveInDate: DateTime.now(),
                  dueDate: r.dueDate,
                  assignedUnitId: r.unitId,
                ),
            title: tenant != null ? tenant.name : r.title,
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
        }).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      },
    );
  }

  Future<void> recordRentPayment({
    required ActionItem item,
    required String ownerId,
    DateTime? paymentDate,
  }) async {
    if (item.rentRecordId == null) return;

    final batch = _db.batch();
    final pDate = paymentDate ?? DateTime.now();

    // 1. Update Rent Record to Paid
    final recordRef = _db.collection('rentRecords').doc(item.rentRecordId);
    batch.update(recordRef, {
      'status': 'paid',
      'paymentDate': Timestamp.fromDate(pDate),
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
      date: pDate,
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
    required String ownerId,
    double? proratedAmount,
    DateTime? proratedDueDate,
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

    // Trigger rent record sync for the owner
    await ensureRentRecordsExist(ownerId);
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
      final propertiesSnap = await _db
          .collection('properties')
          .where('ownerId', isEqualTo: tenant.ownerId)
          .get();
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
        status: settlementAmount >= 0 ? RentStatus.paid : RentStatus.pending,
        dueDate: DateTime.now(),
        title: 'Security Deposit Settlement',
        notes: 'Deposit: $securityDeposit, Dues: $totalPending',
      );
      batch.set(settlementRef, settlementRecord.toFirestore());

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
      final unitsSnap = await _db
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .get();
      final unitMap = {
        for (var doc in unitsSnap.docs) doc.id: UnitModel.fromFirestore(doc)
      };

      for (final uid in unitIds) {
        final unit = unitMap[uid];
        if (unit != null && unit.currentTenantId != null) {
          final recordRef = _db.collection('rentRecords').doc();
          final record = RentRecordModel(
            id: recordRef.id,
            tenantId: unit.currentTenantId!,
            propertyId: propertyId,
            unitId: uid,
            ownerId: ownerId,
            amount: perUnitAmount,
            month: month,
            status: RentStatus.pending,
            dueDate: transactionDate
                .add(const Duration(days: 14)), // Default 2 weeks to pay
            title: description,
          );
          batch.set(recordRef, record.toFirestore());
        }
      }
    }

    await batch.commit();
  }

  Stream<List<RentRecordModel>> getRecentRentRecords(String ownerId) {
    return _db
        .collection('rentRecords')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('dueDate', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RentRecordModel.fromFirestore(doc))
            .toList());
  }

  Future<void> recordTransaction({
    required String propertyId,
    required String unitId,
    required String tenantId,
    required double amount,
    required String description,
    required String type,
    required String month,
    DateTime? date,
  }) async {
    final ref = _db.collection('transactions').doc();
    final transaction = TransactionModel(
      id: ref.id,
      unitId: unitId,
      propertyId: propertyId,
      ownerId: currentOwnerId,
      tenantId: tenantId,
      description: description,
      amount: amount,
      date: date ?? DateTime.now(),
      type: type == 'income' ? TransactionType.income : TransactionType.expense,
      month: month,
    );
    await ref.set(transaction.toFirestore());
  }

  // Notifications & Annual Rent Increase
  Future<void> _checkAnnualRentIncreases(
      String ownerId, List<TenantModel> tenants, List<UnitModel> units) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final unitMap = {for (var u in units) u.id: u};
    final batch = _db.batch();
    bool hasChanges = false;

    for (var tenant in tenants) {
      if (tenant.status != TenantStatus.active) continue;

      final startDate = tenant.rentTrackingStartDate ?? tenant.moveInDate;

      // Calculate full years since start date
      int years = today.year - startDate.year;
      if (today.month < startDate.month ||
          (today.month == startDate.month && today.day < startDate.day)) {
        years--;
      }

      if (years > 0) {
        // Expected increase date for the current year
        final expectedIncreaseDate =
            DateTime(startDate.year + years, startDate.month, startDate.day);

        // Check if an increase has already been processed or notified for this expected date
        if (tenant.lastRentIncreaseDate == null ||
            tenant.lastRentIncreaseDate!.isBefore(expectedIncreaseDate)) {
          final unit = unitMap[tenant.assignedUnitId];
          if (unit == null) continue;

          // Check if notification already exists
          final existingQuery = await _db
              .collection('notifications')
              .where('ownerId', isEqualTo: ownerId)
              .where('type',
                  isEqualTo:
                      NotificationType.rentIncrease.toString().split('.').last)
              .where('data.tenantId', isEqualTo: tenant.id)
              .where('data.expectedIncreaseDate',
                  isEqualTo: expectedIncreaseDate.toIso8601String())
              .limit(1)
              .get();

          if (existingQuery.docs.isEmpty) {
            final double currentRent = unit.monthlyRent;
            final double newRent = currentRent * 1.05; // 5% increase

            final notificationRef = _db.collection('notifications').doc();
            final notification = NotificationModel(
              id: notificationRef.id,
              ownerId: ownerId,
              title: 'Annual Rent Increase Due',
              body:
                  '${tenant.name} has completed $years year(s). Consider a 5% rent increase from $currentRent to ${newRent.toStringAsFixed(2)}.',
              type: NotificationType.rentIncrease,
              data: {
                'tenantId': tenant.id,
                'propertyId': tenant.propertyId,
                'unitId': tenant.assignedUnitId,
                'currentRent': currentRent,
                'proposedRent': newRent,
                'expectedIncreaseDate': expectedIncreaseDate.toIso8601String(),
              },
              createdAt: DateTime.now(),
            );

            batch.set(notificationRef, notification.toFirestore());
            hasChanges = true;
          }
        }
      }
    }

    if (hasChanges) {
      await batch.commit();
      developer.log('Generated annual rent increase notifications.');
    }
  }

  Stream<List<NotificationModel>> getNotifications(String ownerId) {
    return _db
        .collection('notifications')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> applyRentIncrease(NotificationModel notification) async {
    if (notification.type != NotificationType.rentIncrease) return;

    final data = notification.data;
    final tenantId = data['tenantId'] as String;
    final unitId = data['unitId'] as String;
    final propertyId = data['propertyId'] as String;
    final proposedRent = (data['proposedRent'] as num).toDouble();
    final expectedIncreaseDate = DateTime.parse(data['expectedIncreaseDate']);

    final batch = _db.batch();

    // Update Unit Rent
    final unitRef = _db
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId);
    batch.update(unitRef, {'monthlyRent': proposedRent});

    // Update Tenant
    final tenantRef = _db.collection('tenants').doc(tenantId);
    batch.update(tenantRef, {
      'rentAmount': proposedRent,
      'lastRentIncreaseDate': Timestamp.fromDate(expectedIncreaseDate)
    });

    // Mark Notification as read/accepted
    final notifRef = _db.collection('notifications').doc(notification.id);
    batch.update(notifRef, {'isRead': true});

    await batch.commit();
  }

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
