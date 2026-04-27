import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/utils/currency_helper.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Join transactions with property, unit, and tenant details
    final stream = CombineLatestStream.combine4(
      databaseService.allTransactions(user.uid),
      databaseService.getProperties(user.uid),
      databaseService.allUnits(user.uid),
      databaseService.getTenants(user.uid),
      (List<TransactionModel> txs, List<PropertyModel> props, List<UnitModel> units, List<TenantModel> tenants) {
        final propMap = {for (var p in props) p.id: p};
        final unitMap = {for (var u in units) u.id: u};
        final tenantMap = {for (var t in tenants) t.id: t};
        return txs.map((tx) => _TransactionDetail(tx, propMap[tx.propertyId], unitMap[tx.unitId], tenantMap[tx.tenantId])).toList();
      },
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Financial Records', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<_TransactionDetail>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No records found', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          final details = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: details.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = details[index];
              final tx = d.transaction;
              final isIncome = tx.type == TransactionType.income;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isIncome ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.description, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.business_rounded, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  d.property?.name ?? 'Unknown Property', 
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.door_front_door_rounded, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text('Unit ${d.unit?.unitNumber ?? 'N/A'}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                          if (d.tenant != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.person_rounded, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(d.tenant!.name, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(DateFormat('d MMM yyyy').format(tx.date), style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isIncome ? '+' : '-'}${CurrencyHelper.formatNoDecimal(tx.amount, user.currency)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green : Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TransactionDetail {
  final TransactionModel transaction;
  final PropertyModel? property;
  final UnitModel? unit;
  final TenantModel? tenant;

  _TransactionDetail(this.transaction, this.property, this.unit, this.tenant);
}
