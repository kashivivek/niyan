import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/widgets/responsive_centered.dart';

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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      databaseService.addTransaction(
        TransactionModel(
          id: '', // Firestore will generate this
          unitId: widget.unit.id,
          propertyId: widget.unit.propertyId,
          description: _description,
          amount: _amount,
          date: _selectedDate,
          type: _transactionType,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: ResponsiveCentered(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Please enter a valid amount.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _amount = double.parse(value!);
                },
              ),
              DropdownButtonFormField<TransactionType>(
                initialValue: _transactionType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: TransactionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _transactionType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                        'Date: ${_selectedDate.toLocal()}'.split(' ')[0]),
                  ),
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: const Text('Select date'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Add Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
