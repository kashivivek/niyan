import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/visitor_model.dart';
import 'package:myapp/models/daily_help_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

/// Service for visitor pre-approval, check-in/out, and daily help management.
class VisitorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ──────────────────────────────────────────────
  // Visitor Streams
  // ──────────────────────────────────────────────

  /// Live stream of all visitors for a society — guard uses this.
  Stream<List<VisitorModel>> getVisitorsBySociety(
    String societyId, {
    DateTime? date,
  }) {
    Query query = _db
        .collection('visitors')
        .where('societyId', isEqualTo: societyId);

    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end));
    }

    return query.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => VisitorModel.fromFirestore(d)).toList(),
        );
  }

  /// Live stream of visitors for a specific unit (resident view).
  Stream<List<VisitorModel>> getVisitorsByUnit(String unitId) {
    return _db
        .collection('visitors')
        .where('unitId', isEqualTo: unitId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => VisitorModel.fromFirestore(d)).toList());
  }

  /// Visitors currently inside the premises (checked in, not checked out).
  Stream<List<VisitorModel>> getCurrentlyInsideVisitors(String societyId) {
    return _db
        .collection('visitors')
        .where('societyId', isEqualTo: societyId)
        .where('status', isEqualTo: VisitorStatus.checked_in.toString())
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => VisitorModel.fromFirestore(d)).toList());
  }

  /// Pre-approved visitors waiting at the gate.
  Stream<List<VisitorModel>> getArrivedVisitors(String societyId) {
    return _db
        .collection('visitors')
        .where('societyId', isEqualTo: societyId)
        .where('status', isEqualTo: VisitorStatus.arrived.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => VisitorModel.fromFirestore(d)).toList());
  }

  /// Single visitor stream — used for real-time gate updates.
  Stream<VisitorModel> getVisitorStream(String visitorId) {
    return _db
        .collection('visitors')
        .doc(visitorId)
        .snapshots()
        .map((doc) => VisitorModel.fromFirestore(doc));
  }

  Future<VisitorModel?> getVisitorById(String visitorId) async {
    final doc = await _db.collection('visitors').doc(visitorId).get();
    if (doc.exists) {
      return VisitorModel.fromFirestore(doc);
    }
    return null;
  }

  /// Find visitor by QR code token.
  Future<VisitorModel?> getVisitorByQrCode(String qrCode) async {
    final snap = await _db
        .collection('visitors')
        .where('qrCode', isEqualTo: qrCode)
        .where('status', whereIn: [
          VisitorStatus.pre_approved.toString(),
          VisitorStatus.arrived.toString(),
        ])
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return VisitorModel.fromFirestore(snap.docs.first);
  }

  // ──────────────────────────────────────────────
  // Pre-approval by resident
  // ──────────────────────────────────────────────

  /// Create a visitor pass (pre-approval). Returns the visitor ID.
  Future<String> preApproveVisitor({
    required String societyId,
    required String unitId,
    required String propertyId,
    required String residentId,
    required String residentName,
    required String unitNumber,
    required String visitorName,
    required String visitorPhone,
    required VisitorType type,
    String? purpose,
    DateTime? expectedAt,
    DateTime? validUntil,
    bool leaveAtGate = false,
    String? deliveryAgency,
    String? vehicleNumber,
  }) async {
    final ref = _db.collection('visitors').doc();
    // Generate a unique QR token
    final qrCode = 'NIYAN-${_uuid.v4().substring(0, 8).toUpperCase()}';

    final visitor = VisitorModel(
      id: ref.id,
      societyId: societyId,
      unitId: unitId,
      propertyId: propertyId,
      residentId: residentId,
      residentName: residentName,
      unitNumber: unitNumber,
      visitorName: visitorName,
      visitorPhone: visitorPhone,
      type: type,
      status: VisitorStatus.pre_approved,
      purpose: purpose,
      qrCode: qrCode,
      validFrom: DateTime.now(),
      validUntil: validUntil,
      expectedAt: expectedAt,
      vehicleNumber: vehicleNumber,
      leaveAtGate: leaveAtGate,
      deliveryAgency: deliveryAgency,
      createdAt: DateTime.now(),
      isPreApproved: true,
    );

    await ref.set(visitor.toFirestore());
    developer.log('Visitor pre-approved: ${ref.id} QR: $qrCode');
    return ref.id;
  }

  // ──────────────────────────────────────────────
  // Gate Operations
  // ──────────────────────────────────────────────

  /// Guard marks visitor as arrived at gate (after QR scan or manual entry).
  Future<void> markArrived(String visitorId) {
    return _db.collection('visitors').doc(visitorId).update({
      'status': VisitorStatus.arrived.toString(),
    });
  }

  /// Guard checks visitor in.
  Future<void> checkIn({
    required String visitorId,
    required String guardId,
    required String guardName,
    String? visitorPhotoUrl,
  }) {
    return _db.collection('visitors').doc(visitorId).update({
      'status': VisitorStatus.checked_in.toString(),
      'checkedInAt': Timestamp.now(),
      'approvedByGuardId': guardId,
      'approvedByGuardName': guardName,
      if (visitorPhotoUrl != null) 'visitorPhotoUrl': visitorPhotoUrl,
    });
  }

  /// Guard checks visitor out.
  Future<void> checkOut(String visitorId) {
    return _db.collection('visitors').doc(visitorId).update({
      'status': VisitorStatus.checked_out.toString(),
      'checkedOutAt': Timestamp.now(),
    });
  }

  /// Guard rejects a visitor.
  Future<void> rejectVisitor({
    required String visitorId,
    required String guardId,
    required String guardName,
    required String reason,
  }) {
    return _db.collection('visitors').doc(visitorId).update({
      'status': VisitorStatus.rejected.toString(),
      'rejectionReason': reason,
      'approvedByGuardId': guardId,
      'approvedByGuardName': guardName,
    });
  }

  /// Guard creates a walk-in entry (no pre-approval).
  Future<String> createWalkIn({
    required String societyId,
    required String unitId,
    required String propertyId,
    required String residentId,
    required String residentName,
    required String unitNumber,
    required String visitorName,
    required String visitorPhone,
    required VisitorType type,
    required String guardId,
    required String guardName,
    String? purpose,
    String? vehicleNumber,
  }) async {
    final ref = _db.collection('visitors').doc();
    final now = DateTime.now();

    final visitor = VisitorModel(
      id: ref.id,
      societyId: societyId,
      unitId: unitId,
      propertyId: propertyId,
      residentId: residentId,
      residentName: residentName,
      unitNumber: unitNumber,
      visitorName: visitorName,
      visitorPhone: visitorPhone,
      type: type,
      status: VisitorStatus.checked_in,
      purpose: purpose,
      vehicleNumber: vehicleNumber,
      checkedInAt: now,
      approvedByGuardId: guardId,
      approvedByGuardName: guardName,
      createdAt: now,
      isPreApproved: false,
    );

    await ref.set(visitor.toFirestore());
    developer.log('Walk-in created: ${ref.id}');
    return ref.id;
  }

  // ──────────────────────────────────────────────
  // Daily Help Management
  // ──────────────────────────────────────────────

  Stream<List<DailyHelpModel>> getDailyHelpByUnit(String unitId) {
    return _db
        .collection('dailyHelp')
        .where('unitId', isEqualTo: unitId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DailyHelpModel.fromFirestore(d)).toList());
  }

  Stream<List<DailyHelpModel>> getDailyHelpBySociety(String societyId) {
    return _db
        .collection('dailyHelp')
        .where('societyId', isEqualTo: societyId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DailyHelpModel.fromFirestore(d)).toList());
  }

  Future<String> registerDailyHelp(DailyHelpModel help) async {
    final ref = _db.collection('dailyHelp').doc();
    final h = DailyHelpModel(
      id: ref.id,
      societyId: help.societyId,
      unitId: help.unitId,
      residentId: help.residentId,
      unitNumber: help.unitNumber,
      name: help.name,
      phone: help.phone,
      photoUrl: help.photoUrl,
      idProofUrl: help.idProofUrl,
      category: help.category,
      expectedArrivalTime: help.expectedArrivalTime,
      expectedDepartureTime: help.expectedDepartureTime,
      notes: help.notes,
      registeredAt: DateTime.now(),
    );
    await ref.set(h.toFirestore());
    developer.log('Daily help registered: ${ref.id}');
    return ref.id;
  }

  /// Mark attendance for a single staff member on a specific date.
  Future<void> markAttendance({
    required String helpId,
    required String dateKey,   // 'yyyy-MM-dd'
    required AttendanceStatus status,
    String? note,
  }) {
    return _db.collection('dailyHelp').doc(helpId).update({
      'attendance.$dateKey': AttendanceRecord(
        status: status,
        note: note,
        markedAt: DateTime.now(),
      ).toMap(),
    });
  }

  Future<void> deactivateDailyHelp(String helpId) {
    return _db.collection('dailyHelp').doc(helpId).update({'isActive': false});
  }
}
