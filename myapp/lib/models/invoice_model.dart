import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceStatus { draft, sent, paid, overdue, cancelled }

enum InvoiceCategory {
  maintenance,
  utility,
  parking,
  amenity,
  penalty,
  special,
  rent,
  lateFee,
  other,
}

extension InvoiceCategoryLabel on InvoiceCategory {
  String get label {
    switch (this) {
      case InvoiceCategory.maintenance:
        return 'Maintenance';
      case InvoiceCategory.utility:
        return 'Utility';
      case InvoiceCategory.parking:
        return 'Parking';
      case InvoiceCategory.amenity:
        return 'Amenity';
      case InvoiceCategory.penalty:
        return 'Penalty / Late Fee';
      case InvoiceCategory.special:
        return 'Special Levy';
      case InvoiceCategory.rent:
        return 'Rent';
      case InvoiceCategory.lateFee:
        return 'Late Fee';
      case InvoiceCategory.other:
        return 'Other';
    }
  }
}

/// A single line item on an invoice (e.g. "Maintenance: ₹2000", "Water: ₹300").
class InvoiceLineItem {
  final String description;
  final InvoiceCategory category;
  final double amount;
  final double? gstRate; // e.g. 18.0 — if null, GST not applicable
  final double gstAmount;

  InvoiceLineItem({
    required this.description,
    required this.category,
    required this.amount,
    this.gstRate,
    this.gstAmount = 0.0,
  });

  double get totalWithGst => amount + gstAmount;

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItem(
      description: map['description'] ?? '',
      category: InvoiceCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
        orElse: () => InvoiceCategory.other,
      ),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      gstRate: (map['gstRate'] as num?)?.toDouble(),
      gstAmount: (map['gstAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'category': category.toString(),
      'amount': amount,
      'gstRate': gstRate,
      'gstAmount': gstAmount,
    };
  }
}

/// Full invoice document. Supports both standalone mode (ownerId scoped)
/// and society ERP mode (societyId scoped).
class InvoiceModel {
  final String id;
  final String? societyId; // null in standalone mode
  final String? ownerId;   // null in society mode
  final String unitId;
  final String propertyId;
  final String residentId; // tenantId or userId
  final String residentName;
  final String unitNumber;
  final String propertyName;
  final List<InvoiceLineItem> lineItems;
  final double subtotal;
  final double totalGst;
  final double grandTotal;
  final String? gstNumber; // Society's GSTIN
  final String billingMonth; // Format: yyyy-MM
  final InvoiceStatus status;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? paymentReference; // UPI transaction ID, cheque no., etc.
  final String? notes;
  final String? createdBy;

  InvoiceModel({
    required this.id,
    this.societyId,
    this.ownerId,
    required this.unitId,
    required this.propertyId,
    required this.residentId,
    required this.residentName,
    required this.unitNumber,
    required this.propertyName,
    required this.lineItems,
    required this.subtotal,
    required this.totalGst,
    required this.grandTotal,
    this.gstNumber,
    required this.billingMonth,
    this.status = InvoiceStatus.draft,
    required this.issueDate,
    required this.dueDate,
    this.paidDate,
    this.paymentMethod,
    this.paymentReference,
    this.notes,
    this.createdBy,
  });

  bool get isOverdue =>
      status != InvoiceStatus.paid &&
      status != InvoiceStatus.cancelled &&
      DateTime.now().isAfter(dueDate);

  /// Creates an invoice from individual line items with automatic GST calculation.
  factory InvoiceModel.create({
    required String id,
    String? societyId,
    String? ownerId,
    required String unitId,
    required String propertyId,
    required String residentId,
    required String residentName,
    required String unitNumber,
    required String propertyName,
    required List<InvoiceLineItem> lineItems,
    String? gstNumber,
    required String billingMonth,
    required DateTime issueDate,
    required DateTime dueDate,
    String? notes,
    String? createdBy,
  }) {
    final subtotal = lineItems.fold(0.0, (sum, item) => sum + item.amount);
    final totalGst = lineItems.fold(0.0, (sum, item) => sum + item.gstAmount);
    return InvoiceModel(
      id: id,
      societyId: societyId,
      ownerId: ownerId,
      unitId: unitId,
      propertyId: propertyId,
      residentId: residentId,
      residentName: residentName,
      unitNumber: unitNumber,
      propertyName: propertyName,
      lineItems: lineItems,
      subtotal: subtotal,
      totalGst: totalGst,
      grandTotal: subtotal + totalGst,
      gstNumber: gstNumber,
      billingMonth: billingMonth,
      issueDate: issueDate,
      dueDate: dueDate,
      notes: notes,
      createdBy: createdBy,
    );
  }

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceModel(
      id: doc.id,
      societyId: data['societyId'],
      ownerId: data['ownerId'],
      unitId: data['unitId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      residentId: data['residentId'] ?? '',
      residentName: data['residentName'] ?? '',
      unitNumber: data['unitNumber'] ?? '',
      propertyName: data['propertyName'] ?? '',
      lineItems: (data['lineItems'] as List? ?? [])
          .map((e) => InvoiceLineItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      totalGst: (data['totalGst'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (data['grandTotal'] as num?)?.toDouble() ?? 0.0,
      gstNumber: data['gstNumber'],
      billingMonth: data['billingMonth'] ?? '',
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      issueDate: (data['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidDate: (data['paidDate'] as Timestamp?)?.toDate(),
      paymentMethod: data['paymentMethod'],
      paymentReference: data['paymentReference'],
      notes: data['notes'],
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'societyId': societyId,
      'ownerId': ownerId,
      'unitId': unitId,
      'propertyId': propertyId,
      'residentId': residentId,
      'residentName': residentName,
      'unitNumber': unitNumber,
      'propertyName': propertyName,
      'lineItems': lineItems.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'totalGst': totalGst,
      'grandTotal': grandTotal,
      'gstNumber': gstNumber,
      'billingMonth': billingMonth,
      'status': status.toString(),
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'notes': notes,
      'createdBy': createdBy,
    };
  }

  InvoiceModel copyWith({
    InvoiceStatus? status,
    DateTime? paidDate,
    String? paymentMethod,
    String? paymentReference,
    String? notes,
  }) {
    return InvoiceModel(
      id: id,
      societyId: societyId,
      ownerId: ownerId,
      unitId: unitId,
      propertyId: propertyId,
      residentId: residentId,
      residentName: residentName,
      unitNumber: unitNumber,
      propertyName: propertyName,
      lineItems: lineItems,
      subtotal: subtotal,
      totalGst: totalGst,
      grandTotal: grandTotal,
      gstNumber: gstNumber,
      billingMonth: billingMonth,
      status: status ?? this.status,
      issueDate: issueDate,
      dueDate: dueDate,
      paidDate: paidDate ?? this.paidDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      notes: notes ?? this.notes,
      createdBy: createdBy,
    );
  }
}
