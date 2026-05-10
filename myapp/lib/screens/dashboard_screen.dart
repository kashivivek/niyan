import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
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

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (appMode.mode == AppMode.standalone) {
      return const StandaloneDashboardScreen();
    }

    // Society Mode Routing
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
}
