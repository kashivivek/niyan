import 'package:cloud_firestore/cloud_firestore.dart';

/// Defines what a user can do within a given society.
enum SocietyRole {
  superAdmin,  // Platform owner — full control
  admin,       // Society admin / RWA secretary — manage society
  committee,   // Committee member — approve expenses, manage helpdesk
  owner,       // Flat owner — view dues, vote, raise tickets
  tenant,      // Renter — view dues, raise tickets (no voting)
  guard,       // Security — gate management, visitor logs
}

/// Extension to provide human-readable labels and permission checks.
extension SocietyRoleExtension on SocietyRole {
  String get label {
    switch (this) {
      case SocietyRole.superAdmin:
        return 'Super Admin';
      case SocietyRole.admin:
        return 'Admin';
      case SocietyRole.committee:
        return 'Committee Member';
      case SocietyRole.owner:
        return 'Owner';
      case SocietyRole.tenant:
        return 'Tenant';
      case SocietyRole.guard:
        return 'Security Guard';
    }
  }

  /// Whether this role has administrative privileges.
  bool get isAdmin =>
      this == SocietyRole.superAdmin || this == SocietyRole.admin;

  /// Whether this role can approve expenses and manage operations.
  bool get canApprove =>
      this == SocietyRole.superAdmin ||
      this == SocietyRole.admin ||
      this == SocietyRole.committee;

  /// Whether this role represents a resident (owner or tenant).
  bool get isResident =>
      this == SocietyRole.owner || this == SocietyRole.tenant;

  /// Whether this role can vote in society polls.
  bool get canVote => this == SocietyRole.owner;

  /// Whether this role can manage gate/visitor operations.
  bool get canManageGate =>
      this == SocietyRole.guard ||
      this == SocietyRole.admin ||
      this == SocietyRole.superAdmin;
}

/// Represents a user's membership within a specific society.
/// A single user can be a member of multiple societies with different roles.
class MemberModel {
  final String id; // Same as the user's UID
  final String societyId;
  final SocietyRole role;
  final List<String> unitIds; // Units this member is associated with
  final DateTime joinedAt;
  final MemberStatus status;
  final String? invitedBy; // userId who invited this member
  final String? displayName; // Cached from UserModel for quick lookups
  final String? email;
  final String? phone;

  MemberModel({
    required this.id,
    required this.societyId,
    required this.role,
    this.unitIds = const [],
    required this.joinedAt,
    this.status = MemberStatus.active,
    this.invitedBy,
    this.displayName,
    this.email,
    this.phone,
  });

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberModel(
      id: doc.id,
      societyId: data['societyId'] ?? '',
      role: SocietyRole.values.firstWhere(
        (e) => e.toString() == data['role'],
        orElse: () => SocietyRole.tenant,
      ),
      unitIds: List<String>.from(data['unitIds'] ?? []),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MemberStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => MemberStatus.active,
      ),
      invitedBy: data['invitedBy'],
      displayName: data['displayName'],
      email: data['email'],
      phone: data['phone'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'societyId': societyId,
      'role': role.toString(),
      'unitIds': unitIds,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'status': status.toString(),
      'invitedBy': invitedBy,
      'displayName': displayName,
      'email': email,
      'phone': phone,
    };
  }

  MemberModel copyWith({
    String? id,
    String? societyId,
    SocietyRole? role,
    List<String>? unitIds,
    DateTime? joinedAt,
    MemberStatus? status,
    String? invitedBy,
    String? displayName,
    String? email,
    String? phone,
  }) {
    return MemberModel(
      id: id ?? this.id,
      societyId: societyId ?? this.societyId,
      role: role ?? this.role,
      unitIds: unitIds ?? this.unitIds,
      joinedAt: joinedAt ?? this.joinedAt,
      status: status ?? this.status,
      invitedBy: invitedBy ?? this.invitedBy,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

enum MemberStatus {
  active,
  pending,  // Invited but not yet accepted
  removed,
}
