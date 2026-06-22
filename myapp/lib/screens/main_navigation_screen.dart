import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/notification_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/society_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/models/sos_model.dart';
import 'package:myapp/services/sos_service.dart';
import 'package:myapp/widgets/responsive_layout.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget child;
  const MainNavigationScreen({super.key, required this.child});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  bool _isAutoRouting = false;
  bool _hasRestoredMode = false;

  Future<void> _checkAutoRoute() async {
    if (_isAutoRouting || _hasRestoredMode) return;

    final user = Provider.of<UserModel?>(context, listen: false);
    final appMode = Provider.of<AppModeProvider>(context, listen: false);

    if (user == null) return;
    _hasRestoredMode = true;

    // Step 1: Load the user's last-used mode from Firestore (via UserModel)
    await appMode.loadSavedMode(user: user);

    // Step 2: If the persisted mode is society (or role demands it), 
    // restore the active society context.
    final savedSocietyId = user.activeSocietyId ?? await appMode.getPersistedSocietyId();
    
    final isSocietyRole = user.currentRole == AppRole.guard ||
        user.currentRole == AppRole.societyAdmin ||
        user.currentRole == AppRole.superAdmin ||
        user.currentRole == AppRole.treasurer ||
        user.currentRole == AppRole.resident ||
        user.currentRole == AppRole.tenant;

    final shouldBeSocietyMode = appMode.isSocietyMode || isSocietyRole;

    if (shouldBeSocietyMode && savedSocietyId != null && appMode.activeSociety == null) {
      if (mounted) setState(() => _isAutoRouting = true);
      try {
        final society = await SocietyService().getSocietyById(savedSocietyId);
        final membership = await SocietyService().getMembership(savedSocietyId, user.uid);

        if (society != null && membership != null) {
          await appMode.switchToSocietyMode(
            society: society,
            membership: membership,
            userId: user.uid,
          );
        }
      } finally {
        if (mounted) setState(() => _isAutoRouting = false);
      }
    }
  }

  void _showContextSwitcher(BuildContext context) {
    context.push('/select-society');
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);

    // Auto-restore session context once user profile is loaded
    if (user != null && !_hasRestoredMode && !_isAutoRouting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAutoRoute();
      });
    }

    if (_isAutoRouting) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: ThemeProvider.accentTeal),
              const SizedBox(height: 16),
              Text('Switching to Society Mode...', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopHeader(),
                if (appMode.isSocietyMode && appMode.activeSociety != null && (user?.currentRole == AppRole.guard || user?.currentRole == AppRole.societyAdmin))
                  _buildGlobalSosBanner(appMode.activeSociety!.id),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
            if (!isKeyboardOpen)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildGlassmorphicNavBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSosBanner(String societyId) {
    return StreamBuilder<List<SosModel>>(
      stream: SosService().getActiveSosAlerts(societyId),
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? [];
        if (alerts.isEmpty) return const SizedBox.shrink();
        final alert = alerts.first;
        
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).cardColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOS ACTIVE: ${alert.residentName}', style: GoogleFonts.outfit(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      alert.unitNumber.isNotEmpty 
                        ? 'Unit ${alert.unitNumber} needs assistance.'
                        : 'Emergency assistance requested immediately.', 
                      style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 12)
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => SosService().resolveSos(alert.id, 'Guard'),
                style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                child: const Text('RESOLVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopHeader() {
    final location = GoRouterState.of(context).matchedLocation;
    final canPop = GoRouter.of(context).canPop();
    final isDashboard = location == '/' || location == '/dashboard';
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? Colors.white : ThemeProvider.primaryNavy;
    
    String title = AppLocalizations.of(context)?.home ?? 'Home';
    if (location.startsWith('/properties')) title = AppLocalizations.of(context)?.properties ?? 'Properties';
    if (location.startsWith('/tenants')) title = AppLocalizations.of(context)?.tenants ?? 'Tenants';
    if (location.startsWith('/transactions')) title = AppLocalizations.of(context)?.finance ?? 'Finance';
    if (location.startsWith('/notifications')) title = AppLocalizations.of(context)?.alerts ?? 'Alerts';
    if (location.startsWith('/more')) title = AppLocalizations.of(context)?.settings ?? 'Settings';
    if (location.startsWith('/gate')) title = 'Gate Control';
    if (location.startsWith('/notices')) title = 'Society Notices';
    if (location.startsWith('/community')) title = 'Community';
    if (location.startsWith('/profile')) title = 'Profile';
 
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top Left: Back Button or Logo
          Align(
            alignment: Alignment.centerLeft,
            child: (!isDashboard && canPop)
                ? IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: headerColor),
                    onPressed: () => context.pop(),
                  )
                : Image.asset(
                    'assets/images/logo_full.png',
                    height: 28,
                    errorBuilder: (context, _, __) => Text(
                      'NIYAN',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: headerColor,
                      ),
                    ),
                  ),
          ),
          
          // Top Center: Page Title
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: headerColor.withOpacity(0.8),
            ),
          ),
          
          // Top Right: Profile Avatar (with photo or icon fallback)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.go('/more'),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ThemeProvider.accentTeal.withOpacity(0.4), width: 1.5),
                ),
                child: Builder(builder: (ctx) {
                  final u = Provider.of<UserModel?>(ctx);
                  if (u?.photoUrl != null && u!.photoUrl!.isNotEmpty) {
                    return CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(u.photoUrl!),
                      onBackgroundImageError: (_, __) {},
                    );
                  }
                  return CircleAvatar(
                    radius: 14,
                    backgroundColor: ThemeProvider.accentTeal.withOpacity(0.1),
                    child: const Icon(Icons.person_rounded, size: 16, color: ThemeProvider.accentTeal),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildGlassmorphicNavBar() {
    final appMode = Provider.of<AppModeProvider>(context);
    final user = Provider.of<UserModel?>(context);
    final items = _getNavItems(appMode.mode);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    int selectedIndex = items.indexWhere((item) => currentLocation.startsWith(item.route));
    if (selectedIndex == -1) selectedIndex = 0;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final needsScroll = !isDesktop && (screenWidth < (items.length * 80));

    return StreamBuilder<List<NotificationModel>>(
      stream: user != null
          ? Provider.of<DatabaseService>(context, listen: false)
              .getNotifications(user.uid)
          : const Stream.empty(),
      builder: (context, snapshot) {
        final unreadCount = (snapshot.data ?? []).where((n) => n.isRead == false).length;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          FlutterAppBadger.isAppBadgeSupported().then((supported) {
            if (supported) {
              if (unreadCount > 0) {
                FlutterAppBadger.updateBadgeCount(unreadCount);
              } else {
                FlutterAppBadger.removeBadge();
              }
            }
          }).catchError((_) {});
        });

        Widget buildNavIcon(int idx, _NavItem item, bool isSelected, {bool compact = false}) {
          final isAlerts = item.route == '/notifications';
          final iconWidget = Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                item.icon,
                color: isSelected ? ThemeProvider.accentTeal : Colors.white70,
                size: 22,
              ),
              if (isAlerts && unreadCount > 0)
                Positioned(
                  top: -5,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.go(item.route),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: compact ? 80 : null,
              padding: compact
                  ? const EdgeInsets.symmetric(vertical: 8)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? ThemeProvider.accentTeal.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconWidget,
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: isSelected ? ThemeProvider.accentTeal : Colors.white70,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        Widget navContent;
        if (needsScroll) {
          navContent = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: items.asMap().entries.map((entry) {
                  return buildNavIcon(entry.key, entry.value, entry.key == selectedIndex, compact: true);
                }).toList(),
              ),
            ),
          );
        } else {
          navContent = Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              return buildNavIcon(entry.key, entry.value, entry.key == selectedIndex);
            }).toList(),
          );
        }

        return Center(
          child: Container(
            height: 75,
            width: isDesktop ? 600 : double.infinity,
            margin: EdgeInsets.fromLTRB(20, 0, 20, isDesktop ? 25 : 15),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeProvider.primaryNavy.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: navContent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  List<_NavItem> _getNavItems(AppMode mode) {
    if (mode == AppMode.standalone) {
      return [
        _NavItem(Icons.dashboard_rounded, AppLocalizations.of(context)?.home ?? 'Home', '/dashboard'),
        _NavItem(Icons.apartment_rounded, AppLocalizations.of(context)?.properties ?? 'Properties', '/properties'),
        _NavItem(Icons.people_alt_rounded, AppLocalizations.of(context)?.tenants ?? 'Tenants', '/tenants'),
        _NavItem(Icons.account_balance_wallet_rounded, AppLocalizations.of(context)?.finance ?? 'Finance', '/transactions'),
        _NavItem(Icons.notifications_rounded, AppLocalizations.of(context)?.alerts ?? 'Alerts', '/notifications'),
        _NavItem(Icons.more_horiz_rounded, AppLocalizations.of(context)?.settings ?? 'Settings', '/more'),
      ];
    } else {
      return [
        _NavItem(Icons.grid_view_rounded, 'Society', '/dashboard'),
        _NavItem(Icons.groups_rounded, 'Community', '/community'),
        _NavItem(Icons.shield_rounded, 'Gate', '/gate'),
        _NavItem(Icons.campaign_rounded, 'Notices', '/notices'),
        _NavItem(Icons.notifications_rounded, 'Alerts', '/notifications'),
        _NavItem(Icons.more_horiz_rounded, 'Settings', '/more'),
      ];
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  _NavItem(this.icon, this.label, this.route);
}
