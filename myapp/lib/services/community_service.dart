import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/community_post_model.dart';
import 'package:myapp/models/announcement_model.dart';
import 'package:myapp/models/poll_model.dart';
import 'package:myapp/models/shared_document_model.dart';

class CommunityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────
  // Community Posts (Forum)
  // ──────────────────────────────────────────────

  Stream<List<CommunityPost>> getPosts(String societyId) {
    return _db
        .collection('communityPosts')
        .where('societyId', isEqualTo: societyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommunityPost.fromFirestore(d)).toList());
  }

  Future<void> createPost(CommunityPost post) async {
    await _db.collection('communityPosts').add(post.toFirestore());
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('communityPosts').doc(postId).delete();
  }

  Future<void> toggleLike(String postId, String userId) async {
    final ref = _db.collection('communityPosts').doc(postId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final likes = List<String>.from(doc.data()?['likes'] ?? []);
    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }
    await ref.update({'likes': likes});
  }

  // Comments
  Stream<List<PostComment>> getComments(String postId) {
    return _db
        .collection('postComments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostComment.fromFirestore(d)).toList());
  }

  Future<void> addComment(PostComment comment) async {
    await _db.runTransaction((tx) async {
      final postRef = _db.collection('communityPosts').doc(comment.postId);
      final commentRef = _db.collection('postComments').doc();

      tx.set(commentRef, comment.toFirestore());
      tx.update(postRef, {'commentCount': FieldValue.increment(1)});
    });
  }

  // ──────────────────────────────────────────────
  // Announcements (Notices)
  // ──────────────────────────────────────────────

  Stream<List<AnnouncementModel>> getAnnouncements(String societyId) {
    return _db
        .collection('societies')
        .doc(societyId)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AnnouncementModel.fromFirestore(doc)).toList());
  }

  Future<void> createAnnouncement(AnnouncementModel announcement) {
    return _db
        .collection('societies')
        .doc(announcement.societyId)
        .collection('announcements')
        .add(announcement.toFirestore());
  }

  // ──────────────────────────────────────────────
  // Polls
  // ──────────────────────────────────────────────

  Stream<List<PollModel>> getPolls(String societyId) {
    return _db
        .collection('societies')
        .doc(societyId)
        .collection('polls')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => PollModel.fromFirestore(doc)).toList());
  }

  Future<void> voteInPoll({required String societyId, required String pollId, required String userId, required String optionId}) async {
    final pollRef = _db.collection('societies').doc(societyId).collection('polls').doc(pollId);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(pollRef);
      if (!snapshot.exists) return;

      final poll = PollModel.fromFirestore(snapshot);
      if (poll.votedUserIds.contains(userId)) return;

      final updatedOptions = poll.options.map((opt) {
        if (opt.id == optionId) {
          return PollOption(id: opt.id, text: opt.text, votes: opt.votes + 1);
        }
        return opt;
      }).toList();

      transaction.update(pollRef, {
        'options': updatedOptions.map((o) => o.toMap()).toList(),
        'votedUserIds': FieldValue.arrayUnion([userId]),
      });
    });
  }

  // ──────────────────────────────────────────────
  // Document Library
  // ──────────────────────────────────────────────

  Stream<List<SharedDocumentModel>> getDocuments(String societyId) {
    return _db
        .collection('societies')
        .doc(societyId)
        .collection('documents')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => SharedDocumentModel.fromFirestore(doc)).toList());
  }
}
