import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class MigrationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Migrates standalone data (Properties -> Units -> Tenants) into
  /// the new Society -> Members / Properties structure.
  /// 
  /// WARNING: This should only be run ONCE by a SuperAdmin.
  Future<void> migrateStandaloneToSociety(String ownerId, String societyName) async {
    developer.log('Starting Migration for Owner: $ownerId');
    
    // 1. Create a Society for this owner
    final societyRef = _db.collection('societies').doc();
    await societyRef.set({
      'name': societyName,
      'address': 'Migrated Address',
      'city': 'Migrated City',
      'state': 'Migrated State',
      'pincode': '000000',
      'subscriptionPlan': 'premium',
      'createdAt': FieldValue.serverTimestamp(),
    });
    final societyId = societyRef.id;

    // 2. Make the owner a SuperAdmin of this society
    final memberRef = _db.collection('societies').doc(societyId).collection('members').doc(ownerId);
    await memberRef.set({
      'userId': ownerId,
      'name': 'Migrated Owner',
      'role': 'superAdmin',
      'roles': ['superAdmin', 'owner'],
      'joinedAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    // 3. Migrate Properties
    final propertiesSnap = await _db.collection('properties').where('ownerId', isEqualTo: ownerId).get();
    
    for (var propDoc in propertiesSnap.docs) {
      final oldPropData = propDoc.data();
      final propId = propDoc.id;

      // Update property with societyId
      await propDoc.reference.update({'societyId': societyId});

      // 4. Migrate Units within this property
      final unitsSnap = await _db.collection('properties').doc(propId).collection('units').get();
      for (var unitDoc in unitsSnap.docs) {
        final oldUnitData = unitDoc.data();
        
        // Ensure unit has societyId
        await unitDoc.reference.update({'societyId': societyId});

        final currentTenantId = oldUnitData['currentTenantId'];
        if (currentTenantId != null && currentTenantId.toString().isNotEmpty) {
          // 5. If occupied, find the tenant and add them as a Resident/Tenant member
          final tenantSnap = await _db.collection('tenants').doc(currentTenantId).get();
          if (tenantSnap.exists) {
            final tenantData = tenantSnap.data()!;
            
            // Update tenant with societyId
            await tenantSnap.reference.update({'societyId': societyId});

            // Add to society members
            await _db.collection('societies').doc(societyId).collection('members').doc(currentTenantId).set({
              'userId': currentTenantId,
              'name': tenantData['name'] ?? 'Migrated Tenant',
              'email': tenantData['email'],
              'role': 'tenant',
              'roles': ['tenant'],
              'unitId': unitDoc.id,
              'unitNumber': oldUnitData['unitNumber'] ?? '',
              'propertyId': propId,
              'joinedAt': FieldValue.serverTimestamp(),
              'status': 'active',
            }, SetOptions(merge: true));

            // Optional: Create a Lease track for them
            if (tenantData['leaseStartDate'] != null && tenantData['leaseEndDate'] != null) {
              await _db.collection('leases').add({
                'societyId': societyId,
                'propertyId': propId,
                'unitId': unitDoc.id,
                'unitNumber': oldUnitData['unitNumber'] ?? '',
                'tenantId': currentTenantId,
                'tenantName': tenantData['name'] ?? '',
                'ownerId': ownerId,
                'startDate': tenantData['leaseStartDate'],
                'endDate': tenantData['leaseEndDate'],
                'monthlyRent': tenantData['rentAmount'] ?? 0,
                'securityDeposit': tenantData['securityDeposit'] ?? 0,
                'status': 'active',
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }
    }

    // Update invoices and rent records
    final recordsSnap = await _db.collection('rentRecords').where('ownerId', isEqualTo: ownerId).get();
    for (var record in recordsSnap.docs) {
      await record.reference.update({'societyId': societyId});
    }

    developer.log('Migration Complete! Society ID: $societyId');
  }
}
