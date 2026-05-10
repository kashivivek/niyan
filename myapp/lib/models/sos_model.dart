import 'package:cloud_firestore/cloud_firestore.dart';

class SosModel {
  final String id;
  final String societyId;
  final String residentId;
  final String residentName;
  final String unitNumber;
  final String status; // active, resolved
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  SosModel({
    required this.id,
    required this.societyId,
    required this.residentId,
    required this.residentName,
    required this.unitNumber,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory SosModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SosModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      residentId: data['residentId'] ?? '',
      residentName: data['residentName'] ?? 'Unknown Resident',
      unitNumber: data['unitNumber'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolvedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'residentId': residentId,
      'residentName': residentName,
      'unitNumber': unitNumber,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
    };
  }
}
