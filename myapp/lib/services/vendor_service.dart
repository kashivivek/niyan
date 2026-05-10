import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/vendor_model.dart';
import 'package:myapp/models/purchase_order_model.dart';
import 'dart:developer' as developer;

/// Service for vendor directory and purchase order management.
class VendorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────
  // Vendors
  // ──────────────────────────────────────────────

  /// Get vendors for standalone mode (by ownerId).
  Stream<List<VendorModel>> getVendorsByOwner(String ownerId) {
    return _db
        .collection('vendors')
        .where('ownerId', isEqualTo: ownerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => VendorModel.fromFirestore(doc)).toList()
              ..sort((a, b) => b.rating.compareTo(a.rating)));
  }

  /// Get vendors for society mode (by societyId).
  Stream<List<VendorModel>> getVendorsBySociety(String societyId) {
    return _db
        .collection('vendors')
        .where('societyId', isEqualTo: societyId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => VendorModel.fromFirestore(doc)).toList()
              ..sort((a, b) => b.rating.compareTo(a.rating)));
  }

  Stream<VendorModel> getVendorStream(String vendorId) {
    return _db
        .collection('vendors')
        .doc(vendorId)
        .snapshots()
        .map((doc) => VendorModel.fromFirestore(doc));
  }

  Future<String> addVendor(VendorModel vendor) async {
    final ref = _db.collection('vendors').doc();
    final v = VendorModel(
      id: ref.id,
      societyId: vendor.societyId,
      ownerId: vendor.ownerId,
      name: vendor.name,
      category: vendor.category,
      phone: vendor.phone,
      email: vendor.email,
      address: vendor.address,
      gstNumber: vendor.gstNumber,
      panNumber: vendor.panNumber,
      createdAt: DateTime.now(),
    );
    await ref.set(v.toFirestore());
    developer.log('Vendor added: ${ref.id}');
    return ref.id;
  }

  Future<void> updateVendor(VendorModel vendor) {
    return _db.collection('vendors').doc(vendor.id).update(vendor.toFirestore());
  }

  Future<void> deactivateVendor(String vendorId) {
    return _db
        .collection('vendors')
        .doc(vendorId)
        .update({'isActive': false});
  }

  Future<void> updateVendorRating(String vendorId, double newRating, int newTotalJobs) {
    return _db.collection('vendors').doc(vendorId).update({
      'rating': newRating,
      'totalJobs': newTotalJobs,
    });
  }

  // ──────────────────────────────────────────────
  // Purchase Orders
  // ──────────────────────────────────────────────

  Stream<List<PurchaseOrderModel>> getPurchaseOrders({
    String? ownerId,
    String? societyId,
  }) {
    Query query = _db.collection('purchaseOrders');
    if (societyId != null) {
      query = query.where('societyId', isEqualTo: societyId);
    } else if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }
    return query.snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => PurchaseOrderModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    });
  }

  Stream<List<PurchaseOrderModel>> getPendingApprovals({
    String? ownerId,
    String? societyId,
    required String approverId,
  }) {
    Query query = _db
        .collection('purchaseOrders')
        .where('status', isEqualTo: PurchaseOrderStatus.pending_approval.toString());
    if (societyId != null) {
      query = query.where('societyId', isEqualTo: societyId);
    } else if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }
    return query.snapshots().map((snap) {
      return snap.docs
          .map((doc) => PurchaseOrderModel.fromFirestore(doc))
          .where((po) =>
              po.currentPendingApprover?.approverId == approverId)
          .toList();
    });
  }

  Future<String> createPurchaseOrder(PurchaseOrderModel po) async {
    final ref = _db.collection('purchaseOrders').doc();
    final newPo = PurchaseOrderModel(
      id: ref.id,
      societyId: po.societyId,
      ownerId: po.ownerId,
      title: po.title,
      description: po.description,
      vendorId: po.vendorId,
      vendorName: po.vendorName,
      amount: po.amount,
      gstAmount: po.gstAmount,
      grandTotal: po.grandTotal,
      status: po.approvalChain.isEmpty
          ? PurchaseOrderStatus.approved
          : PurchaseOrderStatus.pending_approval,
      approvalChain: po.approvalChain,
      requestedBy: po.requestedBy,
      requestedByName: po.requestedByName,
      requestedAt: DateTime.now(),
      expectedDelivery: po.expectedDelivery,
      notes: po.notes,
      category: po.category,
    );
    await ref.set(newPo.toFirestore());
    developer.log('Purchase order created: ${ref.id}');
    return ref.id;
  }

  Future<void> approvePurchaseOrder({
    required String poId,
    required String approverId,
    required String approverName,
    String? comment,
  }) async {
    final doc = await _db.collection('purchaseOrders').doc(poId).get();
    final po = PurchaseOrderModel.fromFirestore(doc);

    final updatedChain = po.approvalChain.map((step) {
      if (step.approverId == approverId &&
          step.action == ApprovalAction.pending) {
        return step.copyWith(
          action: ApprovalAction.approved,
          comment: comment,
          actionDate: DateTime.now(),
        );
      }
      return step;
    }).toList();

    // Check if all steps are approved
    final allApproved =
        updatedChain.every((s) => s.action == ApprovalAction.approved);

    await _db.collection('purchaseOrders').doc(poId).update({
      'approvalChain': updatedChain.map((s) => s.toMap()).toList(),
      'status': allApproved
          ? PurchaseOrderStatus.approved.toString()
          : PurchaseOrderStatus.pending_approval.toString(),
    });
  }

  Future<void> rejectPurchaseOrder({
    required String poId,
    required String approverId,
    required String comment,
  }) async {
    final doc = await _db.collection('purchaseOrders').doc(poId).get();
    final po = PurchaseOrderModel.fromFirestore(doc);

    final updatedChain = po.approvalChain.map((step) {
      if (step.approverId == approverId &&
          step.action == ApprovalAction.pending) {
        return step.copyWith(
          action: ApprovalAction.rejected,
          comment: comment,
          actionDate: DateTime.now(),
        );
      }
      return step;
    }).toList();

    await _db.collection('purchaseOrders').doc(poId).update({
      'approvalChain': updatedChain.map((s) => s.toMap()).toList(),
      'status': PurchaseOrderStatus.rejected.toString(),
    });
  }

  Future<void> markPurchaseOrderPaid({
    required String poId,
    required String receiptUrl,
  }) {
    return _db.collection('purchaseOrders').doc(poId).update({
      'status': PurchaseOrderStatus.paid.toString(),
      'receiptUrl': receiptUrl,
    });
  }
}
