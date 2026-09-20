import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/rent_status.dart';
import '../models/tenant_model.dart';
import '../models/rent_record_model.dart';

class RentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateMonthlyRentRecords(String ownerId) async {
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);

    final tenantsSnapshot = await _firestore
        .collection('tenants')
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: TenantStatus.active.toString())
        .get();

    for (final tenantDoc in tenantsSnapshot.docs) {
      final tenant = TenantModel.fromFirestore(tenantDoc);

      final rentRecordQuery = await _firestore
          .collection('rentRecords')
          .where('tenantId', isEqualTo: tenant.id)
          .where('month', isEqualTo: currentMonth)
          .limit(1)
          .get();

      if (rentRecordQuery.docs.isEmpty) {
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final dueDay = tenant.dueDate.day;
        final clampedDay = dueDay > daysInMonth ? daysInMonth : (dueDay <= 0 ? 1 : dueDay);
        final newRentRecord = RentRecordModel(
          id: '',
          tenantId: tenant.id,
          propertyId: tenant.propertyId,
          unitId: tenant.assignedUnitId,
          ownerId: tenant.ownerId,
          amount: tenant.rentAmount,
          month: currentMonth,
          status: RentStatus.pending,
          dueDate: DateTime(now.year, now.month, clampedDay),
          title: 'Rent - ${DateFormat('MMMM yyyy').format(now)}',
        );

        await _firestore
            .collection('rentRecords')
            .add(newRentRecord.toFirestore());
      }
    }
  }
}
