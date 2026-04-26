import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/rent_record_model.dart';
import 'package:myapp/models/rent_status.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/action_item_model.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/screens/add_property_screen.dart';
import 'package:myapp/screens/tenant_detail_screen.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:myapp/providers/theme_provider.dart';

Future<Map<String, dynamic>> _calculateSummary(Map<String, dynamic> data) async {
  final properties = data['properties'] as List<PropertyModel>? ?? [];
  final units = data['units'] as List<UnitModel>? ?? [];
  final transactions = data['transactions'] as List<TransactionModel>? ?? [];

  final occupiedUnits = units.where((unit) => unit.isOccupied).toList();
  final occupiedUnitsCount = occupiedUnits.length;
  final totalExpectedRent = occupiedUnits.fold<double>(0, (sum, unit) => sum + unit.monthlyRent);

  final now = DateTime.now();
  final paidRent = transactions
      .where((tx) => tx.type == TransactionType.income && tx.date.year == now.year && tx.date.month == now.month)
      .fold<double>(0, (sum, tx) => sum + tx.amount);

  return {
    'propertiesCount': properties.length,
    'unitsCount': units.length,
    'occupiedUnits': occupiedUnitsCount,
    'totalRent': totalExpectedRent,
    'paidRent': paidRent,
  };
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userStream = authService.user;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: StreamBuilder<UserModel?>(
        stream: userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('User not found.'));
          }

          final user = snapshot.data!;
          final databaseService = Provider.of<DatabaseService>(context, listen: false);
          final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

          return CustomScrollView(
            slivers: [
              _buildModernHeroHeader(context, user, authService),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            'Portfolio Overview',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ThemeProvider.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryCards(databaseService, user.uid, currentMonth),
                          const SizedBox(height: 32),
                          Text(
                            'Action Center',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ThemeProvider.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildUnpaidTenantsList(databaseService, user.uid),
                          const SizedBox(height: 100), // spacing for bottom nav
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ThemeProvider.accentBlue,
        elevation: 2,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPropertyScreen()));
        },
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('Add Property', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildModernHeroHeader(BuildContext context, UserModel user, AuthService authService) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return SliverAppBar(
      expandedHeight: 110.0,
      backgroundColor: Colors.white,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: false,
      leading: !isDesktop
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset('assets/images/logo_icon.png', fit: BoxFit.contain),
            )
          : null,
      title: Image.asset('assets/images/logo_full.png', height: 28),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Icon(Icons.logout_rounded, color: Colors.grey.shade600),
            tooltip: 'Log out',
            onPressed: () async => await authService.signOut(),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          padding: const EdgeInsets.only(left: 24.0, bottom: 20.0, right: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                user.name ?? user.email?.split('@').first ?? 'Manager',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  color: ThemeProvider.primaryNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DatabaseService databaseService, String ownerId, String currentMonth) {
    final summaryStream = CombineLatestStream.combine3(
      databaseService.getProperties(ownerId).onErrorReturn(<PropertyModel>[]),
      databaseService.allUnits(ownerId).onErrorReturn(<UnitModel>[]),
      databaseService.allTransactions(ownerId).onErrorReturn(<TransactionModel>[]),
      (List<PropertyModel> p, List<UnitModel> u, List<TransactionModel> t) => {'properties': p, 'units': u, 'transactions': t},
    ).debounceTime(const Duration(milliseconds: 300));

    return StreamBuilder<Map<String, dynamic>>(
      stream: summaryStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: compute(_calculateSummary, snapshot.data ?? {}),
          builder: (context, futureSnapshot) {
             if (!futureSnapshot.hasData) return const SizedBox.shrink();
             final data = futureSnapshot.data!;

             return GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: MediaQuery.of(context).size.width > 800 ? 1.4 : 1.2,
              children: [
                _buildKpiCard(context, 'Properties', '${data['propertiesCount']}', Icons.apartment_rounded, ThemeProvider.accentBlue),
                _buildKpiCard(context, 'Occupancy', '${data['occupiedUnits']}/${data['unitsCount']}', Icons.door_front_door_rounded, Colors.teal),
                _buildKpiCard(context, 'Expected', '\$${(data['totalRent'] as double).toStringAsFixed(0)}', Icons.payments_outlined, Colors.orange),
                _buildKpiCard(context, 'Collected', '\$${(data['paidRent'] as double).toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, Colors.purple),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value, IconData icon, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title, 
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600, 
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Icon(icon, color: accent.withOpacity(0.5), size: 24),
            ],
          ),
          Text(
            value, 
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold, 
              color: ThemeProvider.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpaidTenantsList(DatabaseService databaseService, String ownerId) {
    return StreamBuilder<List<ActionItem>>(
      stream: databaseService.getActionItems(ownerId).debounceTime(const Duration(milliseconds: 300)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final actionItems = snapshot.data!;
        
        final user = Provider.of<UserModel?>(context, listen: false);
        if (!kIsWeb && user != null) {
          if (user.notificationsEnabled) {
            NotificationService().scheduleRentReminders(actionItems, user.notificationTime, user.notificationFrequency);
          } else {
            NotificationService().cancelAllNotifications();
          }
        }
        
        if (actionItems.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade400, size: 64),
                const SizedBox(height: 16),
                Text('You are all caught up!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: ThemeProvider.primaryNavy)),
                const SizedBox(height: 8),
                Text('No upcoming dues or overdue rent at this time.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }

        return Column(
          children: actionItems.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.isOverdue ? Colors.red.withOpacity(0.08) : Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.isOverdue ? Icons.warning_rounded : Icons.calendar_today_rounded, 
                    color: item.isOverdue ? Colors.redAccent : Colors.orange,
                  ),
                ),
                title: Text(item.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(item.subtitle, style: TextStyle(color: Colors.grey.shade600)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('\$${item.amount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: ThemeProvider.primaryNavy)),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeProvider.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        try {
                          await databaseService.recordRentPayment(
                            tenantId: item.tenant.id,
                            propertyId: item.tenant.propertyId,
                            unitId: item.tenant.assignedUnitId,
                            amount: item.amount,
                            month: item.month,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded successfully!')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to record payment.')));
                          }
                        }
                      },
                      child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TenantDetailScreen(tenant: item.tenant))),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
