import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/screens/add_property_screen.dart';
import 'package:myapp/screens/property_list_screen.dart';
import 'package:myapp/screens/all_transactions_screen.dart';
import 'package:myapp/utils/currency_helper.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:myapp/models/action_item_model.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/rent_record_model.dart';
import 'package:myapp/models/rent_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

Map<String, dynamic> _calculateSummary(Map<String, dynamic> data) {
  final properties = data['properties'] as List<PropertyModel>;
  final units = data['units'] as List<UnitModel>;
  final records = data['records'] as List<RentRecordModel>;

  final occupiedUnits = units.where((unit) => unit.isOccupied).toList();
  
  final pendingTotal = records
      .where((r) => r.status != RentStatus.paid)
      .fold<double>(0, (sum, r) => sum + r.amount);

  final collectedTotal = records
      .where((r) => r.status == RentStatus.paid)
      .fold<double>(0, (sum, r) => sum + r.amount);

  return {
    'propertiesCount': properties.length,
    'unitsCount': units.length,
    'occupiedUnits': occupiedUnits.length,
    'pendingTotal': pendingTotal,
    'collectedTotal': collectedTotal,
  };
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _upcomingRentsKey = GlobalKey();

  void _scrollToUpcomingRents() {
    final context = _upcomingRentsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

          // Sync rent records when viewing dashboard
          databaseService.ensureRentRecordsExist(user.uid);

          return CustomScrollView(
            controller: _scrollController,
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
                          _buildSummaryCards(databaseService, user),
                          const SizedBox(height: 32),
                          Text(
                            'Upcoming Rents (7 days)',
                            key: _upcomingRentsKey,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ThemeProvider.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ActionCenterList(databaseService: databaseService, user: user),
                          const SizedBox(height: 100),
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
    return SliverAppBar(
      expandedHeight: 110.0,
      backgroundColor: Colors.white,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: false,
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
                'Welcome,',
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

  Widget _buildSummaryCards(DatabaseService databaseService, UserModel user) {
    final summaryStream = CombineLatestStream.combine3(
      databaseService.getProperties(user.uid).onErrorReturn(<PropertyModel>[]),
      databaseService.allUnits(user.uid).onErrorReturn(<UnitModel>[]),
      FirebaseFirestore.instance.collection('rent_records').where('ownerId', isEqualTo: user.uid).snapshots().map((s) => s.docs.map((d) => RentRecordModel.fromFirestore(d)).toList()),
      (List<PropertyModel> p, List<UnitModel> u, List<RentRecordModel> r) => {'properties': p, 'units': u, 'records': r},
    ).debounceTime(const Duration(milliseconds: 300));

    return StreamBuilder<Map<String, dynamic>>(
      stream: summaryStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: compute(_calculateSummary, snapshot.data!),
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
                _buildKpiCard(
                  context, 
                  'Properties', 
                  '${data['propertiesCount']}', 
                  Icons.apartment_rounded, 
                  ThemeProvider.accentBlue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PropertyListScreen())),
                ),
                _buildKpiCard(context, 'Occupancy', '${data['occupiedUnits']}/${data['unitsCount']}', Icons.door_front_door_rounded, Colors.teal),
                _buildKpiCard(
                  context, 
                  'Pending Rents', 
                  CurrencyHelper.formatNoDecimal(data['pendingTotal'] as double, user.currency), 
                  Icons.pending_actions_rounded, 
                  Colors.red.shade600,
                  onTap: _scrollToUpcomingRents,
                ),
                _buildKpiCard(
                  context, 
                  'Collected', 
                  CurrencyHelper.formatNoDecimal(data['collectedTotal'] as double, user.currency), 
                  Icons.account_balance_wallet_rounded, 
                  Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllTransactionsScreen())),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value, IconData icon, Color accent, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            if (onTap != null) BoxShadow(color: accent.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: accent, size: 24),
                ),
                if (onTap != null) Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade400),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: ThemeProvider.primaryNavy))),
                Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCenterList extends StatefulWidget {
  final DatabaseService databaseService;
  final UserModel user;

  const _ActionCenterList({required this.databaseService, required this.user});

  @override
  State<_ActionCenterList> createState() => _ActionCenterListState();
}

class _ActionCenterListState extends State<_ActionCenterList> {
  final Set<String> _selectedKeys = {};
  bool _isProcessing = false;

  String _itemKey(ActionItem item) => item.rentRecordId ?? '${item.tenant.id}_${item.month}';

  Future<void> _recordPayment(ActionItem item) async {
    await widget.databaseService.recordRentPayment(
      item: item,
      ownerId: widget.user.uid,
    );
  }

  Future<void> _recordSelectedPayments(List<ActionItem> allItems) async {
    if (_selectedKeys.isEmpty) return;
    setState(() => _isProcessing = true);
    final selected = allItems.where((item) => _selectedKeys.contains(_itemKey(item))).toList();
    int success = 0;
    for (final item in selected) {
      try {
        await _recordPayment(item);
        success++;
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _selectedKeys.clear();
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$success payment(s) recorded successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActionItem>>(
      stream: widget.databaseService.getActionItems(widget.user.uid).debounceTime(const Duration(milliseconds: 300)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final actionItems = snapshot.data!;

        if (!kIsWeb && widget.user.notificationsEnabled) {
          NotificationService().scheduleRentReminders(actionItems, widget.user.notificationTime, widget.user.notificationFrequency);
        } else if (!kIsWeb) {
          NotificationService().cancelAllNotifications();
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
                Text('All caught up!', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
                Text('No upcoming rent payments.', style: GoogleFonts.inter(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (_selectedKeys.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_selectedKeys.length} selected', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _recordSelectedPayments(actionItems),
                      icon: _isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded),
                      label: const Text('Mark Received'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actionItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = actionItems[index];
                final isSelected = _selectedKeys.contains(_itemKey(item));

                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? ThemeProvider.accentBlue : Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedKeys.remove(_itemKey(item));
                        } else {
                          _selectedKeys.add(_itemKey(item));
                        }
                      });
                    },
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedKeys.add(_itemKey(item));
                          } else {
                            _selectedKeys.remove(_itemKey(item));
                          }
                        });
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    title: Text(item.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (item.isOverdue ? Colors.red : Colors.orange).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.month,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.isOverdue ? Colors.red : Colors.orange),
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyHelper.formatNoDecimal(item.amount, widget.user.currency),
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: ThemeProvider.primaryNavy),
                        ),
                        Text('Rent', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
