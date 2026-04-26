import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:myapp/firebase_options.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(home: SetupDataScreen()));
}

class SetupDataScreen extends StatefulWidget {
  const SetupDataScreen({super.key});

  @override
  State<SetupDataScreen> createState() => _SetupDataScreenState();
}

class _SetupDataScreenState extends State<SetupDataScreen> {
  String status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _setupData();
  }

  Future<void> _setupData() async {
    final auth = FirebaseAuth.instance;
    final databaseService = DatabaseService();

    // 1. Define Test User Credentials
    const String testEmail = "test.user@example.com";
    const String testPassword = "password123";

    setState(() => status = 'Creating test user...');

    try {
      // 2. Create Test User
      UserCredential userCredential;
      try {
        userCredential = await auth.signInWithEmailAndPassword(
            email: testEmail, password: testPassword);
      } catch (e) {
        if (e is FirebaseAuthException && (e.code == 'user-not-found' || e.code == 'invalid-credential')) {
          userCredential = await auth.createUserWithEmailAndPassword(
              email: testEmail, password: testPassword);
        } else {
          rethrow;
        }
      }

      final String userId = userCredential.user!.uid;

      setState(() => status = 'Adding Property...');

      // 3. Add Property
      final property = PropertyModel(
        id: '',
        name: 'Sunset Apartments',
        address: '123 Main St, Anytown, USA',
        ownerId: userId,
        city: 'Anytown',
        type: PropertyType.flat,
        imageUrl: '',
      );
      
      final db = FirebaseFirestore.instance;
      final propertyRef = await db.collection('properties').add(property.toFirestore());

      setState(() => status = 'Adding Unit...');

      // 4. Add Unit
      final unit = UnitModel(
        id: '',
        unitNumber: '101',
        bedrooms: 2,
        bathrooms: 1,
        sqft: 850,
        monthlyRent: 1200.0,
        rentDueDate: 5,
        status: 'vacant',
        ownerId: userId,
        propertyId: propertyRef.id,
      );
      final unitRef = await db.collection('properties').doc(propertyRef.id).collection('units').add(unit.toFirestore());

      setState(() => status = 'Adding Tenant...');

      // 5. Add Tenant
      final tenant = TenantModel(
        id: '',
        name: 'John Doe',
        phoneNumber: '555-1234',
        email: 'john.doe@example.com',
        rentAmount: 1200.0,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        moveInDate: DateTime.now().subtract(const Duration(days: 30)),
        ownerId: userId,
        isAssignedToUnit: false,
        assignedUnitId: '',
        propertyId: '',
      );
      final tenantRef = await db.collection('tenants').add(tenant.toFirestore());

      setState(() => status = 'Assigning Tenant to Unit...');

      // 6. Assign Tenant to Unit
      await databaseService.assignTenantToUnit(
        unitId: unitRef.id, 
        tenantId: tenantRef.id, 
        propertyId: propertyRef.id
      );

      setState(() => status = 'Adding complete. You can now login with:\n\nEmail: $testEmail\nPassword: $testPassword');
      
      print('SETUP COMPLETE: You can login with $testEmail and $testPassword');
      Future.delayed(const Duration(seconds: 2), () => exit(0));

    } catch (e) {
      if(mounted) {
        setState(() => status = 'An error occurred: $e');
        print('SETUP ERROR: $e');
        Future.delayed(const Duration(seconds: 2), () => exit(1));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Data Tool')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
