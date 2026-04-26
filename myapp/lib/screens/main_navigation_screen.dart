import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/screens/dashboard_screen.dart';
import 'package:myapp/screens/property_list_screen.dart';
import 'package:myapp/screens/tenant_list_screen.dart';
import 'package:myapp/screens/settings_screen.dart';
import 'package:myapp/providers/theme_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PropertyListScreen(),
    const TenantListScreen(),
    const SettingsScreen(), // Profiling/Settings
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  backgroundColor: Colors.white,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
                    child: Image.asset('assets/images/logo_icon.png', height: 40),
                  ),
                  selectedIconTheme: IconThemeData(color: ThemeProvider.accentBlue, size: 28),
                  unselectedIconTheme: IconThemeData(color: Colors.grey.shade400, size: 24),
                  selectedLabelTextStyle: TextStyle(color: ThemeProvider.accentBlue, fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  onDestinationSelected: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
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
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: ThemeProvider.accentBlue,
              unselectedItemColor: Colors.grey.shade400,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.dashboard_outlined)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.dashboard_rounded)),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.apartment_outlined)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.apartment_rounded)),
                  label: 'Properties',
                ),
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.people_outline_rounded)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.people_rounded)),
                  label: 'Tenants',
                ),
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline_rounded)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded)),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
