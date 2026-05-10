import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/invoice_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/billing_service.dart';
import 'package:myapp/utils/currency_helper.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _statusTabs = [null, InvoiceStatus.sent, InvoiceStatus.paid, InvoiceStatus.overdue];
  final _tabLabels = ['All', 'Sent', 'Paid', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);
    final billingService = Provider.of<BillingService>(context, listen: false);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final stream = billingService.getInvoices(
      ownerId: appMode.isStandaloneMode ? user.uid : null,
      societyId: appMode.activeSociety?.id,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Invoices',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 20)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w400, fontSize: 13),
          labelColor: ThemeProvider.accentBlue,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: ThemeProvider.accentBlue,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
        actions: [
          if (user.currentRole == AppRole.superAdmin || user.currentRole == AppRole.societyAdmin || user.currentRole == AppRole.treasurer)
            IconButton(
              icon: const Icon(Icons.gavel_rounded),
              tooltip: 'Apply Late Fees',
              onPressed: () async {
                if (appMode.activeSociety == null) return;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Apply Late Fees?'),
                    content: const Text('This will automatically append a ₹500 late fee to all overdue invoices that do not already have one.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('CANCEL')),
                      ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('APPLY')),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    final count = await billingService.applyLateFeesToOverdueInvoices(appMode.activeSociety!.id, appMode.activeSociety!.settings);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Applied late fees to $count invoices.')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/invoices/create'),
        backgroundColor: ThemeProvider.accentBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('New Invoice',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<InvoiceModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allInvoices = snapshot.data ?? [];
          return TabBarView(
            controller: _tabController,
            children: _statusTabs.map((statusFilter) {
              final invoices = statusFilter == null
                  ? allInvoices
                  : allInvoices.where((inv) {
                      if (statusFilter == InvoiceStatus.overdue) return inv.isOverdue;
                      return inv.status == statusFilter;
                    }).toList();
              return _buildInvoiceList(invoices, user.currency);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceList(List<InvoiceModel> invoices, String currency) {
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No invoices here',
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    // Group by month
    final grouped = <String, List<InvoiceModel>>{};
    for (final inv in invoices) {
      grouped.putIfAbsent(inv.billingMonth, () => []).add(inv);
    }
    final months = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: months.length,
      itemBuilder: (context, idx) {
        final month = months[idx];
        final items = grouped[month]!;
        final totalDue = items
            .where((i) => i.status != InvoiceStatus.paid && i.status != InvoiceStatus.cancelled)
            .fold(0.0, (sum, i) => sum + i.grandTotal);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(
                    _formatMonth(month),
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: ThemeProvider.primaryNavy),
                  ),
                  const Spacer(),
                  if (totalDue > 0)
                    Text(
                      '${CurrencyHelper.format(totalDue, currency)} due',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
            ...items.map((inv) => _InvoiceCard(invoice: inv, currency: currency)),
          ],
        );
      },
    );
  }

  String _formatMonth(String month) {
    try {
      final date = DateFormat('yyyy-MM').parse(month);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return month;
    }
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final String currency;

  const _InvoiceCard({required this.invoice, required this.currency});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(invoice);
    final statusLabel = _statusLabel(invoice);

    return GestureDetector(
      onTap: () => context.push('/invoices/${invoice.id}', extra: invoice),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.residentName,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: ThemeProvider.primaryNavy),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${invoice.propertyName} · Unit ${invoice.unitNumber}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: 'Due ${DateFormat('d MMM').format(invoice.dueDate)}'),
                const SizedBox(width: 12),
                _InfoChip(
                    icon: Icons.receipt_outlined,
                    label: '${invoice.lineItems.length} item${invoice.lineItems.length != 1 ? 's' : ''}'),
                const Spacer(),
                Text(
                  CurrencyHelper.format(invoice.grandTotal, currency),
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: ThemeProvider.primaryNavy),
                ),
              ],
            ),
            if (invoice.totalGst > 0) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'incl. GST ${CurrencyHelper.format(invoice.totalGst, currency)}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(InvoiceModel inv) {
    if (inv.isOverdue) return Colors.red.shade600;
    switch (inv.status) {
      case InvoiceStatus.paid:      return Colors.green.shade600;
      case InvoiceStatus.sent:      return ThemeProvider.accentBlue;
      case InvoiceStatus.cancelled: return Colors.grey;
      default:                      return Colors.orange.shade600;
    }
  }

  String _statusLabel(InvoiceModel inv) {
    if (inv.isOverdue && inv.status != InvoiceStatus.paid) return 'Overdue';
    switch (inv.status) {
      case InvoiceStatus.paid:      return 'Paid';
      case InvoiceStatus.sent:      return 'Sent';
      case InvoiceStatus.draft:     return 'Draft';
      case InvoiceStatus.cancelled: return 'Cancelled';
      default:                      return 'Pending';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}
