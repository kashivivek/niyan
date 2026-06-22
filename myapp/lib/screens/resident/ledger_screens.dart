import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/invoice_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/services/billing_service.dart';
import 'package:myapp/utils/currency_helper.dart';
import 'package:myapp/widgets/responsive_layout.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ResidentLedgerScreen extends StatelessWidget {
  const ResidentLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appMode = Provider.of<AppModeProvider>(context);
    final user = Provider.of<UserModel?>(context);
    final billingService = Provider.of<BillingService>(context, listen: false);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator(color: ThemeProvider.accentTeal)));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Financial Ledger', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<InvoiceModel>>(
        stream: billingService.getInvoices(residentId: user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: ThemeProvider.accentTeal));
          }
          final invoices = snapshot.data ?? [];
          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_rounded, size: 64, color: Colors.grey.shade100),
                  const SizedBox(height: 16),
                  Text('No payment history found.', style: GoogleFonts.inter(color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          final totalDue = invoices
              .where((i) => i.status != InvoiceStatus.paid && i.status != InvoiceStatus.cancelled)
              .fold(0.0, (sum, i) => sum + i.grandTotal);

          return ResponsiveCentered(
            child: Column(
              children: [
                _buildSummaryHeader(context, totalDue, user.currency),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Transaction History', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      Icon(Icons.filter_list_rounded, color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: invoices.length,
                    itemBuilder: (context, index) => _LedgerItem(invoice: invoices[index], currency: user.currency),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, double totalDue, String currency) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: ThemeProvider.primaryNavy.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL OUTSTANDING', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(
            CurrencyHelper.format(totalDue, currency),
            style: GoogleFonts.outfit(color: Theme.of(context).cardColor, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          if (totalDue > 0) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => _simulatePayment(context),
                style: ElevatedButton.styleFrom(backgroundColor: ThemeProvider.accentTeal, foregroundColor: Colors.white),
                child: const Text('PAY ALL DUES NOW', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _simulatePayment(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Secure Payment'),
        content: const Text('Redirecting to payment gateway... (Demo Mode: All invoices will be marked as paid)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text('CONFIRM')),
        ],
      ),
    );
  }
}

class _LedgerItem extends StatelessWidget {
  final InvoiceModel invoice;
  final String currency;
  const _LedgerItem({required this.invoice, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isPaid = invoice.status == InvoiceStatus.paid;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPaid ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isPaid ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        title: Text(
          DateFormat('MMMM yyyy').format(DateFormat('yyyy-MM').parse(invoice.billingMonth)),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
        ),
        subtitle: Text(isPaid ? 'Payment Successful' : 'Due ${DateFormat('MMM dd').format(invoice.dueDate)}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyHelper.format(invoice.grandTotal, currency),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
            ),
            if (!isPaid) const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class GatePassScreen extends StatelessWidget {
  const GatePassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('My Gate Pass')),
      body: ResponsiveCentered(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Universal Resident Access', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              Text('Present this code at any society entry point.', style: GoogleFonts.inter(color: Colors.grey.shade500)),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))],
                ),
                child: QrImageView(
                  data: user?.uid ?? 'unknown',
                  version: QrVersions.auto,
                  size: 240.0,
                  foregroundColor: ThemeProvider.primaryNavy,
                ),
              ),
              const SizedBox(height: 48),
              Text(user?.name?.toUpperCase() ?? 'RESIDENT', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(color: ThemeProvider.accentTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded, color: ThemeProvider.accentTeal, size: 16),
                    const SizedBox(width: 8),
                    Text('VERIFIED STATUS', style: GoogleFonts.inter(color: ThemeProvider.accentTeal, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
