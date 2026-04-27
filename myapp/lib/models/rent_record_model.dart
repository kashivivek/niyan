import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/rent_status.dart';

@immutable
class RentRecordModel {
  final String id;
  final String tenantId;
  final String propertyId;
  final String unitId;
  final String ownerId;
  final double amount;
  final String month;
  final RentStatus status;
  final DateTime dueDate;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String? notes;
  final String title;

  const RentRecordModel({
    required this.id,
    required this.tenantId,
    required this.propertyId,
    required this.unitId,
    required this.ownerId,
    required this.amount,
    required this.month,
    required this.status,
    required this.dueDate,
    this.paymentDate,
    this.paymentMethod,
    this.notes,
    this.title = 'Monthly Rent',
  });

  factory RentRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentRecordModel(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      unitId: data['unitId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      month: data['month'] ?? '',
      status: RentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => RentStatus.pending,
      ),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentDate: (data['paymentDate'] as Timestamp?)?.toDate(),
      paymentMethod: data['paymentMethod'],
      notes: data['notes'],
      title: data['title'] ?? 'Monthly Rent',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'propertyId': propertyId,
      'unitId': unitId,
      'ownerId': ownerId,
      'amount': amount,
      'month': month,
      'status': status.toString().split('.').last,
      'dueDate': Timestamp.fromDate(dueDate),
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'title': title,
    };
  }

  RentRecordModel copyWith({
    String? id,
    String? tenantId,
    String? propertyId,
    String? unitId,
    String? ownerId,
    double? amount,
    String? month,
    RentStatus? status,
    DateTime? dueDate,
    DateTime? paymentDate,
    String? paymentMethod,
    String? notes,
    String? title,
  }) {
    return RentRecordModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      ownerId: ownerId ?? this.ownerId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      title: title ?? this.title,
    );
  }
}
