import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/rent_record_model.dart';
import 'package:myapp/models/rent_status.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/utils/currency_helper.dart';
import 'package:myapp/utils/rent_message_helper.dart';

class RentTrackerScreen extends StatefulWidget {
  final TenantModel tenant;

  const RentTrackerScreen({super.key, required this.tenant});

  @override
  State<RentTrackerScreen> createState() => _RentTrackerScreenState();
}

class _RentTrackerScreenState extends State<RentTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Rent Tracker - ${widget.tenant.name}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<RentRecordModel>>(
        stream: databaseService.getRentRecordsForTenant(widget.tenant.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No rent records found.'));
          }
          final rentRecords = snapshot.data!;
          final currency = Provider.of<UserModel?>(context)?.currency;
          return ListView.builder(
            itemCount: rentRecords.length,
            itemBuilder: (context, index) {
              final record = rentRecords[index];
              final monthLabel = DateFormat('MMMM yyyy').format(DateFormat('yyyy-MM').parse(record.month));
              final subtitle = record.status == RentStatus.partial
                  ? 'Paid ${CurrencyHelper.format(record.paidAmount, currency)} of ${CurrencyHelper.format(record.amount, currency)} · Balance ${CurrencyHelper.format(record.outstanding, currency)}'
                  : 'Amount: ${CurrencyHelper.format(record.amount, currency)}';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(monthLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(record.status.toString().split('.').last, style: TextStyle(color: _getStatusColor(record.status), fontWeight: FontWeight.w600)),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'pay':
                              _showUpdateStatusDialog(record);
                              break;
                            case 'latefee':
                              _applyLateFee(record);
                              break;
                            case 'reminder':
                              _sendReminder(record);
                              break;
                            case 'receipt':
                              _shareReceipt(record);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          if (record.status != RentStatus.paid)
                            const PopupMenuItem(value: 'pay', child: Text('Record Payment')),
                          if (record.status != RentStatus.paid &&
                              record.title != 'Late Fee' &&
                              DateTime.now().isAfter(record.dueDate))
                            const PopupMenuItem(value: 'latefee', child: Text('Apply Late Fee')),
                          if (record.outstanding > 0)
                            const PopupMenuItem(value: 'reminder', child: Text('Send Reminder')),
                          if (record.paidAmount > 0)
                            const PopupMenuItem(value: 'receipt', child: Text('Share Receipt')),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _showUpdateStatusDialog(record),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(RentStatus status) {
    switch (status) {
      case RentStatus.paid:
        return Colors.green;
      case RentStatus.pending:
        return Colors.orange;
      case RentStatus.partial:
        return Colors.blue;
    }
  }

  void _showUpdateStatusDialog(RentRecordModel record) {
    if (record.status == RentStatus.paid) {
      // Already settled — offer the receipt instead of a payment form.
      _shareReceipt(record);
      return;
    }

    final outstanding = record.outstanding > 0 ? record.outstanding : record.amount;
    final amountController = TextEditingController(text: outstanding.toStringAsFixed(2));
    final paymentMethodController = TextEditingController(text: record.paymentMethod);
    final notesController = TextEditingController(text: record.notes);
    DateTime paymentDate = DateTime.now();
    final currency = Provider.of<UserModel?>(context, listen: false)?.currency;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record Payment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Billed: ${CurrencyHelper.format(record.amount, currency)}', style: GoogleFonts.inter(fontSize: 13)),
                    if (record.paidAmount > 0)
                      Text('Already paid: ${CurrencyHelper.format(record.paidAmount, currency)}', style: GoogleFonts.inter(fontSize: 13)),
                    Text('Outstanding: ${CurrencyHelper.format(record.outstanding, currency)}',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount Received'),
                    ),
                    TextField(
                      controller: paymentMethodController,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                    ),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Payment Date', style: TextStyle(fontSize: 14)),
                      subtitle: Text(DateFormat('d MMM yyyy').format(paymentDate)),
                      trailing: const Icon(Icons.calendar_today, size: 18),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: paymentDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setDialogState(() => paymentDate = picked);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid amount.')),
                      );
                      return;
                    }
                    final databaseService = Provider.of<DatabaseService>(context, listen: false);
                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final updated = await databaseService.recordRentRecordPayment(
                        record: record,
                        paymentAmount: amount,
                        ownerId: record.ownerId,
                        paymentDate: paymentDate,
                        paymentMethod: paymentMethodController.text.trim(),
                        notes: notesController.text.trim(),
                      );
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text(updated.status == RentStatus.paid ? 'Payment recorded — paid in full.' : 'Partial payment recorded.')),
                      );
                      if (mounted) _offerReceipt(updated);
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Failed to record payment: $e')));
                    }
                  },
                  child: const Text('Record'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _offerReceipt(RentRecordModel record) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share a receipt with the tenant?'),
        action: SnackBarAction(label: 'Share', onPressed: () => _shareReceipt(record)),
      ),
    );
  }

  String get _landlordName {
    final user = Provider.of<UserModel?>(context, listen: false);
    return (user?.name != null && user!.name!.isNotEmpty) ? user.name! : 'Your Landlord';
  }

  Future<void> _applyLateFee(RentRecordModel record) async {
    final currency = Provider.of<UserModel?>(context, listen: false)?.currency;
    final controller = TextEditingController();
    final monthLabel = DateFormat('MMMM yyyy').format(DateFormat('yyyy-MM').parse(record.month));

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Apply Late Fee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${record.title} · $monthLabel'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Late Fee Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, double.tryParse(controller.text.trim())),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (amount == null) return;
    if (!mounted) return;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount.')),
      );
      return;
    }

    final db = Provider.of<DatabaseService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await db.applyLateFeeToRecord(record: record, feeAmount: amount);
      messenger.showSnackBar(
        SnackBar(content: Text('Late fee of ${CurrencyHelper.format(amount, currency)} applied.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _sendReminder(RentRecordModel record) async {
    final currency = Provider.of<UserModel?>(context, listen: false)?.currency;
    final message = RentMessageHelper.buildReminderMessage(
      tenantName: widget.tenant.name,
      landlordName: _landlordName,
      outstanding: record.outstanding > 0 ? record.outstanding : record.amount,
      dueDate: record.dueDate,
      propertyLabel: 'your rented unit',
      currency: currency,
    );
    final sent = await RentMessageHelper.sendToTenant(phone: widget.tenant.phoneNumber, message: message);
    if (!sent && mounted) _showMessageFallback('Rent Reminder', message);
  }

  Future<void> _shareReceipt(RentRecordModel record) async {
    final currency = Provider.of<UserModel?>(context, listen: false)?.currency;
    final paymentDate = record.paymentDate ?? DateTime.now();
    final message = RentMessageHelper.buildReceiptMessage(
      tenantName: widget.tenant.name,
      landlordName: _landlordName,
      paidAmount: record.paidAmount > 0 ? record.paidAmount : record.amount,
      billedAmount: record.amount,
      outstanding: record.outstanding,
      paymentDate: paymentDate,
      period: DateFormat('MMMM yyyy').format(DateFormat('yyyy-MM').parse(record.month)),
      propertyLabel: 'your rented unit',
      receiptNo: RentMessageHelper.receiptNumber(record.id, paymentDate),
      paymentMethod: record.paymentMethod,
      currency: currency,
    );
    final sent = await RentMessageHelper.sendToTenant(phone: widget.tenant.phoneNumber, message: message);
    if (!sent && mounted) _showMessageFallback('Rent Receipt', message);
  }

  void _showMessageFallback(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: SelectableText(message)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard.')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
