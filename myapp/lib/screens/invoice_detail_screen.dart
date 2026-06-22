import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/invoice_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/billing_service.dart';
import 'package:myapp/utils/currency_helper.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;
  final InvoiceModel? invoice; // Passed via router extra for instant display

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
    this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    final billingService = Provider.of<BillingService>(context, listen: false);

    return StreamBuilder<InvoiceModel>(
      stream: billingService.getInvoiceStream(invoiceId),
      initialData: invoice,
      builder: (context, snapshot) {
        final inv = snapshot.data;
        if (inv == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return _InvoiceDetailBody(invoice: inv);
      },
    );
  }
}

class _InvoiceDetailBody extends StatefulWidget {
  final InvoiceModel invoice;
  const _InvoiceDetailBody({required this.invoice});

  @override
  State<_InvoiceDetailBody> createState() => _InvoiceDetailBodyState();
}

class _InvoiceDetailBodyState extends State<_InvoiceDetailBody> {
  bool _isProcessing = false;

  Future<void> _markPaid() async {
    final billingService = context.read<BillingService>();
    final user = context.read<UserModel?>();
    if (user == null) return;

    final method = await _showPaymentMethodDialog();
    if (method == null) return;

    setState(() => _isProcessing = true);
    try {
      await billingService.markInvoicePaid(
        invoiceId: widget.invoice.id,
        ownerId: user.uid,
        paymentMethod: method,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice marked as paid ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String?> _showPaymentMethodDialog() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payment Method', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final method in ['UPI', 'Bank Transfer', 'Cash', 'Cheque', 'Card'])
              ListTile(
                title: Text(method, style: GoogleFonts.inter()),
                onTap: () => Navigator.pop(ctx, method),
                leading: Icon(Icons.payment_outlined),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final user = Provider.of<UserModel?>(context);
    final currency = user?.currency ?? 'INR';
    final isPaid = inv.status == InvoiceStatus.paid;
    final isOverdue = inv.isOverdue;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Invoice', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        actions: [
          if (!isPaid)
            TextButton.icon(
              onPressed: _isProcessing ? null : _markPaid,
              icon: Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text('Mark Paid', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(foregroundColor: Colors.green.shade700),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(inv, currency, isPaid, isOverdue),
            const SizedBox(height: 20),
            // Line items
            _buildSectionHeader('Charges Breakdown'),
            const SizedBox(height: 10),
            _buildLineItems(inv, currency),
            const SizedBox(height: 20),
            // Totals
            _buildTotalsCard(inv, currency),
            const SizedBox(height: 20),
            // Payment info (if paid)
            if (isPaid) ...[
              _buildSectionHeader('Payment Details'),
              const SizedBox(height: 10),
              _buildPaymentDetails(inv),
              const SizedBox(height: 20),
            ],
            // Notes
            if (inv.notes != null && inv.notes!.isNotEmpty) ...[
              _buildSectionHeader('Notes'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Text(inv.notes!, style: GoogleFonts.inter(color: Colors.grey.shade700)),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(InvoiceModel inv, String currency, bool isPaid, bool isOverdue) {
    final statusColor = isPaid
        ? Colors.green.shade600
        : isOverdue
            ? Colors.red.shade600
            : ThemeProvider.accentBlue;
    final statusLabel = isPaid ? 'Paid' : isOverdue ? 'Overdue' : inv.status.toString().split('.').last;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ThemeProvider.primaryNavy, const Color(0xFF3D3D4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: ThemeProvider.primaryNavy.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                    Text(inv.residentName,
                        style: GoogleFonts.outfit(
                            color: Theme.of(context).cardColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                    const SizedBox(height: 4),
                    Text('${inv.propertyName} · Unit ${inv.unitNumber}',
                        style: GoogleFonts.inter(
                            color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel.toUpperCase(),
                  style: GoogleFonts.outfit(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            CurrencyHelper.format(inv.grandTotal, currency),
            style: GoogleFonts.outfit(
                color: Theme.of(context).cardColor,
                fontWeight: FontWeight.bold,
                fontSize: 34),
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('MMMM yyyy').format(DateFormat('yyyy-MM').parse(inv.billingMonth))} · Due ${DateFormat('d MMM yyyy').format(inv.dueDate)}',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),
          if (inv.gstNumber != null) ...[
            const SizedBox(height: 8),
            Text('GSTIN: ${inv.gstNumber}',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildLineItems(InvoiceModel inv, String currency) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          for (int i = 0; i < inv.lineItems.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
            _buildLineItemRow(inv.lineItems[i], currency),
          ],
        ],
      ),
    );
  }

  Widget _buildLineItemRow(InvoiceLineItem item, String currency) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 2),
                Text(item.category.label,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey.shade400)),
                if (item.gstAmount > 0)
                  Text(
                    '+ GST ${CurrencyHelper.format(item.gstAmount, currency)}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.orange.shade400),
                  ),
              ],
            ),
          ),
          Text(
            CurrencyHelper.format(item.totalWithGst, currency),
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(InvoiceModel inv, String currency) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', inv.subtotal, currency, isTotal: false),
          if (inv.totalGst > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow('Total GST', inv.totalGst, currency, isTotal: false, color: Colors.orange.shade700),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _buildTotalRow('Grand Total', inv.grandTotal, currency, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, String currency, {required bool isTotal, Color? color}) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
                color: color ?? (isTotal ? ThemeProvider.primaryNavy : Colors.grey.shade600))),
        const Spacer(),
        Text(
          CurrencyHelper.format(amount, currency),
          style: GoogleFonts.outfit(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
              color: color ?? (isTotal ? ThemeProvider.primaryNavy : Colors.grey.shade600)),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails(InvoiceModel inv) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Received',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (inv.paidDate != null)
                      DateFormat('d MMM yyyy').format(inv.paidDate!),
                    if (inv.paymentMethod != null) inv.paymentMethod!,
                    if (inv.paymentReference != null) inv.paymentReference!,
                  ].join(' · '),
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.2),
    );
  }
}
