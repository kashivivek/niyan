import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/providers/app_mode_provider.dart';
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
import 'package:myapp/screens/society/society_selector_screen.dart';
import 'package:myapp/screens/invoice_list_screen.dart';
import 'package:myapp/screens/invoice_detail_screen.dart';
import 'package:myapp/screens/vendor_directory_screen.dart';
import 'package:myapp/screens/add_vendor_screen.dart';
import 'package:myapp/screens/security/visitor_pre_approve_screen.dart';
import 'package:myapp/screens/security/gate_dashboard_screen.dart';
import 'package:myapp/screens/security/daily_help_screen.dart';
import 'package:myapp/screens/admin/helpdesk_screen.dart';
import 'package:myapp/screens/admin/amenities_screen.dart';
import 'package:myapp/screens/admin/parking_management_screen.dart';
import 'package:myapp/screens/admin/lease_tracking_screen.dart';
import 'package:myapp/screens/admin/assets_screen.dart';
import 'package:myapp/screens/admin/create_invoice_screen.dart';
import 'package:myapp/screens/community/notice_board_screen.dart';
import 'package:myapp/screens/community/polls_screen.dart';
import 'package:myapp/screens/community/document_library_screen.dart';
import 'package:myapp/screens/resident/resident_dashboard_screen.dart';
import 'package:myapp/screens/resident/ledger_screens.dart';
import 'package:myapp/screens/more_menu_screen.dart';
import 'package:myapp/screens/admin/invite_member_screen.dart';
import 'package:myapp/screens/admin/society_settings_screen.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/invoice_model.dart';
import 'package:myapp/models/vendor_model.dart';
import 'package:myapp/screens/landing_page.dart';
import 'package:myapp/screens/society/community_screen.dart';
import 'package:myapp/screens/society/community_post_detail_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppRouter {
  final AuthService authService;
  final AppModeProvider appModeProvider;

  AppRouter(this.authService, this.appModeProvider);

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _CombinedListenable([
      GoRouterRefreshStream(authService.user),
      appModeProvider,
    ]),
    redirect: (context, state) {
      if (!authService.initialized) return null;

      final isLoggedIn = authService.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isLandingPage = state.matchedLocation == '/';

      // On Web, allow access to landing page without login
      // On Mobile, if not logged in, force login
      if (!isLoggedIn) {
        if (kIsWeb && isLandingPage) return null; // Allow landing page on web
        if (!isLoggingIn) return '/login'; // Force login everywhere else
      }
      
      if (isLoggedIn && (isLoggingIn || isLandingPage)) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Society selector — outside shell so no bottom nav shown
      GoRoute(
        path: '/select-society',
        builder: (context, state) => const SocietySelectorScreen(),
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
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreMenuScreen(),
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
                  return UnitDetailScreen(
                      unit: unit, unitId: uid, propertyId: pid);
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
          // Phase 1: Financial & Billing
          GoRoute(
            path: '/invoices',
            builder: (context, state) => const InvoiceListScreen(),
          ),
          GoRoute(
            path: '/invoices/create',
            builder: (context, state) => const CreateInvoiceScreen(),
          ),
          GoRoute(
            path: '/invoices/:id',
            builder: (context, state) {
              final inv = state.extra as InvoiceModel?;
              return InvoiceDetailScreen(
                invoiceId: state.pathParameters['id']!,
                invoice: inv,
              );
            },
          ),
          GoRoute(
            path: '/vendors',
            builder: (context, state) => const VendorDirectoryScreen(),
          ),
          GoRoute(
            path: '/vendors/add',
            builder: (context, state) => const AddVendorScreen(),
          ),
          GoRoute(
            path: '/vendors/:id',
            builder: (context, state) {
              final vendor = state.extra as VendorModel?;
              return _PlaceholderScreen(
                title: vendor?.name ?? 'Vendor Detail',
              );
            },
          ),
          GoRoute(
            path: '/purchase-orders',
            builder: (context, state) => const _PlaceholderScreen(title: 'Purchase Orders'),
          ),
          // Phase 2: Security & Visitor Management
          GoRoute(
            path: '/visitors/invite',
            builder: (context, state) => const VisitorPreApproveScreen(),
          ),
          GoRoute(
            path: '/visitors',
            builder: (context, state) => const _PlaceholderScreen(title: 'Visitor Log'),
          ),
          GoRoute(
            path: '/gate',
            builder: (context, state) => const GateDashboardScreen(),
          ),
          GoRoute(
            path: '/daily-help',
            builder: (context, state) => const DailyHelpScreen(),
          ),
          // Phase 3: Administrative Workflows
          GoRoute(
            path: '/helpdesk',
            builder: (context, state) => const HelpdeskScreen(),
          ),
          GoRoute(
            path: '/amenities',
            builder: (context, state) => const AmenitiesScreen(),
          ),
          GoRoute(
            path: '/parking',
            builder: (context, state) => const ParkingManagementScreen(),
          ),
          GoRoute(
            path: '/leases',
            builder: (context, state) => const LeaseTrackingScreen(),
          ),
          GoRoute(
            path: '/assets',
            builder: (context, state) => const AssetsScreen(),
          ),
          // Phase 4: Community Engagement
          GoRoute(
            path: '/notices',
            builder: (context, state) => const NoticeBoardScreen(),
          ),
          GoRoute(
            path: '/polls',
            builder: (context, state) => const PollsScreen(),
          ),
          GoRoute(
            path: '/documents',
            builder: (context, state) => const DocumentLibraryScreen(),
          ),
          GoRoute(
            path: '/resident-ledger',
            builder: (context, state) => const ResidentLedgerScreen(),
          ),
          GoRoute(
            path: '/gate-pass',
            builder: (context, state) => const GatePassScreen(),
          ),
          GoRoute(
            path: '/society/invite',
            builder: (context, state) => const InviteMemberScreen(),
          ),
          GoRoute(
            path: '/society/settings',
            builder: (context, state) => const SocietySettingsScreen(),
          ),
          GoRoute(
            path: '/society/edit',
            builder: (context, state) => const _PlaceholderScreen(title: 'Edit Society Profile'),
          ),
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityScreen(),
            routes: [
              GoRoute(
                path: 'post/:id',
                builder: (context, state) => CommunityPostDetailScreen(postId: state.pathParameters['id']!),
              ),
            ],
          ),
          // Profile edit (from More screen Edit button)
          GoRoute(
            path: '/profile/edit',
            builder: (context, state) => const SettingsScreen(),
          ),
          // Notification settings standalone screen
          GoRoute(
            path: '/settings/notifications',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Combines multiple [Listenable]s so GoRouter refreshes on any change.
class _CombinedListenable extends ChangeNotifier {
  final List<Listenable> listenables;

  _CombinedListenable(this.listenables) {
    for (final l in listenables) {
      l.addListener(notifyListeners);
    }
  }

  @override
  void dispose() {
    for (final l in listenables) {
      l.removeListener(notifyListeners);
    }
    super.dispose();
  }
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

/// Temporary placeholder for screens not yet implemented.
/// Shows a coming-soon message with the screen name.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Coming soon in the next phase',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
