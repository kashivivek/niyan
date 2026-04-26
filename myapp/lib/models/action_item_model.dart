import 'package:flutter/foundation.dart';
import 'package:myapp/models/tenant_model.dart';

@immutable
class ActionItem {
  final TenantModel tenant;
  final String title;
  final String subtitle;
  final double amount;
  final bool isOverdue;
  final DateTime dueDate;
  final String month;

  const ActionItem({
    required this.tenant,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isOverdue,
    required this.dueDate,
    required this.month,
  });
}
