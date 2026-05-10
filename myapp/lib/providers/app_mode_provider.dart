import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/models/member_model.dart';
import 'package:myapp/models/society_model.dart';
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
/// This is the key dual-mode orchestrator — all screens check this
/// to decide which UI and data to show.
class AppModeProvider with ChangeNotifier {
  AppMode _mode = AppMode.standalone;
  SocietyModel? _activeSociety;
  MemberModel? _activeMembership;
  final RoleService roleService = RoleService();

  static const _modeKey = 'app_mode';
  static const _activeSocietyKey = 'active_society_id';
  static const _lastViewedPropertyKey = 'last_viewed_property_id';

  AppMode get mode => _mode;
  SocietyModel? get activeSociety => _activeSociety;
  MemberModel? get activeMembership => _activeMembership;
  bool get isSocietyMode => _mode == AppMode.society;
  bool get isStandaloneMode => _mode == AppMode.standalone;

  /// Load persisted mode from local storage on startup.
  Future<void> loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_modeKey);
    
    if (savedMode == AppMode.society.toString()) {
      _mode = AppMode.society;
    } else {
      _mode = AppMode.standalone;
    }
    notifyListeners();
  }

  Future<void> setLastViewedProperty(String propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastViewedPropertyKey, propertyId);
  }

  Future<String?> getLastViewedProperty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastViewedPropertyKey);
  }

  /// Switch to standalone landlord mode.
  Future<void> switchToStandaloneMode() async {
    _mode = AppMode.standalone;
    _activeSociety = null;
    _activeMembership = null;
    roleService.setActiveMembership(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, AppMode.standalone.toString());
    await prefs.remove(_activeSocietyKey);
    notifyListeners();
  }

  /// Switch to society ERP mode with the given society and membership.
  Future<void> switchToSocietyMode({
    required SocietyModel society,
    required MemberModel membership,
  }) async {
    _mode = AppMode.society;
    _activeSociety = society;
    _activeMembership = membership;
    roleService.setActiveMembership(membership);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, AppMode.society.toString());
    await prefs.setString(_activeSocietyKey, society.id);
    notifyListeners();
  }

  /// Called when the user switches to a different society (multi-society support).
  Future<void> changeSociety({
    required SocietyModel society,
    required MemberModel membership,
  }) async {
    _activeSociety = society;
    _activeMembership = membership;
    roleService.setActiveMembership(membership);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSocietyKey, society.id);
    notifyListeners();
  }

  /// Get the persisted active society ID (used on app restart to restore context).
  Future<String?> getPersistedSocietyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeSocietyKey);
  }
}
