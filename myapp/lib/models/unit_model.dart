import 'package:cloud_firestore/cloud_firestore.dart';

class UnitModel {
  final String id;
  final String propertyId;
  final String ownerId;
  final String unitNumber;
  final double monthlyRent;
  final int rentDueDate; // Day of the month
  final String status; // e.g., 'occupied', 'vacant'
  final int sqft;
  final int bedrooms;
  final int bathrooms;
  final String? currentTenantId;
  final String? currentTenancyHistoryId;
  final List<String> previousTenantIds;
  final double balanceDue;
  final DateTime? rentPaymentDate;
  final DateTime? lastVacatedDate;

  UnitModel({
    required this.id,
    required this.propertyId,
    required this.ownerId,
    required this.unitNumber,
    required this.monthlyRent,
    required this.rentDueDate,
    required this.sqft,
    required this.bedrooms,
    required this.bathrooms,
    this.status = 'vacant',
    this.currentTenantId,
    this.currentTenancyHistoryId,
    this.previousTenantIds = const [],
    this.balanceDue = 0.0,
    this.rentPaymentDate,
    this.lastVacatedDate,
  });

  bool get isOccupied => currentTenantId != null && currentTenantId!.isNotEmpty;
  String? get tenantId => currentTenantId;

  factory UnitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UnitModel(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      unitNumber: data['unitNumber'] ?? '',
      monthlyRent: (data['monthlyRent'] as num?)?.toDouble() ?? 0.0,
      rentDueDate: (data['rentDueDate'] as num?)?.toInt() ?? 1,
      sqft: (data['sqft'] as num?)?.toInt() ?? 0,
      bedrooms: (data['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (data['bathrooms'] as num?)?.toInt() ?? 0,
      status: data['status'] ?? 'vacant',
      currentTenantId: data['currentTenantId'] as String?,
      currentTenancyHistoryId: data['currentTenancyHistoryId'] as String?,
      previousTenantIds: List<String>.from(data['previousTenantIds'] ?? []),
      balanceDue: (data['balanceDue'] ?? 0).toDouble(),
      rentPaymentDate: data['rentPaymentDate'] != null ? (data['rentPaymentDate'] as Timestamp).toDate() : null,
      lastVacatedDate: data['lastVacatedDate'] != null ? (data['lastVacatedDate'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'ownerId': ownerId,
      'unitNumber': unitNumber,
      'monthlyRent': monthlyRent,
      'rentDueDate': rentDueDate,
      'sqft': sqft,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'status': status,
      'currentTenantId': currentTenantId,
      'currentTenancyHistoryId': currentTenancyHistoryId,
      'previousTenantIds': previousTenantIds,
      'balanceDue': balanceDue,
      'rentPaymentDate': rentPaymentDate != null ? Timestamp.fromDate(rentPaymentDate!) : null,
      'lastVacatedDate': lastVacatedDate != null ? Timestamp.fromDate(lastVacatedDate!) : null,
    };
  }

  UnitModel copyWith({
    String? id,
    String? propertyId,
    String? ownerId,
    String? unitNumber,
    double? monthlyRent,
    int? rentDueDate,
    String? status,
    int? sqft,
    int? bedrooms,
    int? bathrooms,
    String? currentTenantId,
    String? currentTenancyHistoryId,
    List<String>? previousTenantIds,
    double? balanceDue,
    DateTime? rentPaymentDate,
    DateTime? lastVacatedDate,
  }) {
    return UnitModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      ownerId: ownerId ?? this.ownerId,
      unitNumber: unitNumber ?? this.unitNumber,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      rentDueDate: rentDueDate ?? this.rentDueDate,
      status: status ?? this.status,
      sqft: sqft ?? this.sqft,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      currentTenantId: currentTenantId ?? this.currentTenantId,
      currentTenancyHistoryId: currentTenancyHistoryId ?? this.currentTenancyHistoryId,
      previousTenantIds: previousTenantIds ?? this.previousTenantIds,
      balanceDue: balanceDue ?? this.balanceDue,
      rentPaymentDate: rentPaymentDate ?? this.rentPaymentDate,
      lastVacatedDate: lastVacatedDate ?? this.lastVacatedDate,
    );
  }
}
