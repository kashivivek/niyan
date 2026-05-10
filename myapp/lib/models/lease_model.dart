import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaseStatus { active, expiring_soon, expired, terminated }

/// Represents a lease agreement for a unit.
class LeaseModel {
  final String id;
  final String societyId;
  final String propertyId;
  final String unitId;
  final String unitNumber;
  
  final String tenantId;
  final String tenantName;
  final String ownerId;

  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final double securityDeposit;

  final LeaseStatus status;
  final String? documentUrl; // Link to uploaded lease document
  final String? notes;
  final DateTime createdAt;

  LeaseModel({
    required this.id,
    required this.societyId,
    required this.propertyId,
    required this.unitId,
    required this.unitNumber,
    required this.tenantId,
    required this.tenantName,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.securityDeposit,
    this.status = LeaseStatus.active,
    this.documentUrl,
    this.notes,
    required this.createdAt,
  });

  bool get isExpiringSoon {
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;
    return difference > 0 && difference <= 60; // Expiring within 60 days
  }

  factory LeaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaseModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      unitId: data['unitId'] ?? '',
      unitNumber: data['unitNumber'] ?? '',
      tenantId: data['tenantId'] ?? '',
      tenantName: data['tenantName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      monthlyRent: (data['monthlyRent'] as num?)?.toDouble() ?? 0.0,
      securityDeposit: (data['securityDeposit'] as num?)?.toDouble() ?? 0.0,
      status: LeaseStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => LeaseStatus.active,
      ),
      documentUrl: data['documentUrl'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'societyId': societyId,
        'propertyId': propertyId,
        'unitId': unitId,
        'unitNumber': unitNumber,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'ownerId': ownerId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'monthlyRent': monthlyRent,
        'securityDeposit': securityDeposit,
        'status': status.toString(),
        'documentUrl': documentUrl,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
