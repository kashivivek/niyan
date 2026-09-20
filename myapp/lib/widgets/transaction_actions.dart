import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:myapp/services/database_service.dart';

/// Presents Edit / Delete actions for a [tx] from any transaction list.
Future<void> showTransactionActions(BuildContext context, TransactionModel tx) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Transaction'),
            onTap: () {
              Navigator.pop(sheetContext);
              _showEditDialog(context, tx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Delete Transaction', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(sheetContext);
              _confirmDelete(context, tx);
            },
          ),
        ],
      ),
    ),
  );
}

void _showEditDialog(BuildContext context, TransactionModel tx) {
  final descriptionController = TextEditingController(text: tx.description);
  final amountController = TextEditingController(text: tx.amount.toStringAsFixed(2));
  var type = tx.type;
  var date = tx.date;

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Transaction'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TransactionType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: TransactionType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t == TransactionType.income ? 'Income' : 'Expense'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => type = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date', style: TextStyle(fontSize: 14)),
                    subtitle: Text(DateFormat('d MMM yyyy').format(date)),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setDialogState(() => date = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final description = descriptionController.text.trim();
                  final amount = double.tryParse(amountController.text.trim());
                  if (description.isEmpty || amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid description and amount.')),
                    );
                    return;
                  }
                  final db = Provider.of<DatabaseService>(context, listen: false);
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await db.updateTransaction(tx.copyWith(
                      description: description,
                      amount: amount,
                      type: type,
                      date: date,
                      // Rent-month tagging only applies to income entries.
                      month: type == TransactionType.income ? tx.month : null,
                    ));
                    navigator.pop();
                    messenger.showSnackBar(const SnackBar(content: Text('Transaction updated.')));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Update failed: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _confirmDelete(BuildContext context, TransactionModel tx) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete Transaction'),
      content: const Text(
        'This removes the ledger entry only. If it was a rent payment, the '
        'related rent record status will not change automatically.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final db = Provider.of<DatabaseService>(context, listen: false);
            final navigator = Navigator.of(dialogContext);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await db.deleteTransaction(tx.id);
              navigator.pop();
              messenger.showSnackBar(const SnackBar(content: Text('Transaction deleted.')));
            } catch (e) {
              messenger.showSnackBar(SnackBar(content: Text('Delete failed: $e')));
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
