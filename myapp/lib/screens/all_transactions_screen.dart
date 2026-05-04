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

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final Set<String> _selectedPropertyIds = {};
  final Set<String> _selectedUnitIds = {};
  final Set<TransactionType> _selectedTypes = {};
  final ScrollController _monthScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_monthScrollController.hasClients) {
        // Scroll to the end (current month is the last in the reversed list)
        _monthScrollController.jumpTo(_monthScrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final user = Provider.of<UserModel?>(context);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final stream = CombineLatestStream.combine4(
      databaseService.allTransactions(user.uid),
      databaseService.getProperties(user.uid),
      databaseService.allUnits(user.uid),
      databaseService.getTenants(user.uid),
      (List<TransactionModel> txs, List<PropertyModel> props, List<UnitModel> units, List<TenantModel> tenants) {
        final propMap = {for (var p in props) p.id: p};
        final unitMap = {for (var u in units) u.id: u};
        final tenantMap = {for (var t in tenants) t.id: t};

        // Filter by month
        var filteredTxs = txs.where((tx) => tx.date.year == _selectedMonth.year && tx.date.month == _selectedMonth.month);

        // Filter by property
        if (_selectedPropertyIds.isNotEmpty) {
          filteredTxs = filteredTxs.where((tx) => _selectedPropertyIds.contains(tx.propertyId));
        }

        // Filter by unit
        if (_selectedUnitIds.isNotEmpty) {
          filteredTxs = filteredTxs.where((tx) => _selectedUnitIds.contains(tx.unitId));
        }

        // Filter by type
        if (_selectedTypes.isNotEmpty) {
          filteredTxs = filteredTxs.where((tx) => _selectedTypes.contains(tx.type));
        }

        return filteredTxs.map((tx) => _TransactionDetail(tx, propMap[tx.propertyId], unitMap[tx.unitId], tenantMap[tx.tenantId])).toList();
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
      body: Column(
        children: [
          _buildMonthPagination(),
          _buildFilters(databaseService, user.uid),
          Expanded(
            child: StreamBuilder<List<_TransactionDetail>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();

                final details = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: details.length,
                  itemBuilder: (context, index) => _buildTransactionCard(details[index], user.currency),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPagination() {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      return DateTime(now.year, now.month - i);
    }).reversed.toList();

    return Container(
      height: 80,
      color: Colors.white,
      child: ListView.builder(
        controller: _monthScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: months.length,

        itemBuilder: (context, index) {
          final month = months[index];
          final isSelected = month.year == _selectedMonth.year && month.month == _selectedMonth.month;
          return GestureDetector(
            onTap: () => setState(() => _selectedMonth = month),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? ThemeProvider.accentBlue : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isSelected ? ThemeProvider.accentBlue : Colors.grey.shade200),
              ),
              alignment: Alignment.center,
              child: Text(
                DateFormat('MMM yy').format(month),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters(DatabaseService db, String ownerId) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              _buildMultiSelectFilter(
                label: 'Properties',
                selectedCount: _selectedPropertyIds.length,
                onTap: () => _showMultiSelectDialog(
                  title: 'Select Properties',
                  stream: db.getProperties(ownerId),
                  selectedIds: _selectedPropertyIds,
                  idMapper: (PropertyModel p) => p.id,
                  labelMapper: (PropertyModel p) => p.name,
                  onChanged: (ids) => setState(() {
                    _selectedPropertyIds.clear();
                    _selectedPropertyIds.addAll(ids);
                    _selectedUnitIds.clear(); // Reset units when properties change
                  }),
                ),
              ),
              const SizedBox(width: 8),
              _buildMultiSelectFilter(
                label: 'Units',
                selectedCount: _selectedUnitIds.length,
                onTap: () => _showMultiSelectDialog(
                  title: 'Select Units',
                  stream: _selectedPropertyIds.length == 1 
                      ? db.getUnits(_selectedPropertyIds.first)
                      : db.allUnits(ownerId).map((units) => _selectedPropertyIds.isEmpty 
                          ? units 
                          : units.where((u) => _selectedPropertyIds.contains(u.propertyId)).toList()),
                  selectedIds: _selectedUnitIds,
                  idMapper: (UnitModel u) => u.id,
                  labelMapper: (UnitModel u) => 'Unit ${u.unitNumber}',
                  onChanged: (ids) => setState(() {
                    _selectedUnitIds.clear();
                    _selectedUnitIds.addAll(ids);
                  }),
                ),
              ),
              const SizedBox(width: 8),
              _buildMultiSelectFilter(
                label: 'Types',
                selectedCount: _selectedTypes.length,
                onTap: () => _showTypeSelectDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectFilter({required String label, required int selectedCount, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: selectedCount > 0 ? ThemeProvider.accentBlue.withOpacity(0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selectedCount > 0 ? ThemeProvider.accentBlue : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  selectedCount > 0 ? '$label ($selectedCount)' : label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selectedCount > 0 ? FontWeight.bold : FontWeight.normal,
                    color: selectedCount > 0 ? ThemeProvider.accentBlue : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: selectedCount > 0 ? ThemeProvider.accentBlue : Colors.grey),
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
              title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        final label = labelMapper(item);
                        return CheckboxListTile(
                          value: tempSelected.contains(id),
                          title: Text(label),
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

  void _showTypeSelectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Set<TransactionType> tempSelected = Set.from(_selectedTypes);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Types'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: TransactionType.values.map((type) {
                  return CheckboxListTile(
                    value: tempSelected.contains(type),
                    title: Text(type == TransactionType.income ? 'Income' : 'Expense'),
                    onChanged: (val) {
                      setDialogState(() {
                        if (val == true) tempSelected.add(type);
                        else tempSelected.remove(type);
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTypes.clear();
                      _selectedTypes.addAll(tempSelected);
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

  Widget _buildTransactionCard(_TransactionDetail detail, String? currency) {
    final isIncome = detail.tx.type == TransactionType.income;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isIncome ? Colors.green : Colors.red, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${detail.property?.name ?? ''} • Unit ${detail.unit?.unitNumber ?? ''}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${isIncome ? '+' : '-'}${CurrencyHelper.format(detail.tx.amount, currency)}', style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red, fontSize: 16)),
              Text(DateFormat('MMM dd').format(detail.tx.date), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade200), const SizedBox(height: 16), const Text('No records for this selection')]));
  }
}

class _TransactionDetail {
  final TransactionModel tx;
  final PropertyModel? property;
  final UnitModel? unit;
  final TenantModel? tenant;
  _TransactionDetail(this.tx, this.property, this.unit, this.tenant);
}
