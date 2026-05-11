import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/property_service.dart';
import 'package:myapp/screens/standalone_dashboard_screen.dart';
import 'package:myapp/screens/admin/admin_dashboard_screen.dart';
import 'package:myapp/screens/resident/resident_dashboard_screen.dart';
import 'package:myapp/screens/security/gate_dashboard_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);

    if (user == null || !appMode.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: ThemeProvider.accentTeal)));
    }

    // Society Mode routing — role-based
    if (appMode.mode == AppMode.society) {
      final role = user.currentRole;
      switch (role) {
        case AppRole.guard:
          return const GateDashboardScreen();
        case AppRole.superAdmin:
        case AppRole.societyAdmin:
        case AppRole.treasurer:
          return const AdminDashboardScreen();
        case AppRole.resident:
        case AppRole.tenant:
        case AppRole.owner:
        default:
          return const ResidentDashboardScreen();
      }
    }

    // Standalone Mode — but gate society-only users who have no properties
    final isSocietyRole = user.currentRole == AppRole.guard ||
        user.currentRole == AppRole.societyAdmin ||
        user.currentRole == AppRole.superAdmin ||
        user.currentRole == AppRole.treasurer ||
        user.currentRole == AppRole.resident ||
        user.currentRole == AppRole.tenant;

    if (isSocietyRole) {
      // Check if this society-role user actually has standalone properties
      return FutureBuilder<bool>(
        future: _hasAnyProperty(context, user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: ThemeProvider.accentTeal)),
            );
          }
          if (snapshot.data == true) {
            return const StandaloneDashboardScreen();
          }
          // No standalone properties — redirect to mode switcher
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/select-society');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: ThemeProvider.accentTeal)),
          );
        },
      );
    }

    return const StandaloneDashboardScreen();
  }

  Future<bool> _hasAnyProperty(BuildContext context, String uid) async {
    try {
      final propertyService = Provider.of<PropertyService>(context, listen: false);
      final props = await propertyService.getProperties(uid).first;
      return props.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
