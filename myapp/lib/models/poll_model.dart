import 'package:cloud_firestore/cloud_firestore.dart';

enum PollStatus { active, closed }

class PollOption {
  final String id;
  final String text;
  final int votes;

  PollOption({required this.id, required this.text, this.votes = 0});

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      votes: map['votes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'votes': votes,
      };
}

/// A community poll.
class PollModel {
  final String id;
  final String societyId;
  final String question;
  final String authorId;
  final String authorName;
  final List<PollOption> options;
  final List<String> votedUserIds; // To track who has already voted
  final PollStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  PollModel({
    required this.id,
    required this.societyId,
    required this.question,
    required this.authorId,
    required this.authorName,
    required this.options,
    this.votedUserIds = const [],
    this.status = PollStatus.active,
    required this.createdAt,
    required this.expiresAt,
  });

  int get totalVotes => options.fold(0, (sum, opt) => sum + opt.votes);
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory PollModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final optionsList = (data['options'] as List<dynamic>?) ?? [];
    
    return PollModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      question: data['question'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      options: optionsList.map((o) => PollOption.fromMap(Map<String, dynamic>.from(o))).toList(),
      votedUserIds: List<String>.from(data['votedUserIds'] ?? []),
      status: PollStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => PollStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'societyId': societyId,
        'question': question,
        'authorId': authorId,
        'authorName': authorName,
        'options': options.map((o) => o.toMap()).toList(),
        'votedUserIds': votedUserIds,
        'status': status.toString(),
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
      };
}
