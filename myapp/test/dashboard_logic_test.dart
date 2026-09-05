import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/rent_record_model.dart';
import 'package:myapp/models/rent_status.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/services/database_service.dart';

void main() {
  test('groups pending dues by tenant and reflects current rent amount', () {
    final now = DateTime.now();
    final firstDueDate = now.subtract(const Duration(days: 10));
    final secondDueDate = now.add(const Duration(days: 3));
    final tenant = TenantModel(
      id: 'tenant-1',
      name: 'Asha Patel',
      ownerId: 'owner-1',
      propertyId: 'property-1',
      assignedUnitId: 'unit-1',
      dueDate: firstDueDate,
      moveInDate: DateTime(2025, 1, 1),
      rentAmount: 12000,
    );

    final unit = UnitModel(
      id: 'unit-1',
      propertyId: 'property-1',
      ownerId: 'owner-1',
      unitNumber: 'A-101',
      monthlyRent: 15000,
      rentDueDate: 10,
      sqft: 600,
      bedrooms: 2,
      bathrooms: 2,
      status: 'occupied',
      currentTenantId: 'tenant-1',
    );

    final property = PropertyModel(
      id: 'property-1',
      name: 'Sunrise Apartments',
      address: 'MG Road',
      city: 'Bengaluru',
      type: PropertyType.flat,
      ownerId: 'owner-1',
      coOwnerIds: const ['owner-2'],
    );

    final records = [
      RentRecordModel(
        id: 'r1',
        tenantId: 'legacy-tenant-id',
        propertyId: 'property-1',
        unitId: 'unit-1',
        ownerId: 'owner-1',
        amount: 12000,
        month: DateFormat('yyyy-MM').format(firstDueDate),
        status: RentStatus.pending,
        dueDate: firstDueDate,
        title: 'Monthly Rent',
      ),
      RentRecordModel(
        id: 'r2',
        tenantId: 'tenant-1',
        propertyId: 'property-1',
        unitId: 'unit-1',
        ownerId: 'owner-1',
        amount: 12000,
        month: DateFormat('yyyy-MM').format(secondDueDate),
        status: RentStatus.pending,
        dueDate: secondDueDate,
        title: 'Monthly Rent',
      ),
    ];

    final items = DatabaseService.buildActionItems(
      records: records,
      tenants: [tenant],
      properties: [property],
      units: [unit],
    );

    expect(items.length, 1);
    expect(items.first.tenant.name, 'Asha Patel');
    expect(items.first.amount, 30000);
    expect(items.first.month, contains(DateFormat('MMM yyyy').format(firstDueDate)));
    expect(items.first.month, contains(DateFormat('MMM yyyy').format(secondDueDate)));
  });
}
