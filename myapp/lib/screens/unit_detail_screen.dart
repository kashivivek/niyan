import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:myapp/models/tenancy_history_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/utils/currency_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';

class UnitDetailScreen extends StatelessWidget {
  final UnitModel? unit;
  final String unitId;
  final String propertyId;

  const UnitDetailScreen({super.key, this.unit, required this.unitId, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);
    final user = Provider.of<UserModel?>(context);

    return StreamBuilder<UnitModel>(
      stream: databaseService.getUnitStream(unitId, propertyId),
      initialData: unit,
      builder: (context, unitSnapshot) {
        if (!unitSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final currentUnit = unitSnapshot.data!;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Unit ${currentUnit.unitNumber}'),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_outlined),
                onPressed: () => context.push('/property/${currentUnit.propertyId}/unit/${currentUnit.id}/edit', extra: currentUnit),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, databaseService, currentUnit),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildUnitInfoCard(context, currentUnit, user?.currency),
                const SizedBox(height: 24),
                _buildTenantInfo(context, currentUnit, databaseService),
                const SizedBox(height: 24),
                _buildTenancyHistory(context, currentUnit, databaseService),
                const SizedBox(height: 24),
                _buildRecentTransactions(currentUnit, databaseService, user?.currency),
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: Padding(
            padding: EdgeInsets.only(bottom: 80.0),
            child: FloatingActionButton.extended(
              icon: Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Add Transaction', style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold)),
              onPressed: () => context.push('/property/${currentUnit.propertyId}/unit/${currentUnit.id}/transaction/add', extra: currentUnit),
            ),
          ),
        );
      }
    );
  }

  Widget _buildUnitInfoCard(BuildContext context, UnitModel unit, String? currency) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatusBadge(unit.status),
              const Spacer(),
              _buildInfoItem(Icons.payments_outlined, 'Monthly Rent', CurrencyHelper.format(unit.monthlyRent, currency)),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              _buildInfoItem(Icons.calendar_today_rounded, 'Rent Due Date', 'Day ${unit.rentDueDate}'),
              const Spacer(),
              _buildStatusBadge(unit.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final isOccupied = status == 'occupied';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isOccupied ? Colors.green : Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: isOccupied ? Colors.green.shade700 : Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildTenantInfo(BuildContext context, UnitModel unit, DatabaseService databaseService) {
    final user = Provider.of<UserModel?>(context);
    if (unit.currentTenantId == null) return _buildAssignTenantSection(context, unit, databaseService, user?.currency);

    return StreamBuilder<TenantModel?>(
      stream: databaseService.getTenant(unit.currentTenantId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final tenant = snapshot.data!;

        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Tenant', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  Text(CurrencyHelper.format(unit.monthlyRent, user?.currency), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  TextButton(
                    onPressed: () => _confirmMoveOut(context, databaseService, unit, tenant),
                    child: const Text('Move Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => context.push('/tenant/${tenant.id}', extra: tenant),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: ThemeProvider.accentBlue.withOpacity(0.1),
                      backgroundImage: tenant.photoUrl != null ? NetworkImage(tenant.photoUrl!) : null,
                      child: tenant.photoUrl == null ? Icon(Icons.person_rounded, color: ThemeProvider.accentBlue) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tenant.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(tenant.phoneNumber ?? 'No phone', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignTenantSection(BuildContext context, UnitModel unit, DatabaseService databaseService, String? currency) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeProvider.accentBlue.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.person_add_alt_1_rounded, size: 48, color: ThemeProvider.accentBlue),
          const SizedBox(height: 16),
          const Text('No Tenant Assigned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Assign a tenant to start tracking rent and transactions.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          StreamBuilder<Map<String, dynamic>>(
            stream: CombineLatestStream.combine2(
              databaseService.getTenants(unit.ownerId),
              databaseService.allUnitsWithPropertyInfo(unit.ownerId),
              (List<TenantModel> tenants, List<Map<String, dynamic>> unitsInfo) => {
                'tenants': tenants,
                'unitsInfo': unitsInfo,
              },
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final tenants = snapshot.data?['tenants'] as List<TenantModel>? ?? [];
              final unitsInfo = snapshot.data?['unitsInfo'] as List<Map<String, dynamic>>? ?? [];

              // Map each tenant ID to their assigned locations
              final tenantAssignments = <String, List<String>>{};
              for (var info in unitsInfo) {
                final u = info['unit'] as UnitModel;
                final propName = info['propertyName'] as String;
                final tenantId = u.currentTenantId;
                if (tenantId != null && tenantId.isNotEmpty) {
                  tenantAssignments.putIfAbsent(tenantId, () => []).add('$propName - ${u.unitNumber}');
                }
              }

              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Assign Tenant',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Select a Tenant...'),
                items: [
                  const DropdownMenuItem<String>(
                    value: 'CREATE_NEW',
                    child: Text(
                      '+ Create New Tenant...',
                      style: TextStyle(color: ThemeProvider.accentBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...tenants.map((t) {
                    final locations = tenantAssignments[t.id];
                    final hasAssignment = locations != null && locations.isNotEmpty;

                    return DropdownMenuItem<String>(
                      value: t.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              t.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasAssignment) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                locations.join(', '),
                                style: TextStyle(color: Colors.teal.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (tenantId) {
                  if (tenantId == 'CREATE_NEW') {
                    context.push('/tenants/add?propertyId=${unit.propertyId}&unitId=${unit.id}');
                  } else if (tenantId != null) {
                    final selectedTenant = tenants.firstWhere((t) => t.id == tenantId);
                    _showAssignTenantDialog(
                      context,
                      unit,
                      selectedTenant,
                      databaseService,
                      currency,
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTenancyHistory(BuildContext context, UnitModel unit, DatabaseService databaseService) {
    return StreamBuilder<List<TenancyHistoryModel>>(
      stream: databaseService.getTenancyHistory(unit.propertyId, unit.id),
      builder: (context, snapshot) {
        final history = (snapshot.data ?? []).where((h) => h.endDate != null).toList();
        if (history.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Previous Tenants', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 12),
            ...history.map((h) => FutureBuilder<TenantModel?>(
              future: databaseService.getTenantFuture(h.tenantId),
              builder: (context, tSnap) {
                final tenantName = tSnap.data?.name ?? 'Loading...';
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.history_rounded, color: Colors.grey),
                    title: Text(tenantName),
                    subtitle: Text('${DateFormat('MMM yyyy').format(h.startDate)} - ${DateFormat('MMM yyyy').format(h.endDate!)}'),
                  ),
                );
              },
            )),
          ],
        );
      },
    );
  }

  Widget _buildRecentTransactions(UnitModel unit, DatabaseService databaseService, String? currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Transactions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        StreamBuilder<List<TransactionModel>>(
          stream: databaseService.getTransactionsForUnit(unit.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No transactions yet.', style: TextStyle(color: Colors.grey.shade400))));

            final txs = snapshot.data!.take(5).toList();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txs.length,
              itemBuilder: (context, index) {
                final tx = txs[index];
                final isIncome = tx.type == TransactionType.income;
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                  child: Row(
                    children: [
                      Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isIncome ? Colors.green : Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.description, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(DateFormat('MMM dd, yyyy').format(tx.date), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'}${CurrencyHelper.format(tx.amount, currency)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.redAccent),
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

  void _confirmMoveOut(BuildContext context, DatabaseService databaseService, UnitModel unit, TenantModel tenant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Move Out'),
        content: Text('Are you sure you want to mark ${tenant.name} as moved out from Unit ${unit.unitNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await databaseService.unassignTenantFromUnit(unitId: unit.id, tenantId: tenant.id, propertyId: unit.propertyId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Move Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DatabaseService databaseService, UnitModel unit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit'),
        content: const Text('Are you sure you want to delete this unit? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            await databaseService.deleteUnit(unit.id, unit.propertyId);
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showAssignTenantDialog(
    BuildContext context,
    UnitModel unit,
    TenantModel tenant,
    DatabaseService databaseService,
    String? currency,
  ) {
    final moveIn = tenant.moveInDate;
    final dueDay = unit.rentDueDate;
    
    // Calculate first due date after move-in date
    DateTime nextDue;
    if (moveIn.day < dueDay) {
      nextDue = DateTime(moveIn.year, moveIn.month, dueDay);
    } else {
      nextDue = DateTime(moveIn.year, moveIn.month + 1, dueDay);
    }
    
    final daysDiff = nextDue.difference(moveIn).inDays;
    final daysInMonth = DateTime(moveIn.year, moveIn.month + 1, 0).day;
    final dailyRate = unit.monthlyRent / daysInMonth;
    final calculatedProrated = dailyRate * daysDiff;

    showDialog(
      context: context,
      builder: (context) {
        bool applyProration = daysDiff > 0;
        final amountController = TextEditingController(
          text: calculatedProrated.toStringAsFixed(2),
        );
        DateTime proratedDueDate = nextDue;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Assign ${tenant.name}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unit Number: ${unit.unitNumber}', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Move-In Date: ${DateFormat('MMM dd, yyyy').format(moveIn)}'),
                    Text('Monthly Rent: ${CurrencyHelper.format(unit.monthlyRent, currency)}'),
                    Text('Rent Due Day: Day $dueDay of the month'),
                    const Divider(height: 24),
                    if (daysDiff > 0) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: applyProration,
                            onChanged: (val) {
                              setState(() {
                                applyProration = val ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Charge prorated rent for partial first month',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      if (applyProration) ...[
                        const SizedBox(height: 8),
                        Text('Prorated Period: ${DateFormat('MMM dd').format(moveIn)} to ${DateFormat('MMM dd').format(nextDue)} ($daysDiff days)'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: amountController,
                          decoration: InputDecoration(
                            labelText: 'Prorated Amount (${currency ?? '\$'})',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Prorated Due Date', style: TextStyle(fontSize: 14)),
                          subtitle: Text(DateFormat('MMM dd, yyyy').format(proratedDueDate)),
                          trailing: Icon(Icons.calendar_today, size: 18),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: proratedDueDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              setState(() {
                                proratedDueDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'Move-in date is on the rent due day. No proration needed; full monthly rent will start immediately.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeProvider.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final proratedAmt = applyProration
                        ? double.tryParse(amountController.text)
                        : null;
                    
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      await databaseService.assignTenantToUnit(
                        unitId: unit.id,
                        tenantId: tenant.id,
                        propertyId: unit.propertyId,
                        ownerId: unit.ownerId,
                        proratedAmount: proratedAmt,
                        proratedDueDate: applyProration ? proratedDueDate : null,
                      );
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Tenant assigned successfully!')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Assignment failed: $e')),
                      );
                    }
                  },
                  child: const Text('Assign & Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
