import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String unitId;
  final String propertyId;
  final String ownerId;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? tenantId;
  final String? month; // Format: yyyy-MM (optional, used for rent payments)

  TransactionModel({
    required this.id,
    required this.unitId,
    required this.propertyId,
    required this.ownerId,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    this.tenantId,
    this.month,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      unitId: data['unitId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] == 'expense' ? TransactionType.expense : TransactionType.income,
      tenantId: data['tenantId'],
      month: data['month'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'unitId': unitId,
      'propertyId': propertyId,
      'ownerId': ownerId,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'type': type == TransactionType.expense ? 'expense' : 'income',
      'tenantId': tenantId,
      'month': month,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? unitId,
    String? propertyId,
    String? ownerId,
    String? description,
    double? amount,
    DateTime? date,
    TransactionType? type,
    String? tenantId,
    String? month,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      propertyId: propertyId ?? this.propertyId,
      ownerId: ownerId ?? this.ownerId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      tenantId: tenantId ?? this.tenantId,
      month: month ?? this.month,
    );
  }
}
