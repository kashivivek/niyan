import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class TransactionList extends StatelessWidget {
  final String unitId;

  const TransactionList({super.key, required this.unitId});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return StreamBuilder<List<TransactionModel>>(
      stream: dbService.getTransactionsForUnit(unitId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No transactions recorded for this unit yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final transactions = snapshot.data!;
        return ListView.separated(
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isIncome = transaction.type == TransactionType.income;
            final amountColor = isIncome ? Colors.green : Colors.red;
            final amountPrefix = isIncome ? '+' : '-';
            final typeName = transaction.type.name;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: amountColor.withAlpha(25),
                child: Icon(isIncome ? Icons.arrow_upward : Icons.arrow_downward, color: amountColor, size: 20),
              ),
              title: Text(
                typeName[0].toUpperCase() + typeName.substring(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(transaction.description.isNotEmpty ? transaction.description : 'No description'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix\$${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: amountColor, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd().format(transaction.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
