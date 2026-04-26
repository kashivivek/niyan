import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/rent_status.dart';

@immutable
class RentRecordModel {
  final String id;
  final String tenantId;
  final String propertyId;
  final String unitId;
  final double amount;
  final String month;
  final RentStatus status;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String? notes;

  const RentRecordModel({
    required this.id,
    required this.tenantId,
    required this.propertyId,
    required this.unitId,
    required this.amount,
    required this.month,
    required this.status,
    this.paymentDate,
    this.paymentMethod,
    this.notes,
  });

  factory RentRecordModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RentRecordModel(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      unitId: data['unitId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      month: data['month'] ?? '',
      status: RentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => RentStatus.pending,
      ),
      paymentDate: data['paymentDate'] != null
          ? (data['paymentDate'] as Timestamp).toDate()
          : null,
      paymentMethod: data['paymentMethod'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'propertyId': propertyId,
      'unitId': unitId,
      'amount': amount,
      'month': month,
      'status': status.toString().split('.').last,
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  RentRecordModel copyWith({
    String? id,
    String? tenantId,
    String? propertyId,
    String? unitId,
    double? amount,
    String? month,
    RentStatus? status,
    DateTime? paymentDate,
    String? paymentMethod,
    String? notes,
  }) {
    return RentRecordModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      status: status ?? this.status,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }
}
