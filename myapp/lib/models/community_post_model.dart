import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String societyId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String caption;
  final String? imageUrl;
  final DateTime createdAt;
  final List<String> likes; // User IDs
  final int commentCount;

  CommunityPost({
    required this.id,
    required this.societyId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.caption,
    this.imageUrl,
    required this.createdAt,
    this.likes = const [],
    this.commentCount = 0,
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Resident',
      authorAvatar: data['authorAvatar'],
      caption: data['caption'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'societyId': societyId,
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatar': authorAvatar,
    'caption': caption,
    'imageUrl': imageUrl,
    'createdAt': FieldValue.serverTimestamp(),
    'likes': likes,
    'commentCount': commentCount,
  };
}

class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String text;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.text,
    required this.createdAt,
  });

  factory PostComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Resident',
      authorAvatar: data['authorAvatar'],
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'postId': postId,
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatar': authorAvatar,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
