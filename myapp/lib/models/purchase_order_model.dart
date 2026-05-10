import 'package:cloud_firestore/cloud_firestore.dart';

enum PurchaseOrderStatus {
  draft,
  pending_approval,
  approved,
  rejected,
  ordered,
  received,
  paid,
  cancelled,
}

extension PurchaseOrderStatusLabel on PurchaseOrderStatus {
  String get label {
    switch (this) {
      case PurchaseOrderStatus.draft:            return 'Draft';
      case PurchaseOrderStatus.pending_approval: return 'Pending Approval';
      case PurchaseOrderStatus.approved:         return 'Approved';
      case PurchaseOrderStatus.rejected:         return 'Rejected';
      case PurchaseOrderStatus.ordered:          return 'Ordered';
      case PurchaseOrderStatus.received:         return 'Received';
      case PurchaseOrderStatus.paid:             return 'Paid';
      case PurchaseOrderStatus.cancelled:        return 'Cancelled';
    }
  }

  bool get isTerminal =>
      this == PurchaseOrderStatus.paid ||
      this == PurchaseOrderStatus.cancelled ||
      this == PurchaseOrderStatus.rejected;

  bool get requiresAction =>
      this == PurchaseOrderStatus.pending_approval;
}

/// A single approval step in the PO workflow.
class ApprovalStep {
  final String approverId;
  final String approverName;
  final String approverRole;
  final ApprovalAction action;
  final String? comment;
  final DateTime? actionDate;

  ApprovalStep({
    required this.approverId,
    required this.approverName,
    required this.approverRole,
    this.action = ApprovalAction.pending,
    this.comment,
    this.actionDate,
  });

  factory ApprovalStep.fromMap(Map<String, dynamic> map) {
    return ApprovalStep(
      approverId: map['approverId'] ?? '',
      approverName: map['approverName'] ?? '',
      approverRole: map['approverRole'] ?? '',
      action: ApprovalAction.values.firstWhere(
        (e) => e.toString() == map['action'],
        orElse: () => ApprovalAction.pending,
      ),
      comment: map['comment'],
      actionDate: (map['actionDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'approverId': approverId,
      'approverName': approverName,
      'approverRole': approverRole,
      'action': action.toString(),
      'comment': comment,
      'actionDate': actionDate != null ? Timestamp.fromDate(actionDate!) : null,
    };
  }

  ApprovalStep copyWith({ApprovalAction? action, String? comment, DateTime? actionDate}) {
    return ApprovalStep(
      approverId: approverId,
      approverName: approverName,
      approverRole: approverRole,
      action: action ?? this.action,
      comment: comment ?? this.comment,
      actionDate: actionDate ?? this.actionDate,
    );
  }
}

enum ApprovalAction { pending, approved, rejected }

/// Purchase Order with multi-level approval workflow.
class PurchaseOrderModel {
  final String id;
  final String? societyId;
  final String? ownerId;
  final String title;
  final String description;
  final String vendorId;
  final String vendorName;
  final double amount;
  final double? gstAmount;
  final double grandTotal;
  final PurchaseOrderStatus status;
  final List<ApprovalStep> approvalChain;
  final String requestedBy;
  final String requestedByName;
  final DateTime requestedAt;
  final DateTime? expectedDelivery;
  final String? invoiceUrl;     // Firebase Storage URL of vendor invoice
  final String? receiptUrl;     // Firebase Storage URL of payment receipt
  final String? notes;
  final String category;        // Maps to VendorCategory label

  PurchaseOrderModel({
    required this.id,
    this.societyId,
    this.ownerId,
    required this.title,
    required this.description,
    required this.vendorId,
    required this.vendorName,
    required this.amount,
    this.gstAmount,
    required this.grandTotal,
    this.status = PurchaseOrderStatus.draft,
    this.approvalChain = const [],
    required this.requestedBy,
    required this.requestedByName,
    required this.requestedAt,
    this.expectedDelivery,
    this.invoiceUrl,
    this.receiptUrl,
    this.notes,
    this.category = '',
  });

  /// The current pending approver (first pending step in the chain).
  ApprovalStep? get currentPendingApprover {
    try {
      return approvalChain.firstWhere(
          (s) => s.action == ApprovalAction.pending);
    } catch (_) {
      return null;
    }
  }

  factory PurchaseOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchaseOrderModel(
      id: doc.id,
      societyId: data['societyId'],
      ownerId: data['ownerId'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      vendorId: data['vendorId'] ?? '',
      vendorName: data['vendorName'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (data['gstAmount'] as num?)?.toDouble(),
      grandTotal: (data['grandTotal'] as num?)?.toDouble() ?? 0.0,
      status: PurchaseOrderStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => PurchaseOrderStatus.draft,
      ),
      approvalChain: (data['approvalChain'] as List? ?? [])
          .map((e) => ApprovalStep.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      requestedBy: data['requestedBy'] ?? '',
      requestedByName: data['requestedByName'] ?? '',
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedDelivery: (data['expectedDelivery'] as Timestamp?)?.toDate(),
      invoiceUrl: data['invoiceUrl'],
      receiptUrl: data['receiptUrl'],
      notes: data['notes'],
      category: data['category'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'societyId': societyId,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'amount': amount,
      'gstAmount': gstAmount,
      'grandTotal': grandTotal,
      'status': status.toString(),
      'approvalChain': approvalChain.map((s) => s.toMap()).toList(),
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'expectedDelivery': expectedDelivery != null
          ? Timestamp.fromDate(expectedDelivery!)
          : null,
      'invoiceUrl': invoiceUrl,
      'receiptUrl': receiptUrl,
      'notes': notes,
      'category': category,
    };
  }
}
