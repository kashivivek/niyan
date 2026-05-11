import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/models/member_model.dart';
import 'package:myapp/models/society_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/role_service.dart';

/// Defines the two operational modes of the Niyan app.
enum AppMode {
  /// Standalone landlord mode — original Niyan experience.
  /// Single user manages their own properties, tenants, and finances.
  standalone,

  /// Society ERP mode — multi-role, multi-user society management.
  /// Includes visitor management, helpdesk, amenities, community features.
  society,
}

/// Central provider that manages which mode the app is running in,
/// and the active society context (in society mode).
///
/// Mode is persisted to Firestore (for cross-device sync) AND to
/// SharedPreferences (as a fast local cache so there's no flicker on
/// same-device re-launch before the Firestore stream arrives).
class AppModeProvider with ChangeNotifier {
  AppMode _mode = AppMode.standalone;
  SocietyModel? _activeSociety;
  MemberModel? _activeMembership;
  bool _initialized = false;
  final RoleService roleService = RoleService();

  static const _modeKey = 'app_mode';
  static const _activeSocietyKey = 'active_society_id';
  static const _lastViewedPropertyKey = 'last_viewed_property_id';

  AppMode get mode => _mode;
  SocietyModel? get activeSociety => _activeSociety;
  MemberModel? get activeMembership => _activeMembership;
  bool get isInitialized => _initialized;
  bool get isSocietyMode => _mode == AppMode.society;
  bool get isStandaloneMode => _mode == AppMode.standalone;

  /// Load persisted mode from UserModel (Firestore, cross-device) with a
  /// local SharedPreferences fallback for same-device speed.
  ///
  /// Call this on startup after the first UserModel emission from AuthService.
  Future<void> loadSavedMode({UserModel? user}) async {
    final prefs = await SharedPreferences.getInstance();

    // Prefer the Firestore-backed value from the UserModel
    String? savedMode = user?.activeMode;

    // Fall back to local cache if Firestore hasn't set it yet
    savedMode ??= prefs.getString(_modeKey);

    if (savedMode == AppMode.society.toString() || savedMode == 'society') {
      _mode = AppMode.society;
    } else if (savedMode == AppMode.standalone.toString() || savedMode == 'standalone') {
      _mode = AppMode.standalone;
    } else {
      // First-time login: apply role-based default
      _mode = _defaultModeForRole(user?.currentRole);
    }

    _initialized = true;
    notifyListeners();
  }

  /// Determine the default mode for a given role on first login.
  AppMode _defaultModeForRole(AppRole? role) {
    switch (role) {
      case AppRole.guard:
      case AppRole.societyAdmin:
      case AppRole.superAdmin:
      case AppRole.treasurer:
      case AppRole.resident:
      case AppRole.tenant:
        return AppMode.society;
      case AppRole.owner:
      default:
        return AppMode.standalone;
    }
  }

  Future<void> setLastViewedProperty(String propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastViewedPropertyKey, propertyId);
  }

  Future<String?> getLastViewedProperty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastViewedPropertyKey);
  }

  /// Switch to standalone landlord mode and persist to both stores.
  Future<void> switchToStandaloneMode({String? userId}) async {
    _mode = AppMode.standalone;
    _activeSociety = null;
    _activeMembership = null;
    roleService.setActiveMembership(null);

    // Persist locally for fast same-device restore
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, 'standalone');
    await prefs.remove(_activeSocietyKey);

    // Persist to Firestore for cross-device sync
    if (userId != null) {
      await AuthService.persistUserMode(
        uid: userId,
        mode: 'standalone',
        activeSocietyId: null,
      );
    }

    notifyListeners();
  }

  /// Switch to society ERP mode and persist to both stores.
  Future<void> switchToSocietyMode({
    required SocietyModel society,
    required MemberModel membership,
    String? userId,
  }) async {
    _mode = AppMode.society;
    _activeSociety = society;
    _activeMembership = membership;
    roleService.setActiveMembership(membership);

    // Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, 'society');
    await prefs.setString(_activeSocietyKey, society.id);

    // Persist to Firestore for cross-device sync
    if (userId != null) {
      await AuthService.persistUserMode(
        uid: userId,
        mode: 'society',
        activeSocietyId: society.id,
      );
    }

    notifyListeners();
  }

  /// Called when the user switches to a different society (multi-society support).
  Future<void> changeSociety({
    required SocietyModel society,
    required MemberModel membership,
    String? userId,
  }) async {
    _activeSociety = society;
    _activeMembership = membership;
    roleService.setActiveMembership(membership);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSocietyKey, society.id);

    if (userId != null) {
      await AuthService.persistUserMode(
        uid: userId,
        mode: 'society',
        activeSocietyId: society.id,
      );
    }

    notifyListeners();
  }

  /// Get the persisted active society ID (used on app restart to restore context).
  Future<String?> getPersistedSocietyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeSocietyKey);
  }
}
