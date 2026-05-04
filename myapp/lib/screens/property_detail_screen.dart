import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/utils/currency_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyDetailScreen extends StatelessWidget {
  final PropertyModel? property;
  final String propertyId;

  const PropertyDetailScreen({super.key, this.property, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final user = Provider.of<UserModel?>(context);

    return StreamBuilder<PropertyModel>(
      stream: databaseService.getPropertyStream(propertyId),
      initialData: property,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final currentProperty = snapshot.data!;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    currentProperty.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'property_${currentProperty.id}',
                        child: currentProperty.imageUrl != null && currentProperty.imageUrl!.isNotEmpty
                            ? Image.network(currentProperty.imageUrl!, fit: BoxFit.cover)
                            : Image.network(
                                'https://maps.googleapis.com/maps/api/staticmap?center=${Uri.encodeComponent('${currentProperty.address},${currentProperty.city}')}&zoom=15&size=800x400&maptype=roadmap&markers=color:red%7Clabel:P%7C${Uri.encodeComponent('${currentProperty.address},${currentProperty.city}')}&key=AIzaSyDecNKEtkvBJ5tojkOlWVI4CvaLRQMTFKo',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: ThemeProvider.primaryNavy,
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.map_outlined, size: 64, color: Colors.white54),
                                        SizedBox(height: 8),
                                        Text('Add Maps API Key in code to view', style: TextStyle(color: Colors.white54, fontSize: 14)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => context.push('/properties/edit', extra: currentProperty),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _confirmDelete(context, databaseService, currentProperty),
                  ),
                ],
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildInfoSection(currentProperty),
                  _buildMaintenanceSection(context, databaseService, currentProperty),
                  _buildActionsSection(context, databaseService, currentProperty),
                  _buildUnitsSection(context, databaseService, currentProperty, user),
                ]),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: ThemeProvider.accentBlue,
            onPressed: () => context.push('/property/${currentProperty.id}/unit/add'),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(PropertyModel property) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: ThemeProvider.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(property.type.name.toUpperCase(), style: TextStyle(color: ThemeProvider.accentBlue, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(property.city, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          Text(property.address, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection(BuildContext context, DatabaseService databaseService, PropertyModel property) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Maintenance Directory', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: ThemeProvider.accentBlue),
                onPressed: () => _showAddMaintenanceDialog(context, databaseService, property),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (property.maintenanceContacts.isEmpty)
            _buildNearbyMaintenance(context, databaseService, property)
          else
            ...property.maintenanceContacts.map((contact) => _buildContactTile(contact, property, databaseService)),
        ],
      ),
    );
  }

  Widget _buildNearbyMaintenance(BuildContext context, DatabaseService databaseService, PropertyModel property) {
    return StreamBuilder<List<MaintenanceContact>>(
      stream: databaseService.getNearbyMaintenanceContacts(property.city, property.id),
      builder: (context, snapshot) {
        final nearby = snapshot.data ?? [];
        if (nearby.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('No maintenance contacts stored for this property.')),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text('Suggested from nearby properties:', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            ),
            ...nearby.map((c) => _buildContactTile(c, property, databaseService, isFallback: true)),
          ],
        );
      },
    );
  }

  Widget _buildContactTile(MaintenanceContact contact, PropertyModel property, DatabaseService databaseService, {bool isFallback = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ThemeProvider.accentBlue.withOpacity(0.1),
          child: Icon(_getCategoryIcon(contact.category), color: ThemeProvider.accentBlue, size: 20),
        ),
        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(contact.category),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.call_rounded, color: Colors.green),
              onPressed: () => launchUrl(Uri.parse('tel:${contact.phone}')),
            ),
            if (!isFallback)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: () => _removeContact(databaseService, property, contact),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    category = category.toLowerCase();
    if (category.contains('plumb')) return Icons.plumbing_rounded;
    if (category.contains('electr')) return Icons.electrical_services_rounded;
    if (category.contains('clean')) return Icons.cleaning_services_rounded;
    if (category.contains('paint')) return Icons.format_paint_rounded;
    return Icons.build_outlined;
  }

  Future<void> _removeContact(DatabaseService db, PropertyModel property, MaintenanceContact contact) async {
    final newList = List<MaintenanceContact>.from(property.maintenanceContacts)
      ..removeWhere((c) => c.phone == contact.phone && c.name == contact.name);
    await db.updateProperty(property.copyWith(maintenanceContacts: newList));
  }

  Widget _buildActionsSection(BuildContext context, DatabaseService databaseService, PropertyModel property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeProvider.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showExpenseModal(context, databaseService, property),
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Add Expense'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsSection(BuildContext context, DatabaseService databaseService, PropertyModel property, UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Units', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
              TextButton.icon(
                onPressed: () => context.push('/property/${property.id}/unit/add'),
                icon: const Icon(Icons.add),
                label: const Text('Add Unit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<UnitModel>>(
            stream: databaseService.getUnits(property.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final units = snapshot.data!;
              if (units.isEmpty) return const Center(child: Text('No units added yet.'));

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unit = units[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                    child: ListTile(
                      onTap: () => context.push('/property/${property.id}/unit/${unit.id}', extra: unit),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text('Unit ${unit.unitNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(unit.isOccupied ? 'Occupied' : 'Vacant', style: TextStyle(color: unit.isOccupied ? ThemeProvider.accentBlue : Colors.teal, fontWeight: FontWeight.w600)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(CurrencyHelper.format(unit.monthlyRent, user?.currency ?? 'USD'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const Text('per month', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddMaintenanceDialog(BuildContext context, DatabaseService db, PropertyModel property) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category (e.g. Plumber)')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
              final contact = MaintenanceContact(
                name: nameController.text.trim(),
                category: categoryController.text.trim(),
                phone: phoneController.text.trim(),
              );
              final newList = List<MaintenanceContact>.from(property.maintenanceContacts)..add(contact);
              await db.updateProperty(property.copyWith(maintenanceContacts: newList));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showExpenseModal(BuildContext context, DatabaseService databaseService, PropertyModel property) async {
    final unitsSnap = await databaseService.getUnits(property.id).first;
    if (context.mounted) {
      _showExpenseSheet(context, databaseService, property, unitsSnap);
    }
  }

  void _showExpenseSheet(BuildContext context, DatabaseService databaseService, PropertyModel property, List<UnitModel> unitsSnap) async {
    final ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;
    
    final years = List.generate(5, (i) => now.year - 2 + i);
    final months = List.generate(12, (i) => i + 1);

    final Set<String> selectedUnitIds = unitsSnap.map((u) => u.id).toSet();
    bool billToTenants = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Add Property Expense', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description_outlined)),
                        validator: (v) => v == null || v.isEmpty ? 'Enter a description' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Total Amount', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money_rounded)),
                        validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a valid amount' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Select Units', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => setModalState(() => selectedUnitIds.addAll(unitsSnap.map((u) => u.id))),
                                child: const Text('Select All', style: TextStyle(fontSize: 12)),
                              ),
                              TextButton(
                                onPressed: () => setModalState(() => selectedUnitIds.clear()),
                                child: const Text('Unselect All', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ...unitsSnap.map((unit) => CheckboxListTile(
                        value: selectedUnitIds.contains(unit.id),
                        title: Text('Unit ${unit.unitNumber}'),
                        onChanged: (v) => setModalState(() => v == true ? selectedUnitIds.add(unit.id) : selectedUnitIds.remove(unit.id)),
                      )),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: ThemeProvider.accentBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: () async {
                            if (!formKey.currentState!.validate() || selectedUnitIds.isEmpty) return;
                            final monthStr = '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
                            await databaseService.addPropertyExpense(
                              propertyId: property.id,
                              ownerId: ownerId,
                              totalAmount: double.parse(amountController.text),
                              description: descController.text,
                              unitIds: selectedUnitIds.toList(),
                              month: monthStr,
                              billToTenants: billToTenants,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: const Text('Add Expense'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, DatabaseService databaseService, PropertyModel property) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text('Are you sure you want to delete "${property.name}"? This action cannot be undone and will delete all units and records associated with it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await databaseService.deleteProperty(property.id);
              if (context.mounted) {
                context.go('/properties');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property deleted')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
