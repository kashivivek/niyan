import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementPriority { normal, high, urgent }

/// A notice or announcement broadcasted to the society.
class AnnouncementModel {
  final String id;
  final String societyId;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final AnnouncementPriority priority;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime? expiresAt; // Optional: auto-hide after this date

  AnnouncementModel({
    required this.id,
    required this.societyId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.priority = AnnouncementPriority.normal,
    this.attachmentUrls = const [],
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      priority: AnnouncementPriority.values.firstWhere(
        (e) => e.toString() == data['priority'],
        orElse: () => AnnouncementPriority.normal,
      ),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'societyId': societyId,
        'title': title,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'priority': priority.toString(),
        'attachmentUrls': attachmentUrls,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      };
}
