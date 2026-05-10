import 'package:flutter/foundation.dart';
import 'package:myapp/models/member_model.dart';

/// Centralized permission checker for the ERP.
/// All UI gates and route guards should use this service
/// rather than checking roles directly.
class RoleService {
  MemberModel? _currentMember;

  MemberModel? get currentMember => _currentMember;
  SocietyRole? get currentRole => _currentMember?.role;
  String? get currentSocietyId => _currentMember?.societyId;
  bool get hasActiveMembership =>
      _currentMember != null && _currentMember!.status == MemberStatus.active;

  /// Set the active membership context (called on society switch or login).
  void setActiveMembership(MemberModel? member) {
    _currentMember = member;
    debugPrint('RoleService: active membership set to ${member?.role.label ?? 'none'} in society ${member?.societyId ?? 'none'}');
  }

  // ──────────────────────────────────────────────
  // Financial & Billing Permissions
  // ──────────────────────────────────────────────

  /// Can generate invoices, manage billing settings.
  bool get canManageBilling =>
      _currentMember?.role.isAdmin ?? false;

  /// Can approve expenses and purchase orders.
  bool get canApproveExpenses =>
      _currentMember?.role.canApprove ?? false;

  /// Can view financial reports and transaction history.
  bool get canViewFinancials =>
      _currentMember != null &&
      (_currentMember!.role.isAdmin || _currentMember!.role == SocietyRole.committee);

  /// Can manage vendor directory and payments.
  bool get canManageVendors =>
      _currentMember?.role.isAdmin ?? false;

  // ──────────────────────────────────────────────
  // Property & Tenant Permissions
  // ──────────────────────────────────────────────

  /// Can add/edit/delete properties and units.
  bool get canManageProperties =>
      _currentMember?.role.isAdmin ?? false;

  /// Can assign/unassign tenants to units.
  bool get canManageTenants =>
      _currentMember?.role.isAdmin ?? false;

  /// Can view their own unit details.
  bool get canViewOwnUnit =>
      _currentMember?.role.isResident ?? false;

  // ──────────────────────────────────────────────
  // Security & Visitor Permissions
  // ──────────────────────────────────────────────

  /// Can manage gate operations (check-in/out, approve visitors).
  bool get canManageGate =>
      _currentMember?.role.canManageGate ?? false;

  /// Can pre-approve visitors for their own unit.
  bool get canPreApproveVisitors =>
      _currentMember?.role.isResident ?? false;

  /// Can view the full visitor log.
  bool get canViewVisitorLog =>
      _currentMember != null &&
      (_currentMember!.role.canManageGate || _currentMember!.role == SocietyRole.committee);

  /// Can trigger emergency alerts.
  bool get canTriggerEmergency =>
      _currentMember != null; // All members can trigger emergencies

  // ──────────────────────────────────────────────
  // Administrative Permissions
  // ──────────────────────────────────────────────

  /// Can manage helpdesk tickets (assign, close, escalate).
  bool get canManageHelpdesk =>
      _currentMember?.role.canApprove ?? false;

  /// Can raise helpdesk tickets.
  bool get canRaiseTickets =>
      _currentMember?.role.isResident ?? false;

  /// Can manage amenity booking rules and schedules.
  bool get canManageAmenities =>
      _currentMember?.role.isAdmin ?? false;

  /// Can book amenities.
  bool get canBookAmenities =>
      _currentMember?.role.isResident ?? false;

  /// Can manage parking allocation.
  bool get canManageParking =>
      _currentMember?.role.isAdmin ?? false;

  /// Can manage lease agreements and move-in/out workflows.
  bool get canManageLeases =>
      _currentMember?.role.isAdmin ?? false;

  // ──────────────────────────────────────────────
  // Community Permissions
  // ──────────────────────────────────────────────

  /// Can create announcements and meeting minutes.
  bool get canPostAnnouncements =>
      _currentMember?.role.canApprove ?? false;

  /// Can create polls.
  bool get canCreatePolls =>
      _currentMember?.role.canApprove ?? false;

  /// Can vote in polls.
  bool get canVote =>
      _currentMember?.role.canVote ?? false;

  /// Can upload shared documents.
  bool get canUploadDocuments =>
      _currentMember?.role.canApprove ?? false;

  /// Can view shared documents.
  bool get canViewDocuments =>
      _currentMember != null;

  // ──────────────────────────────────────────────
  // Society Management
  // ──────────────────────────────────────────────

  /// Can invite/remove members.
  bool get canManageMembers =>
      _currentMember?.role.isAdmin ?? false;

  /// Can edit society settings (billing config, GST, etc.).
  bool get canEditSocietySettings =>
      _currentMember?.role.isAdmin ?? false;

  /// Can delete the society.
  bool get canDeleteSociety =>
      _currentMember?.role == SocietyRole.superAdmin;
}
