import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/invoice_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/billing_service.dart';
import 'package:myapp/widgets/responsive_layout.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _residentNameCtrl = TextEditingController();
  final _unitNumberCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  InvoiceCategory _category = InvoiceCategory.maintenance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final appMode = Provider.of<AppModeProvider>(context);
    final user = Provider.of<UserModel?>(context);

    if (appMode.activeSociety == null) {
      return const Scaffold(body: Center(child: Text('No active society selected')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Invoice')),
      body: ResponsiveCentered(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bill To', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: _residentNameCtrl, decoration: const InputDecoration(labelText: 'Resident Name')),
              const SizedBox(height: 12),
              TextField(controller: _unitNumberCtrl, decoration: const InputDecoration(labelText: 'Unit Number')),
              const SizedBox(height: 32),
              Text('Charges', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<InvoiceCategory>(
                value: _category,
                items: InvoiceCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.toString().split('.').last.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _category = v!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: ThemeProvider.accentBlue, foregroundColor: Colors.white),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('GENERATE INVOICE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final appMode = Provider.of<AppModeProvider>(context, listen: false);
      final user = Provider.of<UserModel?>(context, listen: false);
      final billingService = Provider.of<BillingService>(context, listen: false);
      
      final invoice = InvoiceModel.create(
        id: '',
        societyId: appMode.activeSociety!.id,
        unitId: 'temp',
        propertyId: 'temp',
        residentId: 'temp',
        residentName: _residentNameCtrl.text.trim(),
        unitNumber: _unitNumberCtrl.text.trim(),
        propertyName: appMode.activeSociety!.name,
        lineItems: [InvoiceLineItem(description: _descCtrl.text.trim(), category: _category, amount: double.parse(_amountCtrl.text.trim()))],
        billingMonth: DateFormat('yyyy-MM').format(DateTime.now()),
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 10)),
        createdBy: user?.uid ?? 'Admin',
      );
      
      await billingService.createInvoice(invoice);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
