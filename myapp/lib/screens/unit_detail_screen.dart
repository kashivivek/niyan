import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/screens/edit_unit_screen.dart';
import 'package:myapp/screens/add_transaction_screen.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/theme_provider.dart';

class UnitDetailScreen extends StatelessWidget {
  final UnitModel unit;

  const UnitDetailScreen({super.key, required this.unit});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text('Unit ${unit.unitNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditUnitScreen(unit: unit))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, databaseService),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUnitInfoCard(context, currencyFormat),
            const SizedBox(height: 24),
            _buildTenantInfo(context, databaseService),
            const SizedBox(height: 24),
            _buildRecentTransactions(databaseService),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ThemeProvider.accentBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(unit: unit))),
      ),
    );
  }

  Widget _buildUnitInfoCard(BuildContext context, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Unit Details', style: Theme.of(context).textTheme.titleLarge),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: unit.isOccupied ? Colors.teal.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  unit.isOccupied ? 'Occupied' : 'Vacant',
                  style: TextStyle(
                    color: unit.isOccupied ? Colors.teal.shade700 : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildInfoMetric(context, Icons.king_bed_outlined, 'Beds', unit.bedrooms.toString())),
              Expanded(child: _buildInfoMetric(context, Icons.bathtub_outlined, 'Baths', unit.bathrooms.toString())),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInfoMetric(context, Icons.square_foot_rounded, 'Area', '${unit.sqft} sqft')),
              Expanded(child: _buildInfoMetric(context, Icons.payments_outlined, 'Rent', currencyFormat.format(unit.monthlyRent))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMetric(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: ThemeProvider.primaryNavy.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: ThemeProvider.primaryNavy, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildTenantInfo(BuildContext context, DatabaseService databaseService) {
    if (unit.currentTenantId == null) return _buildAssignTenantSection(context, databaseService);

    return StreamBuilder<TenantModel?>(
      stream: databaseService.getTenant(unit.currentTenantId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data == null) return _buildAssignTenantSection(context, databaseService);
        return _buildCurrentTenantCard(context, snapshot.data!, databaseService);
      },
    );
  }

  Widget _buildAssignTenantSection(BuildContext context, DatabaseService databaseService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_off_outlined, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text('No Tenant Assigned', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orange.shade700)),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<TenantModel>>(
            stream: databaseService.getAvailableTenants(unit.ownerId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final availableTenants = snapshot.data!;
              if (availableTenants.isEmpty) {
                return const Text('No available tenants to assign. Please add a tenant first.', style: TextStyle(color: Colors.grey));
              }
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  filled: true,
                  fillColor: ThemeProvider.backgroundLight,
                ),
                hint: const Text('Select a Tenant...'),
                items: availableTenants.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                onChanged: (tenantId) {
                  if (tenantId != null) databaseService.assignTenantToUnit(unitId: unit.id, tenantId: tenantId, propertyId: unit.propertyId);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTenantCard(BuildContext context, TenantModel tenant, DatabaseService databaseService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Tenant', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: ThemeProvider.primaryNavy.withOpacity(0.05),
                backgroundImage: tenant.photoUrl != null && tenant.photoUrl!.isNotEmpty ? NetworkImage(tenant.photoUrl!) : null,
                child: (tenant.photoUrl == null || tenant.photoUrl!.isEmpty) ? Icon(Icons.person_outline, size: 30, color: ThemeProvider.primaryNavy.withOpacity(0.5)) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tenant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(tenant.phoneNumber ?? 'No phone', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('Unassign Tenant'),
              onPressed: () => databaseService.unassignTenantFromUnit(unitId: unit.id, tenantId: tenant.id, propertyId: unit.propertyId),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(DatabaseService databaseService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        StreamBuilder<List<TransactionModel>>(
          stream: databaseService.getTransactionsForUnit(unit.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final transactions = snapshot.data!;
            if (transactions.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ThemeProvider.primaryNavy.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('No transactions recorded yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isIncome = tx.type == TransactionType.income;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isIncome ? Colors.green : Colors.red, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(DateFormat.yMMMd().format(tx.date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            );
          },
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
          title: const Text('Delete Unit'),
          content: Text('Are you sure you want to delete Unit ${unit.unitNumber}? '
              'If there is an assigned tenant, they will be unassigned automatically.'),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await databaseService.deleteUnit(unit.id, unit.propertyId);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unit ${unit.unitNumber} deleted')));
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
          ],
        );
      },
    );
  }
}
