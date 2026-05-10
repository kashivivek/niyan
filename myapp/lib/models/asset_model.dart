import 'package:cloud_firestore/cloud_firestore.dart';

class AssetModel {
  final String id;
  final String societyId;
  final String name;
  final String category; // Electronics, Plumbing, Gym, Common Area, Security
  final String status; // active, under_maintenance, retired
  final DateTime purchaseDate;
  final double cost;
  final String? warrantyDetails;
  final String? location;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;

  AssetModel({
    required this.id,
    required this.societyId,
    required this.name,
    required this.category,
    required this.status,
    required this.purchaseDate,
    required this.cost,
    this.warrantyDetails,
    this.location,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
  });

  factory AssetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AssetModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'Other',
      status: data['status'] ?? 'active',
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cost: (data['cost'] ?? 0).toDouble(),
      warrantyDetails: data['warrantyDetails'],
      location: data['location'],
      lastMaintenanceDate: (data['lastMaintenanceDate'] as Timestamp?)?.toDate(),
      nextMaintenanceDate: (data['nextMaintenanceDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'name': name,
      'category': category,
      'status': status,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'cost': cost,
      'warrantyDetails': warrantyDetails,
      'location': location,
      'lastMaintenanceDate': lastMaintenanceDate != null ? Timestamp.fromDate(lastMaintenanceDate!) : null,
      'nextMaintenanceDate': nextMaintenanceDate != null ? Timestamp.fromDate(nextMaintenanceDate!) : null,
    };
  }
}
