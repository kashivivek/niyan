import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/register_screen.dart';
import 'package:myapp/screens/main_navigation_screen.dart';
import 'package:myapp/screens/property_detail_screen.dart';
import 'package:myapp/screens/unit_detail_screen.dart';
import 'package:myapp/screens/tenant_detail_screen.dart';
import 'package:myapp/screens/all_transactions_screen.dart';
import 'package:myapp/screens/dashboard_screen.dart';
import 'package:myapp/screens/property_list_screen.dart';
import 'package:myapp/screens/tenant_list_screen.dart';
import 'package:myapp/screens/settings_screen.dart';
import 'package:myapp/screens/add_property_screen.dart';
import 'package:myapp/screens/add_tenant_screen.dart';
import 'package:myapp/screens/add_transaction_screen.dart';
import 'package:myapp/screens/edit_property_screen.dart';
import 'package:myapp/screens/edit_unit_screen.dart';
import 'package:myapp/screens/edit_tenant_screen.dart';
import 'package:myapp/screens/add_unit_screen.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:provider/provider.dart';

class AppRouter {
  final AuthService authService;

  AppRouter(this.authService);

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authService.user),
    redirect: (context, state) {
      if (!authService.initialized) return null; // Wait for initial auth check

      final isLoggedIn = authService.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/properties',
            builder: (context, state) => const PropertyListScreen(),
          ),
          GoRoute(
            path: '/tenants',
            builder: (context, state) => const TenantListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/properties/add',
            builder: (context, state) => const AddPropertyScreen(),
          ),
          GoRoute(
            path: '/properties/edit',
            builder: (context, state) {
              final property = state.extra as PropertyModel;
              return EditPropertyScreen(property: property);
            },
          ),
          GoRoute(
            path: '/tenants/add',
            builder: (context, state) => const AddTenantScreen(),
          ),
          GoRoute(
            path: '/tenants/edit',
            builder: (context, state) {
              final tenant = state.extra as TenantModel;
              return EditTenantScreen(tenant: tenant);
            },
          ),
          GoRoute(
            path: '/property/:pid',
            builder: (context, state) {
              final property = state.extra as PropertyModel?;
              final pid = state.pathParameters['pid']!;
              return PropertyDetailScreen(property: property, propertyId: pid);
            },
            routes: [
              GoRoute(
                path: 'unit/add',
                builder: (context, state) {
                  final pid = state.pathParameters['pid']!;
                  return AddUnitScreen(propertyId: pid);
                },
              ),
              GoRoute(
                path: 'unit/:uid',
                builder: (context, state) {
                  final unit = state.extra as UnitModel?;
                  final uid = state.pathParameters['uid']!;
                  final pid = state.pathParameters['pid']!;
                  return UnitDetailScreen(unit: unit, unitId: uid, propertyId: pid);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final unit = state.extra as UnitModel;
                      return EditUnitScreen(unit: unit);
                    },
                  ),
                  GoRoute(
                    path: 'transaction/add',
                    builder: (context, state) {
                      final unit = state.extra as UnitModel;
                      return AddTransactionScreen(unit: unit);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/tenant/:tid',
            builder: (context, state) {
              final tenant = state.extra as TenantModel?;
              final tid = state.pathParameters['tid']!;
              return TenantDetailScreen(tenant: tenant, tenantId: tid);
            },
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const AllTransactionsScreen(),
          ),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
