import 'package:myapp/models/tenancy_history_model.dart';
import 'package:myapp/models/tenant_model.dart';

class DetailedTenancyHistoryModel {
  final TenantModel tenant;
  final TenancyHistoryModel history;

  DetailedTenancyHistoryModel({required this.tenant, required this.history});
}
