import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/unit_model.dart';

class UpcomingDue {
  final TenantModel tenant;
  final UnitModel unit;
  final PropertyModel property;
  final DateTime dueDate;
  final double amount;

  UpcomingDue({
    required this.tenant,
    required this.unit,
    required this.property,
    required this.dueDate,
    required this.amount,
  });
}
