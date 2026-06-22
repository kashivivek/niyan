import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/widgets/responsive_layout.dart';
import 'package:go_router/go_router.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

enum PropertyViewMode { properties, units }

class _PropertyListScreenState extends State<PropertyListScreen> {
  PropertyViewMode _viewMode = PropertyViewMode.properties;

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 960 : double.infinity),
          child: Column(
        children: [
          // View Mode Toggle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _buildToggleItem(PropertyViewMode.properties, 'Properties', Icons.business_rounded),
                  _buildToggleItem(PropertyViewMode.units, 'Units', Icons.meeting_room_rounded),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: _viewMode == PropertyViewMode.properties 
              ? _buildPropertiesGrid(db, user.uid, isDesktop)
              : _buildUnitsGrid(db, user.uid, isDesktop),
          ),
        ],
      ),
      ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/properties/add'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? ThemeProvider.accentTeal : ThemeProvider.primaryNavy,
          icon: Icon(Icons.add_rounded, color: Colors.white),
          label: Text('Add Property', style: GoogleFonts.outfit(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildToggleItem(PropertyViewMode mode, String label, IconData icon) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? ThemeProvider.primaryNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
              SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertiesGrid(DatabaseService db, String userId, bool isDesktop) {
    final appMode = Provider.of<AppModeProvider>(context, listen: false);
    final stream = appMode.isSocietyMode && appMode.activeSociety != null
        ? db.getSocietyProperties(appMode.activeSociety!.id)
        : db.getProperties(userId);

    return StreamBuilder<List<PropertyModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final properties = snapshot.data ?? [];
        if (properties.isEmpty) return _buildEmptyState('No properties found');

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 2 : 1,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: isDesktop ? 1.8 : 1.6,
          ),
          itemCount: properties.length,
          itemBuilder: (context, index) => _PropertyMapCard(property: properties[index]),
        );
      },
    );
  }

  Widget _buildUnitsGrid(DatabaseService db, String userId, bool isDesktop) {
    final appMode = Provider.of<AppModeProvider>(context, listen: false);
    final stream = appMode.isSocietyMode && appMode.activeSociety != null
        ? db.societyUnitsWithPropertyInfo(appMode.activeSociety!.id)
        : db.allUnitsWithPropertyInfo(userId);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        final unitMaps = snapshot.data ?? [];
        
        if (unitMaps.isEmpty) return _buildEmptyState('No units found');

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: unitMaps.length,
          itemBuilder: (context, index) {
            return _UnitGridCard(unit: unitMaps[index]);
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllUnits(DatabaseService db, List<PropertyModel> properties) async {
    List<Map<String, dynamic>> allUnits = [];
    for (var prop in properties) {
      final units = await db.getUnits(prop.id).first;
      for (var unit in units) {
        allUnits.add({
          'unit': unit,
          'propertyName': prop.name,
          'propertyId': prop.id,
          'propertyAddress': prop.address,
        });
      }
    }
    return allUnits;
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo_icon.png',
            height: 64,
            width: 64,
            color: Theme.of(context).dividerColor,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.business_rounded, size: 64, color: Color(0xFFE5E7EB)),
          ),
          SizedBox(height: 16),
          Text(message, style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

class _UnitGridCard extends StatelessWidget {
  final Map<String, dynamic> unit;
  const _UnitGridCard({required this.unit});

  @override
  Widget build(BuildContext context) {
    final u = unit['unit'];
    final propName = unit['propertyName'];
    final propAddress = unit['propertyAddress'];
    final mapUrl = 'https://maps.googleapis.com/maps/api/staticmap?center=${Uri.encodeComponent(propAddress)}&zoom=17&size=300x300&maptype=roadmap&markers=color:blue%7C${Uri.encodeComponent(propAddress)}&key=AIzaSyDecNKEtkvBJ5tojkOlWVI4CvaLRQMTFKo';
    
    return InkWell(
      onTap: () => context.push('/property/${unit['propertyId']}/unit/${u.id}', extra: u),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  mapUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: ThemeProvider.accentTeal.withOpacity(0.05),
                    child: const Center(child: Icon(Icons.meeting_room_rounded, color: ThemeProvider.accentTeal)),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.unitNumber,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).cardColor,
                      ),
                    ),
                    Text(
                      propName,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    u.isOccupied ? Icons.person_rounded : Icons.door_front_door_rounded,
                    size: 14,
                    color: u.isOccupied ? ThemeProvider.accentTeal : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyMapCard extends StatelessWidget {
  final PropertyModel property;
  const _PropertyMapCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final mapUrl = 'https://maps.googleapis.com/maps/api/staticmap?center=${Uri.encodeComponent('${property.address},${property.city}')}&zoom=15&size=600x300&maptype=roadmap&markers=color:red%7Clabel:P%7C${Uri.encodeComponent('${property.address},${property.city}')}&key=AIzaSyDecNKEtkvBJ5tojkOlWVI4CvaLRQMTFKo';

    return GestureDetector(
      onTap: () {
        context.read<AppModeProvider>().setLastViewedProperty(property.id);
        context.push('/property/${property.id}', extra: property);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  mapUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).dividerColor,
                    child: const Center(child: Icon(Icons.map_outlined, color: Colors.grey)),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                property.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).cardColor,
                                ),
                              ),
                              if (context.read<AuthService>().currentUser?.uid != property.ownerId) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Shared', style: TextStyle(color: Theme.of(context).cardColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, color: ThemeProvider.accentTeal, size: 12),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  property.address,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ThemeProvider.accentTeal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.chevron_right_rounded, color: Theme.of(context).cardColor, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
