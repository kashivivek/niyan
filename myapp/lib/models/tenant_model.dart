import 'package:cloud_firestore/cloud_firestore.dart';

enum TenantStatus { active, past }

class TenantModel {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final double rentAmount;
  final DateTime dueDate;
  final DateTime moveInDate;
  final TenantStatus status;
  final String ownerId;
  final String propertyId;
  final String assignedUnitId;
  final bool isAssignedToUnit;
  final String? photoUrl;

  TenantModel({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    required this.rentAmount,
    required this.dueDate,
    required this.moveInDate,
    this.status = TenantStatus.active,
    required this.ownerId,
    required this.propertyId,
    required this.assignedUnitId,
    this.isAssignedToUnit = false,
    this.photoUrl,
  });

  factory TenantModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TenantModel(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] as String?,
      email: data['email'] as String?,
      rentAmount: (data['rentAmount'] ?? 0).toDouble(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      moveInDate: (data['moveInDate'] as Timestamp).toDate(),
      status: TenantStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => TenantStatus.active,
      ),
      ownerId: data['ownerId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      assignedUnitId: data['assignedUnitId'] ?? '',
      isAssignedToUnit: data['isAssignedToUnit'] ?? false,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'rentAmount': rentAmount,
      'dueDate': dueDate,
      'moveInDate': moveInDate,
      'status': status.toString(),
      'ownerId': ownerId,
      'propertyId': propertyId,
      'assignedUnitId': assignedUnitId,
      'isAssignedToUnit': isAssignedToUnit,
      'photoUrl': photoUrl,
    };
  }

  TenantModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    double? rentAmount,
    DateTime? dueDate,
    DateTime? moveInDate,
    TenantStatus? status,
    String? ownerId,
    String? propertyId,
    String? assignedUnitId,
    bool? isAssignedToUnit,
    String? photoUrl,
  }) {
    return TenantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      rentAmount: rentAmount ?? this.rentAmount,
      dueDate: dueDate ?? this.dueDate,
      moveInDate: moveInDate ?? this.moveInDate,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      propertyId: propertyId ?? this.propertyId,
      assignedUnitId: assignedUnitId ?? this.assignedUnitId,
      isAssignedToUnit: isAssignedToUnit ?? this.isAssignedToUnit,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
