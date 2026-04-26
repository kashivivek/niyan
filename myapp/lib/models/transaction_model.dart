import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String unitId;
  final String propertyId;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;

  TransactionModel({
    required this.id,
    required this.unitId,
    required this.propertyId,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      unitId: data['unitId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      type: TransactionType.values.firstWhere((e) => e.toString() == data['type']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'unitId': unitId,
      'propertyId': propertyId,
      'description': description,
      'amount': amount,
      'date': date,
      'type': type.toString(),
    };
  }
}
