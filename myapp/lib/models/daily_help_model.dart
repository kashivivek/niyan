import 'package:cloud_firestore/cloud_firestore.dart';

enum DailyHelpCategory {
  maid,
  cook,
  driver,
  nanny,
  security,
  gardener,
  plumber,
  other,
}

extension DailyHelpCategoryLabel on DailyHelpCategory {
  String get label {
    switch (this) {
      case DailyHelpCategory.maid:     return 'Maid / Housekeeping';
      case DailyHelpCategory.cook:     return 'Cook';
      case DailyHelpCategory.driver:   return 'Driver';
      case DailyHelpCategory.nanny:    return 'Nanny / Babysitter';
      case DailyHelpCategory.security: return 'Security Guard';
      case DailyHelpCategory.gardener: return 'Gardener';
      case DailyHelpCategory.plumber:  return 'Plumber / Electrician';
      case DailyHelpCategory.other:    return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case DailyHelpCategory.maid:     return '🧹';
      case DailyHelpCategory.cook:     return '👨‍🍳';
      case DailyHelpCategory.driver:   return '🚗';
      case DailyHelpCategory.nanny:    return '👶';
      case DailyHelpCategory.security: return '🛡️';
      case DailyHelpCategory.gardener: return '🌿';
      case DailyHelpCategory.plumber:  return '🔧';
      case DailyHelpCategory.other:    return '👷';
    }
  }
}

/// Attendance status for a single day.
enum AttendanceStatus { present, absent, half_day, holiday }

/// A single day's attendance record embedded in the `attendance` map.
class AttendanceRecord {
  final AttendanceStatus status;
  final String? note;
  final DateTime? markedAt;

  AttendanceRecord({
    required this.status,
    this.note,
    this.markedAt,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      note: map['note'],
      markedAt: (map['markedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.toString(),
        'note': note,
        'markedAt': markedAt != null ? Timestamp.fromDate(markedAt!) : null,
      };
}

/// A daily help / household staff member registered with the society.
/// Attendance is stored as a map: { 'yyyy-MM-dd': AttendanceRecord }
/// per month, keeping reads efficient.
class DailyHelpModel {
  final String id;
  final String societyId;
  final String unitId;
  final String residentId;   // The resident who registered this staff
  final String unitNumber;

  final String name;
  final String phone;
  final String? photoUrl;
  final String? idProofUrl;  // Aadhaar / PAN photo URL
  final DailyHelpCategory category;
  final bool isActive;

  /// Arrival / departure times for gate log — stored in HH:mm format
  final String? expectedArrivalTime;
  final String? expectedDepartureTime;

  /// Attendance map: { 'yyyy-MM' : { 'dd': AttendanceRecord } }
  /// Stored as a separate Firestore document per month for scalability.
  final Map<String, AttendanceRecord> attendance; // key = 'yyyy-MM-dd'

  final DateTime registeredAt;
  final String? notes;
  final String? bgVerificationStatus; // 'pending', 'clear', 'flagged'

  DailyHelpModel({
    required this.id,
    required this.societyId,
    required this.unitId,
    required this.residentId,
    required this.unitNumber,
    required this.name,
    required this.phone,
    this.photoUrl,
    this.idProofUrl,
    required this.category,
    this.isActive = true,
    this.expectedArrivalTime,
    this.expectedDepartureTime,
    this.attendance = const {},
    required this.registeredAt,
    this.notes,
    this.bgVerificationStatus,
  });

  int presentDaysInMonth(String month) {
    return attendance.entries
        .where((e) =>
            e.key.startsWith(month) &&
            (e.value.status == AttendanceStatus.present ||
                e.value.status == AttendanceStatus.half_day))
        .length;
  }

  factory DailyHelpModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawAttendance = data['attendance'] as Map<String, dynamic>? ?? {};
    return DailyHelpModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      unitId: data['unitId'] ?? '',
      residentId: data['residentId'] ?? '',
      unitNumber: data['unitNumber'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'],
      idProofUrl: data['idProofUrl'],
      category: DailyHelpCategory.values.firstWhere(
        (e) => e.toString() == data['category'],
        orElse: () => DailyHelpCategory.other,
      ),
      isActive: data['isActive'] ?? true,
      expectedArrivalTime: data['expectedArrivalTime'],
      expectedDepartureTime: data['expectedDepartureTime'],
      attendance: rawAttendance.map(
        (k, v) => MapEntry(k, AttendanceRecord.fromMap(Map<String, dynamic>.from(v))),
      ),
      registeredAt: (data['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
      bgVerificationStatus: data['bgVerificationStatus'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'societyId': societyId,
        'unitId': unitId,
        'residentId': residentId,
        'unitNumber': unitNumber,
        'name': name,
        'phone': phone,
        'photoUrl': photoUrl,
        'idProofUrl': idProofUrl,
        'category': category.toString(),
        'isActive': isActive,
        'expectedArrivalTime': expectedArrivalTime,
        'expectedDepartureTime': expectedDepartureTime,
        'attendance': attendance.map((k, v) => MapEntry(k, v.toMap())),
        'registeredAt': Timestamp.fromDate(registeredAt),
        'notes': notes,
        'bgVerificationStatus': bgVerificationStatus,
      };
}
