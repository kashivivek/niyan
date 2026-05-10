import 'package:cloud_firestore/cloud_firestore.dart';

enum AmenityStatus { available, under_maintenance, closed }
enum BookingStatus { pending, confirmed, cancelled, completed }

/// A facility available in the society (e.g., Clubhouse, Tennis Court).
class AmenityModel {
  final String id;
  final String societyId;
  final String name;
  final String description;
  final String? icon; // Emoji or url
  final AmenityStatus status;
  final double hourlyRate; // 0 if free
  final int maxCapacity;
  final Map<String, dynamic> openHours; // e.g., {'start': '06:00', 'end': '22:00'}

  AmenityModel({
    required this.id,
    required this.societyId,
    required this.name,
    required this.description,
    this.icon,
    this.status = AmenityStatus.available,
    this.hourlyRate = 0.0,
    this.maxCapacity = 10,
    required this.openHours,
  });

  factory AmenityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AmenityModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'],
      status: AmenityStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => AmenityStatus.available,
      ),
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      maxCapacity: data['maxCapacity'] ?? 10,
      openHours: data['openHours'] ?? {'start': '06:00', 'end': '22:00'},
    );
  }

  Map<String, dynamic> toFirestore() => {
        'societyId': societyId,
        'name': name,
        'description': description,
        'icon': icon,
        'status': status.toString(),
        'hourlyRate': hourlyRate,
        'maxCapacity': maxCapacity,
        'openHours': openHours,
      };
}

/// A booking made by a resident for an amenity.
class AmenityBookingModel {
  final String id;
  final String societyId;
  final String amenityId;
  final String amenityName;
  final String residentId;
  final String residentName;
  final String unitNumber;
  
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final double totalCost;
  final DateTime createdAt;

  AmenityBookingModel({
    required this.id,
    required this.societyId,
    required this.amenityId,
    required this.amenityName,
    required this.residentId,
    required this.residentName,
    required this.unitNumber,
    required this.startTime,
    required this.endTime,
    this.status = BookingStatus.pending,
    this.totalCost = 0.0,
    required this.createdAt,
  });

  factory AmenityBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AmenityBookingModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      amenityId: data['amenityId'] ?? '',
      amenityName: data['amenityName'] ?? '',
      residentId: data['residentId'] ?? '',
      residentName: data['residentName'] ?? '',
      unitNumber: data['unitNumber'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      totalCost: (data['totalCost'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'societyId': societyId,
        'amenityId': amenityId,
        'amenityName': amenityName,
        'residentId': residentId,
        'residentName': residentName,
        'unitNumber': unitNumber,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'status': status.toString(),
        'totalCost': totalCost,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
