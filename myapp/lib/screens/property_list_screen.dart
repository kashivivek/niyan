import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  bool _showAllUnits = false; // Default back to false
  String? _searchQuery;

  final Set<String> _selectedPropertyIds = {};
  final Set<String> _selectedStatusTypes = {}; // 'occupied', 'vacant'

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['filter'] == 'vacant') {
      _showAllUnits = true;
      _selectedStatusTypes.add('vacant');
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final ownerId = databaseService.currentOwnerId;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _showAllUnits ? 'Portfolio Inventory' : 'My Properties',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Row(
              children: [
                Text('All Units', style: TextStyle(color: _showAllUnits ? ThemeProvider.accentBlue : Colors.grey, fontWeight: FontWeight.w600)),
                Switch(
                  value: _showAllUnits,
                  activeColor: ThemeProvider.accentBlue,
                  onChanged: (val) => setState(() => _showAllUnits = val),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          if (_showAllUnits) _buildAllUnitsFilters(databaseService, ownerId),
          Expanded(
            child: _showAllUnits 
              ? _buildAllUnitsView(databaseService, ownerId)
              : _buildPropertiesView(databaseService, ownerId),
          ),
        ],
      ),
      floatingActionButton: _showAllUnits ? null : FloatingActionButton(
        backgroundColor: ThemeProvider.accentBlue,
        onPressed: () => context.push('/properties/add'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: _showAllUnits ? 'Search units...' : 'Search properties...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      ),
    );
  }

  Widget _buildAllUnitsFilters(DatabaseService db, String ownerId) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _buildFilterButton(
            label: 'Properties',
            count: _selectedPropertyIds.length,
            onTap: () => _showMultiSelectDialog(
              title: 'Filter Properties',
              stream: db.getProperties(ownerId),
              selectedIds: _selectedPropertyIds,
              idMapper: (PropertyModel p) => p.id,
              labelMapper: (PropertyModel p) => p.name,
              onChanged: (ids) => setState(() {
                _selectedPropertyIds.clear();
                _selectedPropertyIds.addAll(ids);
              }),
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterButton(
            label: 'Status',
            count: _selectedStatusTypes.length,
            onTap: () => _showStatusFilterDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({required String label, required int count, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: count > 0 ? ThemeProvider.accentBlue.withOpacity(0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: count > 0 ? ThemeProvider.accentBlue : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count > 0 ? '$label ($count)' : label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                  color: count > 0 ? ThemeProvider.accentBlue : Colors.grey.shade600,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: count > 0 ? ThemeProvider.accentBlue : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showMultiSelectDialog<T>({
    required String title,
    required Stream<List<T>> stream,
    required Set<String> selectedIds,
    required String Function(T) idMapper,
    required String Function(T) labelMapper,
    required Function(Set<String>) onChanged,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        Set<String> tempSelected = Set.from(selectedIds);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: StreamBuilder<List<T>>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final items = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final id = idMapper(item);
                        return CheckboxListTile(
                          value: tempSelected.contains(id),
                          title: Text(labelMapper(item)),
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) tempSelected.add(id);
                              else tempSelected.remove(id);
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    onChanged(tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Set<String> tempSelected = Set.from(_selectedStatusTypes);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: tempSelected.contains('occupied'),
                    title: const Text('Occupied'),
                    onChanged: (val) => setDialogState(() => val == true ? tempSelected.add('occupied') : tempSelected.remove('occupied')),
                  ),
                  CheckboxListTile(
                    value: tempSelected.contains('vacant'),
                    title: const Text('Vacant'),
                    onChanged: (val) => setDialogState(() => val == true ? tempSelected.add('vacant') : tempSelected.remove('vacant')),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatusTypes.clear();
                      _selectedStatusTypes.addAll(tempSelected);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPropertiesView(DatabaseService databaseService, String ownerId) {
    return StreamBuilder<List<PropertyModel>>(
      stream: databaseService.getProperties(ownerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var properties = snapshot.data!;
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          properties = properties.where((p) => p.name.toLowerCase().contains(_searchQuery!) || p.address.toLowerCase().contains(_searchQuery!)).toList();
        }

        if (properties.isEmpty) return _buildEmptyState('No properties found');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: properties.length,
          itemBuilder: (context, index) => _PropertyCard(property: properties[index]),
        );
      },
    );
  }

  Widget _buildAllUnitsView(DatabaseService databaseService, String ownerId) {
    final unitsStream = databaseService.allUnits(ownerId);
    final propertiesStream = databaseService.getProperties(ownerId);
    final tenantsStream = databaseService.getTenants(ownerId);

    return StreamBuilder<List<dynamic>>(
      stream: CombineLatestStream.list([unitsStream, propertiesStream, tenantsStream]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final units = snapshot.data![0] as List<UnitModel>;
        final properties = snapshot.data![1] as List<PropertyModel>;
        final tenants = snapshot.data![2] as List<TenantModel>;

        final propMap = {for (var p in properties) p.id: p};
        final tenantMap = {for (var t in tenants) t.id: t};

        var filteredUnits = units;

        // Filter by property
        if (_selectedPropertyIds.isNotEmpty) {
          filteredUnits = filteredUnits.where((u) => _selectedPropertyIds.contains(u.propertyId)).toList();
        }

        // Filter by status
        if (_selectedStatusTypes.isNotEmpty) {
          filteredUnits = filteredUnits.where((u) => _selectedStatusTypes.contains(u.isOccupied ? 'occupied' : 'vacant')).toList();
        }

        // Search
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          filteredUnits = filteredUnits.where((u) {
            final pName = propMap[u.propertyId]?.name.toLowerCase() ?? '';
            return u.unitNumber.toLowerCase().contains(_searchQuery!) || pName.contains(_searchQuery!);
          }).toList();
        }

        if (filteredUnits.isEmpty) return _buildEmptyState('No units found');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUnits.length,
          itemBuilder: (context, index) {
            final unit = filteredUnits[index];
            final property = propMap[unit.propertyId];
            final tenant = unit.currentTenantId != null ? tenantMap[unit.currentTenantId] : null;

            String subtitle = 'Vacant';
            if (unit.isOccupied) {
              subtitle = 'Occupied by ${tenant?.name ?? 'Unknown'}';
            } else if (unit.lastVacatedDate != null) {
              subtitle = 'Vacant since ${DateFormat('MMM dd, yyyy').format(unit.lastVacatedDate!)}';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: ListTile(
                onTap: () => context.push('/property/${unit.propertyId}/unit/${unit.id}', extra: unit),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: (unit.isOccupied ? ThemeProvider.accentBlue : Colors.teal).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(unit.isOccupied ? Icons.person_outline : Icons.door_front_door_outlined, color: unit.isOccupied ? ThemeProvider.accentBlue : Colors.teal),
                ),
                title: Text('${unit.unitNumber} - ${property?.name ?? 'Property'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => context.push('/property/${property.id}', extra: property),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (property.imageUrl != null && property.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(property.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  'https://maps.googleapis.com/maps/api/staticmap?center=${Uri.encodeComponent('${property.address},${property.city}')}&zoom=15&size=800x400&maptype=roadmap&markers=color:red%7Clabel:P%7C${Uri.encodeComponent('${property.address},${property.city}')}&key=AIzaSyDecNKEtkvBJ5tojkOlWVI4CvaLRQMTFKo',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    width: double.infinity,
                    color: ThemeProvider.primaryNavy.withOpacity(0.05),
                    child: Icon(Icons.apartment_rounded, size: 48, color: ThemeProvider.primaryNavy.withOpacity(0.2)),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(property.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: ThemeProvider.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(property.type.name.toUpperCase(), style: TextStyle(color: ThemeProvider.accentBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(property.address, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
