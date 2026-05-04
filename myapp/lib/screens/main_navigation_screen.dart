import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/theme_provider.dart';

class MainNavigationScreen extends StatelessWidget {
  final Widget child;

  const MainNavigationScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/properties') || location.startsWith('/property')) return 1;
    if (location.startsWith('/tenants') || location.startsWith('/tenant')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // Dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/properties');
        break;
      case 2:
        context.go('/tenants');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  backgroundColor: Colors.white,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
                    child: Image.asset('assets/images/logo_icon.png', height: 40),
                  ),
                  selectedIconTheme: const IconThemeData(color: ThemeProvider.accentBlue, size: 28),
                  unselectedIconTheme: IconThemeData(color: Colors.grey.shade400, size: 24),
                  selectedLabelTextStyle: const TextStyle(color: ThemeProvider.accentBlue, fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  onDestinationSelected: (index) => _onItemTapped(index, context),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.apartment_outlined),
                      selectedIcon: Icon(Icons.apartment_rounded),
                      label: Text('Properties'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline_rounded),
                      selectedIcon: Icon(Icons.people_rounded),
                      label: Text('Tenants'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                VerticalDivider(thickness: 1, width: 1, color: Colors.grey.shade200),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) => _onItemTapped(index, context),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: ThemeProvider.accentBlue,
              unselectedItemColor: Colors.grey.shade400,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.apartment_outlined), activeIcon: Icon(Icons.apartment_rounded), label: 'Properties'),
                BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), activeIcon: Icon(Icons.people_rounded), label: 'Tenants'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
              ],
            ),
          ),
        );
      },
    );
  }
}
