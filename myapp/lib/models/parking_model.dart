import 'package:cloud_firestore/cloud_firestore.dart';

enum ParkingSpotType { car, bike, visitor, handicapped, ev_charging }
enum ParkingSpotStatus { available, occupied, reserved, maintenance }

/// A parking spot within the society.
class ParkingSpotModel {
  final String id;
  final String societyId;
  final String spotNumber; // e.g., "B1-42"
  final String blockOrLevel;
  final ParkingSpotType type;
  final ParkingSpotStatus status;

  // Assignment info (if occupied/reserved)
  final String? assignedUnitId;
  final String? assignedUnitNumber;
  final String? assignedResidentId;
  final String? assignedResidentName;
  final String? vehicleNumber; // Assigned vehicle

  final DateTime? assignmentDate;

  ParkingSpotModel({
    required this.id,
    required this.societyId,
    required this.spotNumber,
    required this.blockOrLevel,
    required this.type,
    this.status = ParkingSpotStatus.available,
    this.assignedUnitId,
    this.assignedUnitNumber,
    this.assignedResidentId,
    this.assignedResidentName,
    this.vehicleNumber,
    this.assignmentDate,
  });

  factory ParkingSpotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParkingSpotModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      spotNumber: data['spotNumber'] ?? '',
      blockOrLevel: data['blockOrLevel'] ?? '',
      type: ParkingSpotType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => ParkingSpotType.car,
      ),
      status: ParkingSpotStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => ParkingSpotStatus.available,
      ),
      assignedUnitId: data['assignedUnitId'],
      assignedUnitNumber: data['assignedUnitNumber'],
      assignedResidentId: data['assignedResidentId'],
      assignedResidentName: data['assignedResidentName'],
      vehicleNumber: data['vehicleNumber'],
      assignmentDate: (data['assignmentDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'societyId': societyId,
        'spotNumber': spotNumber,
        'blockOrLevel': blockOrLevel,
        'type': type.toString(),
        'status': status.toString(),
        'assignedUnitId': assignedUnitId,
        'assignedUnitNumber': assignedUnitNumber,
        'assignedResidentId': assignedResidentId,
        'assignedResidentName': assignedResidentName,
        'vehicleNumber': vehicleNumber,
        'assignmentDate': assignmentDate != null ? Timestamp.fromDate(assignmentDate!) : null,
      };
}
