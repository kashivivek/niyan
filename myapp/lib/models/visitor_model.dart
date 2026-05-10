import 'package:cloud_firestore/cloud_firestore.dart';

enum VisitorType { guest, delivery, cab, daily_help, contractor, other }

enum VisitorStatus { pre_approved, arrived, checked_in, checked_out, rejected, expired }

extension VisitorTypeLabel on VisitorType {
  String get label {
    switch (this) {
      case VisitorType.guest:       return 'Guest';
      case VisitorType.delivery:    return 'Delivery';
      case VisitorType.cab:         return 'Cab / Taxi';
      case VisitorType.daily_help:  return 'Daily Help';
      case VisitorType.contractor:  return 'Contractor';
      case VisitorType.other:       return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case VisitorType.guest:       return '👤';
      case VisitorType.delivery:    return '📦';
      case VisitorType.cab:         return '🚖';
      case VisitorType.daily_help:  return '🧹';
      case VisitorType.contractor:  return '🔧';
      case VisitorType.other:       return '🏢';
    }
  }
}

extension VisitorStatusLabel on VisitorStatus {
  String get label {
    switch (this) {
      case VisitorStatus.pre_approved: return 'Pre-approved';
      case VisitorStatus.arrived:      return 'Arrived at Gate';
      case VisitorStatus.checked_in:   return 'Checked In';
      case VisitorStatus.checked_out:  return 'Checked Out';
      case VisitorStatus.rejected:     return 'Rejected';
      case VisitorStatus.expired:      return 'Pass Expired';
    }
  }

  bool get isActive =>
      this == VisitorStatus.pre_approved ||
      this == VisitorStatus.arrived ||
      this == VisitorStatus.checked_in;
}

/// A visitor entry — can be pre-approved by a resident or walked in at the gate.
class VisitorModel {
  final String id;
  final String societyId;
  final String unitId;
  final String propertyId;
  final String residentId;   // The resident who pre-approved OR whose unit is visited
  final String residentName;
  final String unitNumber;

  final String visitorName;
  final String visitorPhone;
  final String? visitorPhotoUrl;

  final VisitorType type;
  final VisitorStatus status;
  final String? purpose;      // "Birthday party", "Repair work", etc.

  // QR pass
  final String? qrCode;       // Unique token for gate scanning
  final DateTime? validFrom;
  final DateTime? validUntil; // null = single use

  // Timing
  final DateTime? expectedAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;

  // Gate details
  final String? vehicleNumber;
  final String? approvedByGuardId;
  final String? approvedByGuardName;
  final String? rejectionReason;

  // Delivery-specific
  final bool? leaveAtGate;    // Resident opted to receive at gate
  final String? deliveryAgency; // "Swiggy", "Amazon", etc.

  final DateTime createdAt;
  final bool isPreApproved;   // true = created by resident, false = walk-in

  VisitorModel({
    required this.id,
    required this.societyId,
    required this.unitId,
    required this.propertyId,
    required this.residentId,
    required this.residentName,
    required this.unitNumber,
    required this.visitorName,
    required this.visitorPhone,
    this.visitorPhotoUrl,
    required this.type,
    this.status = VisitorStatus.pre_approved,
    this.purpose,
    this.qrCode,
    this.validFrom,
    this.validUntil,
    this.expectedAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.vehicleNumber,
    this.approvedByGuardId,
    this.approvedByGuardName,
    this.rejectionReason,
    this.leaveAtGate,
    this.deliveryAgency,
    required this.createdAt,
    this.isPreApproved = true,
  });

  bool get isExpired {
    if (validUntil == null) return false;
    return DateTime.now().isAfter(validUntil!);
  }

  Duration? get duration {
    if (checkedInAt == null) return null;
    final end = checkedOutAt ?? DateTime.now();
    return end.difference(checkedInAt!);
  }

  factory VisitorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VisitorModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      unitId: data['unitId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      residentId: data['residentId'] ?? '',
      residentName: data['residentName'] ?? '',
      unitNumber: data['unitNumber'] ?? '',
      visitorName: data['visitorName'] ?? '',
      visitorPhone: data['visitorPhone'] ?? '',
      visitorPhotoUrl: data['visitorPhotoUrl'],
      type: VisitorType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => VisitorType.guest,
      ),
      status: VisitorStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => VisitorStatus.pre_approved,
      ),
      purpose: data['purpose'],
      qrCode: data['qrCode'],
      validFrom: (data['validFrom'] as Timestamp?)?.toDate(),
      validUntil: (data['validUntil'] as Timestamp?)?.toDate(),
      expectedAt: (data['expectedAt'] as Timestamp?)?.toDate(),
      checkedInAt: (data['checkedInAt'] as Timestamp?)?.toDate(),
      checkedOutAt: (data['checkedOutAt'] as Timestamp?)?.toDate(),
      vehicleNumber: data['vehicleNumber'],
      approvedByGuardId: data['approvedByGuardId'],
      approvedByGuardName: data['approvedByGuardName'],
      rejectionReason: data['rejectionReason'],
      leaveAtGate: data['leaveAtGate'],
      deliveryAgency: data['deliveryAgency'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPreApproved: data['isPreApproved'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'societyId': societyId,
        'unitId': unitId,
        'propertyId': propertyId,
        'residentId': residentId,
        'residentName': residentName,
        'unitNumber': unitNumber,
        'visitorName': visitorName,
        'visitorPhone': visitorPhone,
        'visitorPhotoUrl': visitorPhotoUrl,
        'type': type.toString(),
        'status': status.toString(),
        'purpose': purpose,
        'qrCode': qrCode,
        'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
        'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
        'expectedAt': expectedAt != null ? Timestamp.fromDate(expectedAt!) : null,
        'checkedInAt': checkedInAt != null ? Timestamp.fromDate(checkedInAt!) : null,
        'checkedOutAt': checkedOutAt != null ? Timestamp.fromDate(checkedOutAt!) : null,
        'vehicleNumber': vehicleNumber,
        'approvedByGuardId': approvedByGuardId,
        'approvedByGuardName': approvedByGuardName,
        'rejectionReason': rejectionReason,
        'leaveAtGate': leaveAtGate,
        'deliveryAgency': deliveryAgency,
        'createdAt': Timestamp.fromDate(createdAt),
        'isPreApproved': isPreApproved,
      };

  VisitorModel copyWith({
    VisitorStatus? status,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    String? approvedByGuardId,
    String? approvedByGuardName,
    String? rejectionReason,
    String? visitorPhotoUrl,
  }) {
    return VisitorModel(
      id: id,
      societyId: societyId,
      unitId: unitId,
      propertyId: propertyId,
      residentId: residentId,
      residentName: residentName,
      unitNumber: unitNumber,
      visitorName: visitorName,
      visitorPhone: visitorPhone,
      visitorPhotoUrl: visitorPhotoUrl ?? this.visitorPhotoUrl,
      type: type,
      status: status ?? this.status,
      purpose: purpose,
      qrCode: qrCode,
      validFrom: validFrom,
      validUntil: validUntil,
      expectedAt: expectedAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      vehicleNumber: vehicleNumber,
      approvedByGuardId: approvedByGuardId ?? this.approvedByGuardId,
      approvedByGuardName: approvedByGuardName ?? this.approvedByGuardName,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      leaveAtGate: leaveAtGate,
      deliveryAgency: deliveryAgency,
      createdAt: createdAt,
      isPreApproved: isPreApproved,
    );
  }
}
