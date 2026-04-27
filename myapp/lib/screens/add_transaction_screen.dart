import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/widgets/responsive_centered.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  final UnitModel unit;

  const AddTransactionScreen({super.key, required this.unit});

  @override
  AddTransactionScreenState createState() => AddTransactionScreenState();
}

class AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  double _amount = 0.0;
  TransactionType _transactionType = TransactionType.income;
  DateTime _selectedDate = DateTime.now();
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    // Default description for convenience
    _description = 'Rent Payment';
    _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      databaseService.addTransaction(
        TransactionModel(
          id: '',
          unitId: widget.unit.id,
          propertyId: widget.unit.propertyId,
          ownerId: ownerId,
          tenantId: widget.unit.currentTenantId,
          description: _description,
          amount: _amount,
          date: _selectedDate,
          type: _transactionType,
          month: _transactionType == TransactionType.income ? _selectedMonth : null,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate month options: 6 months back + current + 2 months ahead
    final now = DateTime.now();
    final months = List.generate(9, (i) {
      final m = DateTime(now.year, now.month - 6 + i);
      return DateFormat('yyyy-MM').format(m);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        centerTitle: true,
      ),
      body: ResponsiveCentered(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description.' : null,
                  onSaved: (value) => _description = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null) {
                      return 'Please enter a valid amount.';
                    }
                    return null;
                  },
                  onSaved: (value) => _amount = double.parse(value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TransactionType>(
                  value: _transactionType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: TransactionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type == TransactionType.income ? 'Income' : 'Expense'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _transactionType = value);
                    }
                  },
                ),
                if (_transactionType == TransactionType.income) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Apply to Rent Month',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                      helperText: 'Select which month this rent applies to.',
                    ),
                    items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMonth = value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Transaction Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(DateFormat('d MMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.event_rounded),
                      label: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                  child: const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
