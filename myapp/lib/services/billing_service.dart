import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/rent_record_model.dart';
import 'package:myapp/models/action_item_model.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:myapp/models/rent_status.dart';
import 'package:myapp/models/invoice_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:developer' as developer;
import 'package:myapp/models/society_model.dart';

/// Service for billing: rent records, action items, invoices, property expenses.
/// Extracted from the monolithic DatabaseService for maintainability.
class BillingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────
  // Rent Records
  // ──────────────────────────────────────────────

  Stream<List<RentRecordModel>> getRentRecordsForTenant(String tenantId) {
    return _db
        .collection('rentRecords')
        .where('tenantId', isEqualTo: tenantId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => RentRecordModel.fromFirestore(doc)).toList());
  }

  Stream<List<RentRecordModel>> getAllRentRecords(String ownerId) {
    return _db
        .collection('rentRecords')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => RentRecordModel.fromFirestore(doc)).toList());
  }

  Stream<List<RentRecordModel>> getRecentRentRecords(String ownerId) {
    return _db
        .collection('rentRecords')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('dueDate', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => RentRecordModel.fromFirestore(doc)).toList());
  }

  Future<void> updateRentRecord(RentRecordModel record) {
    return _db
        .collection('rentRecords')
        .doc(record.id)
        .update(record.toFirestore());
  }

  // ──────────────────────────────────────────────
  // Rent Record Auto-Generation
  // ──────────────────────────────────────────────

  /// Ensures rent records exist for all active tenants for the current
  /// and adjacent months. Called after tenant assignment and on app startup.
  Future<void> ensureRentRecordsExist(
    String ownerId, {
    required Stream<List<UnitModel>> Function(String) allUnitsStream,
    required Stream<List<TenantModel>> Function(String) allTenantsStream,
  }) async {
    developer.log('ensureRentRecordsExist: checking for $ownerId');
    final units = await allUnitsStream(ownerId).first;
    final tenants = await allTenantsStream(ownerId).first;
    final tenantMap = {for (var t in tenants) t.id: t};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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

        final trackingStartDate = tenant.rentTrackingStartDate ?? tenant.moveInDate;

        // Skip if month is before tracking start month
        final trackingStartMonth = DateTime(trackingStartDate.year, trackingStartDate.month, 1);
        if (monthDate.isBefore(trackingStartMonth)) continue;

        final daysInMonth =
            DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
        final dueDay = unit.rentDueDate;
        final clampedDay =
            (dueDay > daysInMonth) ? daysInMonth : (dueDay <= 0 ? 1 : dueDay);
        final dueDate =
            DateTime(monthDate.year, monthDate.month, clampedDay);

        // Skip standard rent for tracking start month if the due date is before tracking start date
        if (monthDate.year == trackingStartDate.year && monthDate.month == trackingStartDate.month) {
          if (dueDate.isBefore(trackingStartDate)) {
            developer.log('Skipping standard rent for $monthStr because due date $dueDate is before tracking start date $trackingStartDate');
            continue;
          }
        }

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

  // ──────────────────────────────────────────────
  // Action Center (Pending Collection)
  // ──────────────────────────────────────────────

  Stream<List<ActionItem>> getActionItems(
    String ownerId, {
    required Stream<List<TenantModel>> Function(String) getAllTenants,
    required Stream<List<PropertyModel>> Function(String) getProperties,
    required Stream<List<UnitModel>> Function(String) allUnits,
  }) {
    return CombineLatestStream.combine4(
      _db
          .collection('rentRecords')
          .where('ownerId', isEqualTo: ownerId)
          .snapshots(),
      getAllTenants(ownerId),
      getProperties(ownerId),
      allUnits(ownerId),
      (recordsSnap, tenants, properties, units) {
        final records = recordsSnap.docs
            .map((doc) => RentRecordModel.fromFirestore(doc))
            .toList();
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
                title: tenant != null
                    ? '${tenant.name} (${r.title})'
                    : r.title,
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

  // ──────────────────────────────────────────────
  // Payment Recording
  // ──────────────────────────────────────────────

  Future<void> recordRentPayment({
    required ActionItem item,
    required String ownerId,
  }) async {
    if (item.rentRecordId == null) return;

    final batch = _db.batch();

    final recordRef =
        _db.collection('rentRecords').doc(item.rentRecordId);
    batch.update(recordRef, {
      'status': 'paid',
      'paymentDate': Timestamp.now(),
    });

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

  // ──────────────────────────────────────────────
  // Property Expenses
  // ──────────────────────────────────────────────

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
    final transactionDate =
        DateTime(expenseDate.year, expenseDate.month, 1);

    final batch = _db.batch();

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

    if (billToTenants) {
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
            dueDate:
                transactionDate.add(const Duration(days: 14)),
            title: description,
          );
          batch.set(recordRef, record.toFirestore());
        }
      }
    }

    await batch.commit();
  }

  // ──────────────────────────────────────────────
  // Invoices
  // ──────────────────────────────────────────────

  Stream<List<InvoiceModel>> getInvoices({
    String? ownerId,
    String? societyId,
    String? residentId,
    InvoiceStatus? status,
  }) {
    Query query = _db.collection('invoices');
    if (societyId != null) {
      query = query.where('societyId', isEqualTo: societyId);
    } else if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    } else if (residentId != null) {
      query = query.where('residentId', isEqualTo: residentId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.toString());
    }
    return query.snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => InvoiceModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.issueDate.compareTo(a.issueDate));
      return list;
    });
  }

  Stream<List<InvoiceModel>> getInvoicesForUnit(String unitId) {
    return _db
        .collection('invoices')
        .where('unitId', isEqualTo: unitId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => InvoiceModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.issueDate.compareTo(a.issueDate));
      return list;
    });
  }

  Stream<InvoiceModel> getInvoiceStream(String invoiceId) {
    return _db
        .collection('invoices')
        .doc(invoiceId)
        .snapshots()
        .map((doc) => InvoiceModel.fromFirestore(doc));
  }

  Future<String> createInvoice(InvoiceModel invoice) async {
    final ref = _db.collection('invoices').doc();
    final newInvoice = InvoiceModel.create(
      id: ref.id,
      societyId: invoice.societyId,
      ownerId: invoice.ownerId,
      unitId: invoice.unitId,
      propertyId: invoice.propertyId,
      residentId: invoice.residentId,
      residentName: invoice.residentName,
      unitNumber: invoice.unitNumber,
      propertyName: invoice.propertyName,
      lineItems: invoice.lineItems,
      gstNumber: invoice.gstNumber,
      billingMonth: invoice.billingMonth,
      issueDate: invoice.issueDate,
      dueDate: invoice.dueDate,
      notes: invoice.notes,
      createdBy: invoice.createdBy,
    );
    await ref.set(newInvoice.toFirestore());
    developer.log('Invoice created: ${ref.id}');
    return ref.id;
  }

  Future<void> updateInvoiceStatus({
    required String invoiceId,
    required InvoiceStatus status,
    DateTime? paidDate,
    String? paymentMethod,
    String? paymentReference,
  }) {
    return _db.collection('invoices').doc(invoiceId).update({
      'status': status.toString(),
      if (paidDate != null) 'paidDate': Timestamp.fromDate(paidDate),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentReference != null) 'paymentReference': paymentReference,
    });
  }

  Future<void> markInvoicePaid({
    required String invoiceId,
    required String ownerId,
    String? paymentMethod,
    String? paymentReference,
  }) async {
    final doc = await _db.collection('invoices').doc(invoiceId).get();
    final invoice = InvoiceModel.fromFirestore(doc);
    final batch = _db.batch();

    batch.update(_db.collection('invoices').doc(invoiceId), {
      'status': InvoiceStatus.paid.toString(),
      'paidDate': Timestamp.now(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentReference != null) 'paymentReference': paymentReference,
    });

    final txRef = _db.collection('transactions').doc();
    final tx = TransactionModel(
      id: txRef.id,
      unitId: invoice.unitId,
      propertyId: invoice.propertyId,
      ownerId: ownerId,
      tenantId: invoice.residentId,
      description:
          'Invoice payment — ${invoice.billingMonth} (${invoice.propertyName} Unit ${invoice.unitNumber})',
      amount: invoice.grandTotal,
      date: DateTime.now(),
      type: TransactionType.income,
      month: invoice.billingMonth,
    );
    batch.set(txRef, tx.toFirestore());
    await batch.commit();
    developer.log('Invoice $invoiceId marked paid');
  }

  Future<void> deleteInvoice(String invoiceId) {
    return _db.collection('invoices').doc(invoiceId).delete();
  }

  /// Automatically applies a standard late fee to all overdue invoices that don't already have it.
  Future<int> applyLateFeesToOverdueInvoices(String societyId, SocietySettings settings, {double? customFeeAmount}) async {
    if (!settings.lateFeeEnabled) return 0;
    
    final feeAmount = customFeeAmount ?? settings.lateFeeFlat ?? 500.0;

    final query = await _db
        .collection('invoices')
        .where('societyId', isEqualTo: societyId)
        .where('status', isEqualTo: InvoiceStatus.sent.toString())
        .get();

    final now = DateTime.now();
    int updatedCount = 0;
    final batch = _db.batch();

    for (var doc in query.docs) {
      final invoice = InvoiceModel.fromFirestore(doc);
      if (invoice.isOverdue) {
        // Check if a late fee is already applied
        final hasLateFee = invoice.lineItems.any((item) => item.category == InvoiceCategory.lateFee);
        
        if (!hasLateFee) {
          final updatedLineItems = List<InvoiceLineItem>.from(invoice.lineItems)
            ..add(InvoiceLineItem(
              description: 'Late Payment Fee',
              category: InvoiceCategory.lateFee,
              amount: feeAmount,
            ));
          
          final newTotal = updatedLineItems.fold<double>(0, (sum, item) => sum + item.amount);
          
          batch.update(doc.reference, {
            'lineItems': updatedLineItems.map((e) => e.toMap()).toList(),
            'grandTotal': newTotal + invoice.totalGst, // naive recalc for demo
          });
          updatedCount++;
        }
      }
    }

    if (updatedCount > 0) {
      await batch.commit();
      developer.log('Applied late fees to $updatedCount invoices.');
    }
    return updatedCount;
  }

  /// Automatically generates invoices for all units in a society for the current month.
  /// Skips units that already have an invoice for this month.
  Future<int> autoGenerateMonthlyInvoices(String societyId, SocietySettings settings) async {
    if (!settings.autoGenerateInvoices) return 0;

    final now = DateTime.now();
    final billingMonth = DateFormat('yyyy-MM').format(now);
    
    // Get all properties in this society
    final propertiesSnap = await _db
        .collection('properties')
        .where('societyId', isEqualTo: societyId)
        .get();

    int count = 0;
    final batch = _db.batch();

    for (final propDoc in propertiesSnap.docs) {
      final prop = PropertyModel.fromFirestore(propDoc);
      
      // Get all units for this property
      final unitsSnap = await propDoc.reference.collection('units').get();
      
      for (final unitDoc in unitsSnap.docs) {
        final unit = UnitModel.fromFirestore(unitDoc);
        if (unit.currentTenantId == null) continue;

        // Check if invoice already exists
        final existing = await _db
            .collection('invoices')
            .where('unitId', isEqualTo: unit.id)
            .where('billingMonth', isEqualTo: billingMonth)
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          final ref = _db.collection('invoices').doc();
          final invoice = InvoiceModel.create(
            id: ref.id,
            societyId: societyId,
            unitId: unit.id,
            propertyId: prop.id,
            residentId: unit.currentTenantId!,
            residentName: 'Resident ${unit.unitNumber}', // Ideally fetch real name
            unitNumber: unit.unitNumber,
            propertyName: prop.name,
            lineItems: [
              InvoiceLineItem(
                description: 'Monthly Maintenance / Rent',
                category: InvoiceCategory.maintenance,
                amount: unit.monthlyRent,
              ),
            ],
            billingMonth: billingMonth,
            issueDate: now,
            dueDate: DateTime(now.year, now.month, settings.defaultDueDay).add(const Duration(days: 30)),
            createdBy: 'System Auto-Gen',
          );
          batch.set(ref, invoice.toFirestore());
          count++;
        }
      }
    }

    if (count > 0) {
      await batch.commit();
      developer.log('Auto-generated $count invoices for $societyId');
    }
    return count;
  }

  // ──────────────────────────────────────────────
  // GST Calculation Helpers
  // ──────────────────────────────────────────────

  /// Per Indian GST rules, maintenance charges above ₹7,500/month
  /// per flat attract 18% GST.
  static double calculateGst({
    required double amount,
    required double gstRate,
    double threshold = 7500.0,
  }) {
    if (amount <= threshold) return 0.0;
    return double.parse(((amount * gstRate) / 100).toStringAsFixed(2));
  }

  /// Builds a line item with automatic GST calculation applied.
  static InvoiceLineItem buildLineItem({
    required String description,
    required InvoiceCategory category,
    required double amount,
    double? gstRate,
    double gstThreshold = 7500.0,
  }) {
    double gstAmount = 0.0;
    if (gstRate != null && gstRate > 0) {
      gstAmount = calculateGst(
        amount: amount,
        gstRate: gstRate,
        threshold: gstThreshold,
      );
    }
    return InvoiceLineItem(
      description: description,
      category: category,
      amount: amount,
      gstRate: gstRate,
      gstAmount: gstAmount,
    );
  }

  Stream<double> getSocietyTotalCollections(String societyId) {
    return getInvoices(societyId: societyId, status: InvoiceStatus.paid)
        .map((invoices) => invoices.fold(0.0, (sum, i) => sum + i.grandTotal));
  }
}
