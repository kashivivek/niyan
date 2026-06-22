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
import 'package:go_router/go_router.dart';
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
import 'dart:async';
import 'package:home_widget/home_widget.dart';
import 'package:myapp/models/notification_model.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';

Map<String, dynamic> _calculateSummary(Map<String, dynamic> data) {
  final properties = data['properties'] as List<PropertyModel>;
  final units = data['units'] as List<UnitModel>;
  final records = data['records'] as List<RentRecordModel>;

  final occupiedUnits = units.where((unit) => unit.isOccupied).length;
  
  final pendingTotal = records
      .where((r) => r.status != RentStatus.paid)
      .fold<double>(0, (sum, r) => sum + r.amount);

  final collectedTotal = records
      .where((r) => r.status == RentStatus.paid)
      .fold<double>(0, (sum, r) => sum + r.amount);

  return {
    'propertiesCount': properties.length,
    'unitsCount': units.length,
    'occupiedUnits': occupiedUnits,
    'pendingTotal': pendingTotal,
    'collectedTotal': collectedTotal,
  };
}

class StandaloneDashboardScreen extends StatefulWidget {
  const StandaloneDashboardScreen({super.key});

  @override
  State<StandaloneDashboardScreen> createState() => _StandaloneDashboardScreenState();
}

class _StandaloneDashboardScreenState extends State<StandaloneDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _upcomingRentsKey = GlobalKey();
  StreamSubscription? _notificationSubscription;
  List<ActionItem>? _lastActionItems;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().requestPermissions();
      _setupNotificationListener();
      _triggerRentIncreaseCheck();
    });
  }

  Future<void> _triggerRentIncreaseCheck() async {
    try {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user != null) {
        final db = Provider.of<DatabaseService>(context, listen: false);
        await db.ensureRentRecordsExist(user.uid);
      }
    } catch (e) {
      // Silently fail — not critical path
    }
  }

  Future<void> _updateHomeWidget(List<ActionItem> items) async {
    final user = Provider.of<UserModel?>(context, listen: false);
    final currency = user?.currency ?? 'USD';

    final overdueItems = items.where((i) => i.isOverdue).toList();
    final upcomingItems = items.where((i) => !i.isOverdue).toList();

    final overdueCount = overdueItems.length;
    final upcomingCount = upcomingItems.length;

    // Build details lines: "Property · Unit  Tenant – Amount"
    String buildDetails(List<ActionItem> list) {
      if (list.isEmpty) return '';
      return list.take(3).map((i) {
        final prop = i.propertyName.isNotEmpty ? i.propertyName : '—';
        final unit = i.unitNumber.isNotEmpty ? i.unitNumber : '—';
        final tenant = i.tenant.name.isNotEmpty ? i.tenant.name : '—';
        final amount = CurrencyHelper.formatNoDecimal(i.amount, currency);
        return '$prop · $unit  $tenant – $amount';
      }).join('\n');
    }

    final overdueDetails = overdueCount > 0 ? buildDetails(overdueItems) : 'No overdue rents';
    final upcomingDetails = upcomingCount > 0 ? buildDetails(upcomingItems) : 'No upcoming rents';

    await HomeWidget.saveWidgetData<String>('overdue_count', overdueCount.toString());
    await HomeWidget.saveWidgetData<String>('upcoming_count', upcomingCount.toString());
    await HomeWidget.saveWidgetData<String>('overdue_details', overdueDetails);
    await HomeWidget.saveWidgetData<String>('upcoming_details', upcomingDetails);
    await HomeWidget.saveWidgetData<String>('last_updated', 'Updated ${DateFormat('HH:mm').format(DateTime.now())}');
    
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.kashivivek.niyan.NiyanWidgetProvider',
      iOSName: 'NiyanWidget',
    );
  }

  void _setupNotificationListener() {
    final db = context.read<DatabaseService>();
    final auth = context.read<AuthService>();
    
    _notificationSubscription = auth.user.switchMap((user) {
      if (user == null || !user.notificationsEnabled || kIsWeb) {
        if (!kIsWeb) NotificationService().cancelAllNotifications();
        return Stream.value(<ActionItem>[]);
      }
      return db.getActionItems(user.uid).debounceTime(const Duration(seconds: 2));
    }).listen((items) {
      final user = Provider.of<UserModel?>(context, listen: false);
      
      // Update Home Widget in background
      if (!kIsWeb) _updateHomeWidget(items);

      if (user != null && user.notificationsEnabled && !kIsWeb) {
        if (_lastActionItems == null || _lastActionItems!.length != items.length) {
          developer.log('Rescheduling notifications for ${items.length} items');
          NotificationService().scheduleRentReminders(items, user.notificationTime, user.notificationTimezone, user.notificationFrequency, ownerId: user.uid);
          _lastActionItems = items;
        }
      }
    });
  }

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
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userStream = authService.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: ResponsiveCentered(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.societyIds.isNotEmpty)
                          _buildContextSwitcherBanner(context),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)?.welcomeUser((user.name?.split(' ') ?? ['Vivek']).first) ?? 'Welcome, ${(user.name?.split(' ') ?? ['Vivek']).first}!',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            _buildNotificationBell(context, databaseService, user.uid),
                          ],
                        ),
                        Text(
                          AppLocalizations.of(context)?.portfolioSubtitle ?? 'Here is what is happening with your portfolio today.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryCards(databaseService, user),
                        const SizedBox(height: 32),
                        Text(
                          AppLocalizations.of(context)?.upcomingRents7Days ?? 'Upcoming Rents (7 days)',
                          key: _upcomingRentsKey,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ActionCenterList(databaseService: databaseService, user: user),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }



  Widget _buildNotificationBell(BuildContext context, DatabaseService databaseService, String userId) {
    return StreamBuilder<List<NotificationModel>>(
      stream: databaseService.getNotifications(userId),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!.where((n) => !n.isRead).length;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.primary, size: 28),
              onPressed: () => context.push('/notifications'),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: GoogleFonts.inter(
                      color: Theme.of(context).cardColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContextSwitcherBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [ThemeProvider.accentBlue, ThemeProvider.accentBlue.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: ThemeProvider.accentBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Society Mode Available', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Switch to manage your society', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => context.push('/select-society'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ThemeProvider.accentBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('SWITCH', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(DatabaseService databaseService, UserModel user) {
    final firestore = Provider.of<FirebaseFirestore>(context, listen: false);
    final summaryStream = CombineLatestStream.combine3(
      databaseService.getProperties(user.uid).onErrorReturn(<PropertyModel>[]),
      databaseService.allUnits(user.uid).onErrorReturn(<UnitModel>[]),
      firestore.collection('rentRecords').where('ownerId', isEqualTo: user.uid).snapshots().map((s) => s.docs.map((d) => RentRecordModel.fromFirestore(d)).toList()),
      (List<PropertyModel> p, List<UnitModel> u, List<RentRecordModel> r) => {'properties': p, 'units': u, 'records': r},
    ).debounceTime(const Duration(milliseconds: 300));

    return StreamBuilder<Map<String, dynamic>>(
      stream: summaryStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }

        final data = _calculateSummary(snapshot.data!);

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
              AppLocalizations.of(context)?.properties ?? 'Properties', 
              '${data['propertiesCount']}', 
              Icons.apartment_rounded, 
              ThemeProvider.accentBlue,
              onTap: () => context.push('/properties'),
            ),
            _buildKpiCard(context, AppLocalizations.of(context)?.occupancy ?? 'Occupancy', '${data['occupiedUnits']}/${data['unitsCount']}', Icons.door_front_door_rounded, Colors.teal),
            _buildKpiCard(
              context, 
              AppLocalizations.of(context)?.pendingRents ?? 'Pending Rents', 
              CurrencyHelper.formatNoDecimal(data['pendingTotal'] as double, user.currency), 
              Icons.pending_actions_rounded, 
              Colors.red.shade600,
              onTap: _scrollToUpcomingRents,
            ),
            _buildKpiCard(
              context, 
              AppLocalizations.of(context)?.collected ?? 'Collected', 
              CurrencyHelper.formatNoDecimal(data['collectedTotal'] as double, user.currency), 
              Icons.account_balance_wallet_rounded, 
              Colors.purple,
              onTap: () => context.push('/transactions'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value, IconData icon, Color accent, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200),
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
                Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
                Text(title, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w500)),
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

  Future<void> _recordSelectedPayments(List<ActionItem> allItems) async {
    if (_selectedKeys.isEmpty) return;
    
    final selected = allItems.where((item) => _selectedKeys.contains(_itemKey(item))).toList();
    final Map<String, DateTime> selectedDates = {
      for (var item in selected) _itemKey(item): DateTime.now()
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text('Mark as Received', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select date received for each payment:', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: selected.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = selected[index];
                          final key = _itemKey(item);
                          final propUnit = item.propertyName.isNotEmpty && item.unitNumber.isNotEmpty ? '${item.propertyName} - ${item.unitNumber}' : '—';
                          
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.tenant.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                      Text(propUnit, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDates[key]!,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setDialogState(() => selectedDates[key] = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(DateFormat('MMM d').format(selectedDates[key]!), style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 4),
                                        Icon(Icons.calendar_today_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          }
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    int success = 0;
    for (final item in selected) {
      try {
        final paymentDate = selectedDates[_itemKey(item)] ?? DateTime.now();
        if (item.rentRecordId != null) {
          await widget.databaseService.recordRentPayment(item: item, ownerId: widget.user.uid, paymentDate: paymentDate);
        } else {
          await widget.databaseService.recordTransaction(
            propertyId: item.propertyId,
            unitId: item.unitId,
            tenantId: item.tenant.id,
            amount: item.amount,
            description: 'Rent for ${item.month}',
            type: 'income',
            month: item.month,
            date: paymentDate,
          );
        }
        success++;
      } catch (e) {
        developer.log('Error recording payment', error: e);
      }
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

        if (actionItems.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade400, size: 64),
                const SizedBox(height: 16),
                Text('All caught up!', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
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
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.05) 
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? ThemeProvider.accentBlue 
                          : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200)
                    ),
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
                    title: Text(item.tenant.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
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
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
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

class ResponsiveCentered extends StatelessWidget {
  final Widget child;
  const ResponsiveCentered({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: child,
      ),
    );
  }
}
