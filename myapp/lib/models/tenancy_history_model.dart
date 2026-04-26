import 'package:cloud_firestore/cloud_firestore.dart';

class TenancyHistoryModel {
  final String id;
  final String tenantId;
  final String unitId;
  final DateTime startDate;
  final DateTime? endDate;

  TenancyHistoryModel({
    required this.id,
    required this.tenantId,
    required this.unitId,
    required this.startDate,
    this.endDate,
  });

  factory TenancyHistoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TenancyHistoryModel(
      id: doc.id,
      tenantId: data['tenantId'],
      unitId: data['unitId'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'unitId': unitId,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}
