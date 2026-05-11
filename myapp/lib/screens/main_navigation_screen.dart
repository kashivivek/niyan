import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/society_service.dart';
import 'package:myapp/models/sos_model.dart';
import 'package:myapp/services/sos_service.dart';
import 'package:myapp/widgets/responsive_layout.dart';

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
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: ThemeProvider.accentTeal),
              SizedBox(height: 16),
              Text('Switching to Society Mode...', style: TextStyle(color: ThemeProvider.primaryNavy, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOS ACTIVE: ${alert.residentName}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
    
    String title = 'Home';
    if (location.startsWith('/properties')) title = 'Properties';
    if (location.startsWith('/tenants')) title = 'Tenants';
    if (location.startsWith('/transactions')) title = 'Finance';
    if (location.startsWith('/more')) title = 'Settings';
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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: ThemeProvider.primaryNavy),
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
                        color: ThemeProvider.primaryNavy,
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
              color: ThemeProvider.primaryNavy.withOpacity(0.8),
            ),
          ),
          
          // Top Right: Profile Icon
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _showContextSwitcher(context),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ThemeProvider.accentTeal.withOpacity(0.2), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: ThemeProvider.accentTeal.withOpacity(0.05),
                  child: const Icon(Icons.person_rounded, size: 16, color: ThemeProvider.accentTeal),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildGlassmorphicNavBar() {
    final appMode = Provider.of<AppModeProvider>(context);
    final items = _getNavItems(appMode.mode);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    int selectedIndex = items.indexWhere((item) => currentLocation.startsWith(item.route));
    if (selectedIndex == -1) selectedIndex = 0;

    final isDesktop = MediaQuery.of(context).size.width > 900;

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isSelected = idx == selectedIndex;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.go(item.route),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? ThemeProvider.accentTeal.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected ? ThemeProvider.accentTeal : Colors.white70,
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
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
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_NavItem> _getNavItems(AppMode mode) {
    if (mode == AppMode.standalone) {
      return [
        _NavItem(Icons.dashboard_rounded, 'Home', '/dashboard'),
        _NavItem(Icons.apartment_rounded, 'Properties', '/properties'),
        _NavItem(Icons.people_alt_rounded, 'Tenants', '/tenants'),
        _NavItem(Icons.account_balance_wallet_rounded, 'Finance', '/transactions'),
        _NavItem(Icons.more_horiz_rounded, 'Settings', '/more'),
      ];
    } else {
      return [
        _NavItem(Icons.grid_view_rounded, 'Society', '/dashboard'),
        _NavItem(Icons.groups_rounded, 'Community', '/community'),
        _NavItem(Icons.shield_rounded, 'Gate', '/gate'),
        _NavItem(Icons.campaign_rounded, 'Notices', '/notices'),
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
