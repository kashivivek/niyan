import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketCategory { plumbing, electrical, carpentry, cleaning, security, billing, other }
enum TicketPriority { low, medium, high, urgent }
enum TicketStatus { open, in_progress, resolved, closed }

extension TicketCategoryLabel on TicketCategory {
  String get label {
    switch (this) {
      case TicketCategory.plumbing:  return 'Plumbing';
      case TicketCategory.electrical:return 'Electrical';
      case TicketCategory.carpentry: return 'Carpentry';
      case TicketCategory.cleaning:  return 'Cleaning';
      case TicketCategory.security:  return 'Security';
      case TicketCategory.billing:   return 'Billing';
      case TicketCategory.other:     return 'Other';
    }
  }
}

extension TicketPriorityLabel on TicketPriority {
  String get label {
    switch (this) {
      case TicketPriority.low:    return 'Low';
      case TicketPriority.medium: return 'Medium';
      case TicketPriority.high:   return 'High';
      case TicketPriority.urgent: return 'Urgent';
    }
  }
}

extension TicketStatusLabel on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.open:        return 'Open';
      case TicketStatus.in_progress: return 'In Progress';
      case TicketStatus.resolved:    return 'Resolved';
      case TicketStatus.closed:      return 'Closed';
    }
  }
}

/// Helpdesk ticket or complaint raised by a resident.
class TicketModel {
  final String id;
  final String societyId;
  final String unitId;
  final String residentId;
  final String residentName;
  final String unitNumber;
  
  final String title;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;

  final String? assignedToId;
  final String? assignedToName;
  final String? resolutionNotes;
  final List<String> attachmentUrls;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  TicketModel({
    required this.id,
    required this.societyId,
    required this.unitId,
    required this.residentId,
    required this.residentName,
    required this.unitNumber,
    required this.title,
    required this.description,
    required this.category,
    this.priority = TicketPriority.medium,
    this.status = TicketStatus.open,
    this.assignedToId,
    this.assignedToName,
    this.resolutionNotes,
    this.attachmentUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory TicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TicketModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      unitId: data['unitId'] ?? '',
      residentId: data['residentId'] ?? '',
      residentName: data['residentName'] ?? '',
      unitNumber: data['unitNumber'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: TicketCategory.values.firstWhere(
        (e) => e.toString() == data['category'],
        orElse: () => TicketCategory.other,
      ),
      priority: TicketPriority.values.firstWhere(
        (e) => e.toString() == data['priority'],
        orElse: () => TicketPriority.medium,
      ),
      status: TicketStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => TicketStatus.open,
      ),
      assignedToId: data['assignedToId'],
      assignedToName: data['assignedToName'],
      resolutionNotes: data['resolutionNotes'],
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'societyId': societyId,
        'unitId': unitId,
        'residentId': residentId,
        'residentName': residentName,
        'unitNumber': unitNumber,
        'title': title,
        'description': description,
        'category': category.toString(),
        'priority': priority.toString(),
        'status': status.toString(),
        'assignedToId': assignedToId,
        'assignedToName': assignedToName,
        'resolutionNotes': resolutionNotes,
        'attachmentUrls': attachmentUrls,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      };
}
