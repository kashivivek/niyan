import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/screens/property_detail_screen.dart';
import 'package:myapp/screens/add_property_screen.dart';
import 'package:myapp/providers/theme_provider.dart';

class PropertyListScreen extends StatelessWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 160,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Image.asset('assets/images/logo_full.png', fit: BoxFit.contain),
        ),
        title: const SizedBox.shrink(),
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: user.asyncExpand((user) => user != null ? databaseService.getProperties(user.uid) : Stream.value([])),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No properties found. Tap + to add one.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          final properties = snapshot.data!;
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1);

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding for bottom nav
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.1, // Fixed ratio to prevent huge stretched images 
            ),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return _buildPropertyCard(context, property);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeProvider.accentBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPropertyScreen()));
        },
      ),
    );
  }

  Widget _buildPropertyCard(BuildContext context, PropertyModel property) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => PropertyDetailScreen(property: property)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Header
            Stack(
              children: [
                Hero(
                  tag: 'property_${property.id}',
                  child: property.imageUrl != null && property.imageUrl!.isNotEmpty
                      ? Image.network(
                          property.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          'https://maps.googleapis.com/maps/api/staticmap?center=${Uri.encodeComponent('${property.address}, ${property.city}')}&zoom=15&size=600x300&maptype=roadmap&markers=color:red%7C${Uri.encodeComponent('${property.address}, ${property.city}')}&key=AIzaSyDecNKEtkvBJ5tojkOlWVI4CvaLRQMTFKo',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey.shade100,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text('Add Maps API Key in code to view', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      property.type.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
            // Details Area
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    property.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${property.address}, ${property.city}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
