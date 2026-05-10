import 'package:cloud_firestore/cloud_firestore.dart';

enum DocumentCategory { rules, forms, financials, minutes, other }

extension DocumentCategoryLabel on DocumentCategory {
  String get label {
    switch (this) {
      case DocumentCategory.rules:      return 'Rules & Guidelines';
      case DocumentCategory.forms:      return 'Forms & Applications';
      case DocumentCategory.financials: return 'Financials';
      case DocumentCategory.minutes:    return 'Meeting Minutes';
      case DocumentCategory.other:      return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case DocumentCategory.rules:      return '📜';
      case DocumentCategory.forms:      return '📝';
      case DocumentCategory.financials: return '📊';
      case DocumentCategory.minutes:    return '👥';
      case DocumentCategory.other:      return '📁';
    }
  }
}

/// A document shared with the society members.
class SharedDocumentModel {
  final String id;
  final String societyId;
  final String title;
  final String description;
  final DocumentCategory category;
  final String fileUrl;
  final String fileType; // e.g., 'pdf', 'doc', 'jpg'
  final String uploadedById;
  final String uploadedByName;
  final DateTime uploadedAt;
  final bool isPinned;

  SharedDocumentModel({
    required this.id,
    required this.societyId,
    required this.title,
    required this.description,
    required this.category,
    required this.fileUrl,
    required this.fileType,
    required this.uploadedById,
    required this.uploadedByName,
    required this.uploadedAt,
    this.isPinned = false,
  });

  factory SharedDocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedDocumentModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: DocumentCategory.values.firstWhere(
        (e) => e.toString() == data['category'],
        orElse: () => DocumentCategory.other,
      ),
      fileUrl: data['fileUrl'] ?? '',
      fileType: data['fileType'] ?? 'unknown',
      uploadedById: data['uploadedById'] ?? '',
      uploadedByName: data['uploadedByName'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'societyId': societyId,
        'title': title,
        'description': description,
        'category': category.toString(),
        'fileUrl': fileUrl,
        'fileType': fileType,
        'uploadedById': uploadedById,
        'uploadedByName': uploadedByName,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'isPinned': isPinned,
      };
}
