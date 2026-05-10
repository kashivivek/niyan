import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/society_model.dart';
import 'package:myapp/models/member_model.dart';
import 'dart:developer' as developer;

/// Service for society-level operations: CRUD, member management, invitations.
class SocietyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────
  // Society CRUD
  // ──────────────────────────────────────────────

  /// Get all societies the user is a member of.
  Stream<List<SocietyModel>> getUserSocieties(String userId) {
    return _db
        .collection('societies')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => SocietyModel.fromFirestore(doc)).toList());
  }

  /// Get a single society by ID.
  Stream<SocietyModel> getSociety(String societyId) {
    return _db
        .collection('societies')
        .doc(societyId)
        .snapshots()
        .map((doc) => SocietyModel.fromFirestore(doc));
  }

  /// Get a single society by ID (Future).
  Future<SocietyModel?> getSocietyById(String societyId) async {
    final doc = await _db.collection('societies').doc(societyId).get();
    if (!doc.exists) return null;
    return SocietyModel.fromFirestore(doc);
  }

  /// Create a new society and add the creator as super admin.
  Future<String> createSociety({
    required String name,
    required String address,
    required String city,
    String? state,
    String? pincode,
    required String createdByUserId,
    String? createdByName,
    String? createdByEmail,
  }) async {
    final docRef = _db.collection('societies').doc();

    final society = SocietyModel(
      id: docRef.id,
      name: name,
      address: address,
      city: city,
      state: state,
      pincode: pincode,
      createdBy: createdByUserId,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();

    // 1. Create the society document
    batch.set(docRef, {
      ...society.toFirestore(),
      'memberIds': [createdByUserId], // Denormalized for querying
    });

    // 2. Add creator as society manager (admin) in the members subcollection
    final memberRef = docRef.collection('members').doc(createdByUserId);
    final member = MemberModel(
      id: createdByUserId,
      societyId: docRef.id,
      role: SocietyRole.admin,
      joinedAt: DateTime.now(),
      status: MemberStatus.active,
      displayName: createdByName,
      email: createdByEmail,
    );
    batch.set(memberRef, member.toFirestore());

    // 3. Update the user document with the new society
    final userRef = _db.collection('users').doc(createdByUserId);
    batch.update(userRef, {
      'societyIds': FieldValue.arrayUnion([docRef.id]),
      'activeSocietyId': docRef.id,
    });

    await batch.commit();
    developer.log('Society created: ${docRef.id} by $createdByUserId');
    return docRef.id;
  }

  /// Update society details.
  Future<void> updateSociety(SocietyModel society) {
    return _db
        .collection('societies')
        .doc(society.id)
        .update(society.toFirestore());
  }

  /// Update society settings (billing, GST, etc.).
  Future<void> updateSocietySettings(
      String societyId, SocietySettings settings) {
    return _db
        .collection('societies')
        .doc(societyId)
        .update({'settings': settings.toMap()});
  }

  // ──────────────────────────────────────────────
  // Member Management
  // ──────────────────────────────────────────────

  /// Get all members of a society.
  Stream<List<MemberModel>> getMembers(String societyId) {
    return _db
        .collection('societies')
        .doc(societyId)
        .collection('members')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => MemberModel.fromFirestore(doc)).toList());
  }

  /// Get a specific member's record.
  Future<MemberModel?> getMember(String societyId, String userId) async {
    final doc = await _db
        .collection('societies')
        .doc(societyId)
        .collection('members')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return MemberModel.fromFirestore(doc);
  }

  /// Alias for getMember for cleaner context switching code
  Future<MemberModel?> getMembership(String societyId, String userId) => getMember(societyId, userId);

  /// Get a member stream for real-time role updates.
  Stream<MemberModel?> getMemberStream(String societyId, String userId) {
    return _db
        .collection('societies')
        .doc(societyId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? MemberModel.fromFirestore(doc) : null);
  }

  /// Invite a user to a society with a given role.
  Future<void> inviteMember({
    required String societyId,
    required String userId,
    required SocietyRole role,
    required String invitedBy,
    String? displayName,
    String? email,
    String? phone,
    List<String> unitIds = const [],
  }) async {
    final batch = _db.batch();

    final memberRef = _db
        .collection('societies')
        .doc(societyId)
        .collection('members')
        .doc(userId);

    final member = MemberModel(
      id: userId,
      societyId: societyId,
      role: role,
      unitIds: unitIds,
      joinedAt: DateTime.now(),
      status: MemberStatus.pending,
      invitedBy: invitedBy,
      displayName: displayName,
      email: email,
      phone: phone,
    );
    batch.set(memberRef, member.toFirestore());

    // Add to society's denormalized memberIds
    final societyRef = _db.collection('societies').doc(societyId);
    batch.update(societyRef, {
      'memberIds': FieldValue.arrayUnion([userId]),
    });

    // Add to user's societyIds
    final userRef = _db.collection('users').doc(userId);
    batch.update(userRef, {
      'societyIds': FieldValue.arrayUnion([societyId]),
    });

    await batch.commit();
    developer.log('Member invited: $userId to society $societyId as ${role.label}');
  }

  /// Update a member's role.
  Future<void> updateMemberRole(
      String societyId, String userId, SocietyRole newRole) {
    return _db
        .collection('societies')
        .doc(societyId)
        .collection('members')
        .doc(userId)
        .update({'role': newRole.toString()});
  }

  /// Remove a member from a society.
  Future<void> removeMember(String societyId, String userId) async {
    final batch = _db.batch();

    final memberRef = _db
        .collection('societies')
        .doc(societyId)
        .collection('members')
        .doc(userId);
    batch.delete(memberRef);

    final societyRef = _db.collection('societies').doc(societyId);
    batch.update(societyRef, {
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    final userRef = _db.collection('users').doc(userId);
    batch.update(userRef, {
      'societyIds': FieldValue.arrayRemove([societyId]),
    });

    await batch.commit();
    developer.log('Member removed: $userId from society $societyId');
  }

  /// Set the user's active society.
  Future<void> setActiveSociety(String userId, String societyId) {
    return _db
        .collection('users')
        .doc(userId)
        .update({'activeSocietyId': societyId});
  }
}
