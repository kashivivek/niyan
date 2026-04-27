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
import './add_unit_screen.dart';
import './edit_property_screen.dart';
import './unit_detail_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                property.name,
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
                    tag: 'property_${property.id}',
                    child: property.imageUrl != null && property.imageUrl!.isNotEmpty
                        ? Image.network(property.imageUrl!, fit: BoxFit.cover)
                        : Image.network(
                            'https://maps.googleapis.com/maps/api/staticmap?center=${Uri.encodeComponent('${property.address}, ${property.city}')}&zoom=15&size=800x400&maptype=roadmap&markers=color:red%7C${Uri.encodeComponent('${property.address}, ${property.city}')}&key=AIzaSyDecNKEtkvBJ5tojkOlWVI4CvaLRQMTFKo',
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
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Property',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditPropertyScreen(property: property))),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Delete Property',
                onPressed: () => _confirmDelete(context, databaseService),
              ),
            ],
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${property.address}, ${property.city}',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Units', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          StreamBuilder<List<UnitModel>>(
            stream: databaseService.getUnits(property.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(context));
              }

              final units = snapshot.data!;
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return UnitCard(unit: units[index], currency: user?.currency);
                    },
                    childCount: units.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_expense_fab',
            icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
            backgroundColor: Colors.orange.shade700,
            label: const Text('Add Property Expense', style: TextStyle(color: Colors.white)),
            onPressed: () => _showAddExpenseDialog(context, databaseService),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_unit_fab',
            icon: const Icon(Icons.add_home_outlined, color: Colors.white),
            backgroundColor: ThemeProvider.accentBlue,
            label: const Text('Add Unit', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddUnitScreen(propertyId: property.id, property: property)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, DatabaseService databaseService) async {
    final unitsSnap = await databaseService.getUnits(property.id).first;
    if (!context.mounted) return;

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
                      Text('Split equally across selected units.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter a description' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Total Amount',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter an amount';
                          if (double.tryParse(v) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedMonth,
                              decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
                              items: months.map((m) => DropdownMenuItem(value: m, child: Text(DateFormat('MMMM').format(DateTime(2022, m))))).toList(),
                              onChanged: (v) { if (v != null) setModalState(() => selectedMonth = v); },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedYear,
                              decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                              items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                              onChanged: (v) { if (v != null) setModalState(() => selectedYear = v); },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Apply to Units', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...unitsSnap.map((unit) {
                        final checked = selectedUnitIds.contains(unit.id);
                        return CheckboxListTile(
                          value: checked,
                          title: Text('Unit ${unit.unitNumber}'),
                          subtitle: Text(unit.isOccupied ? 'Occupied' : 'Vacant'),
                          activeColor: ThemeProvider.accentBlue,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) selectedUnitIds.add(unit.id);
                              else selectedUnitIds.remove(unit.id);
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Bill to Tenants'),
                        subtitle: const Text('Add this charge to each selected unit\'s ledger as "Due"'),
                        value: billToTenants,
                        onChanged: (v) => setModalState(() => billToTenants = v),
                        activeColor: ThemeProvider.accentBlue,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeProvider.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            if (selectedUnitIds.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Select at least one unit.')));
                              return;
                            }
                            final monthStr = '${selectedYear}-${selectedMonth.toString().padLeft(2, '0')}';
                            try {
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
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Expense split across ${selectedUnitIds.length} unit(s) for $monthStr')),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                          child: Text('Add Expense', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.door_front_door_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 24),
        const Text(
          'No Units Found',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Get started by adding units to this property.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, DatabaseService databaseService) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Property'),
          content: Text('Are you sure you want to delete ${property.name}? This will also delete all associated units.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await databaseService.deleteProperty(property.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${property.name} deleted')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class UnitCard extends StatelessWidget {
  final UnitModel unit;
  final String? currency;

  const UnitCard({super.key, required this.unit, this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UnitDetailScreen(unit: unit))),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeProvider.primaryNavy.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.door_front_door_outlined, color: ThemeProvider.primaryNavy),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit ${unit.unitNumber}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyHelper.format(unit.monthlyRent, currency),
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: unit.isOccupied ? Colors.teal.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    unit.isOccupied ? 'Occupied' : 'Vacant',
                    style: TextStyle(
                      color: unit.isOccupied ? Colors.teal.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
