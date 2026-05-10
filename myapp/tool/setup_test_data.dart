import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show exit;

import 'package:myapp/firebase_options.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/society_model.dart';
import 'package:myapp/models/member_model.dart';
import 'package:myapp/models/asset_model.dart';
import 'package:myapp/models/invoice_model.dart';
import 'package:myapp/models/ticket_model.dart';
import 'package:myapp/models/user_model.dart';

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
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _setupData();
  }

  Future<UserCredential> _getOrCreateUser(String email, String password, String name, AppRole role, String? societyId) async {
    UserCredential cred;
    try {
      cred = await auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
    }
    
    // Update user profile
    await db.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'name': name,
      'currentRole': role.toString(),
      'activeSocietyId': societyId,
      'societyIds': societyId != null ? [societyId] : [],
      'notificationsEnabled': true,
      'notificationTime': '09:00',
      'notificationTimezone': 'UTC',
      'notificationFrequency': 'Daily',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return cred;
  }

  Future<void> _setupData() async {
    setState(() => status = 'Creating Demo Data...');

    try {
      // 1. Create Admin User First
      setState(() => status = 'Creating Admin...');
      final societyId = db.collection('societies').doc().id; 
      final adminCred = await _getOrCreateUser('admin@example.com', 'password123', 'Admin Alex', AppRole.societyAdmin, societyId);
      final adminId = adminCred.user!.uid;

      // 2. Create Society
      setState(() => status = 'Creating Society...');
      final societyRef = db.collection('societies').doc(societyId);
      final society = SocietyModel(
        id: societyRef.id,
        name: 'The Zillow Residences',
        address: '100 Silicon Valley Way',
        city: 'San Francisco',
        createdBy: adminId,
        createdAt: DateTime.now(),
        settings: const SocietySettings(
          currency: 'USD',
          lateFeeFlat: 50.0,
          gracePeriodDays: 5,
        ),
      );
      await societyRef.set(society.toFirestore());

      // 3. Create Properties and Units
      setState(() => status = 'Creating Properties...');
      final blockA = PropertyModel(
        id: '',
        name: 'Block A',
        address: '100 Silicon Valley Way',
        ownerId: adminId,
        city: 'San Francisco',
        type: PropertyType.flat,
        imageUrl: '',
      );
      final propRef = await societyRef.collection('properties').add(blockA.toFirestore());
      
      final unitRef = societyRef.collection('properties').doc(propRef.id).collection('units').doc();

      // 4. Create Resident User
      setState(() => status = 'Creating Resident...');
      final resCred = await _getOrCreateUser('resident@example.com', 'password123', 'Resident Ryan', AppRole.resident, societyRef.id);
      final residentId = resCred.user!.uid;

      final unit = UnitModel(
        id: unitRef.id,
        unitNumber: 'A-101',
        bedrooms: 3,
        bathrooms: 2,
        sqft: 1500,
        monthlyRent: 3500.0,
        rentDueDate: 5,
        status: 'occupied',
        ownerId: adminId,
        propertyId: propRef.id,
        currentTenantId: residentId,
      );
      await unitRef.set(unit.toFirestore());

      // 5. Create Guard User
      setState(() => status = 'Creating Guard...');
      final guardCred = await _getOrCreateUser('guard@example.com', 'password123', 'Guard Gary', AppRole.guard, societyRef.id);
      final guardId = guardCred.user!.uid;

      await auth.signInWithEmailAndPassword(email: 'admin@example.com', password: 'password123');

      // 6. Create Society Members
      setState(() => status = 'Assigning Roles...');
      
      await societyRef.collection('members').doc(adminId).set(
        MemberModel(
          id: adminId,
          societyId: societyRef.id,
          role: SocietyRole.admin,
          displayName: 'Admin Alex',
          status: MemberStatus.active,
          joinedAt: DateTime.now(),
        ).toFirestore()
      );

      await societyRef.collection('members').doc(residentId).set(
        MemberModel(
          id: residentId,
          societyId: societyRef.id,
          role: SocietyRole.tenant,
          displayName: 'Resident Ryan',
          unitIds: [unitRef.id],
          status: MemberStatus.active,
          joinedAt: DateTime.now(),
        ).toFirestore()
      );

      await societyRef.collection('members').doc(guardId).set(
        MemberModel(
          id: guardId,
          societyId: societyRef.id,
          role: SocietyRole.guard,
          displayName: 'Guard Gary',
          status: MemberStatus.active,
          joinedAt: DateTime.now(),
        ).toFirestore()
      );

      // 7. Seed Assets
      setState(() => status = 'Seeding Assets...');
      final assets = [
        {'name': 'Main Backup Generator', 'category': 'machinery', 'loc': 'Basement B1', 'status': 'active'},
        {'name': 'Elevator Block A', 'category': 'machinery', 'loc': 'Block A', 'status': 'active'},
        {'name': 'Gym Equipment Set', 'category': 'gym', 'loc': 'Clubhouse L1', 'status': 'active'},
        {'name': 'Swimming Pool Filter', 'category': 'plumbing', 'loc': 'Pool Area', 'status': 'maintenanceNeeded'},
      ];

      for (var a in assets) {
        final assetRef = db.collection('assets').doc();
        await assetRef.set(AssetModel(
          id: assetRef.id,
          societyId: societyRef.id,
          name: a['name'] as String,
          category: a['category'] as String,
          location: a['loc'] as String,
          purchaseDate: DateTime.now().subtract(const Duration(days: 365)),
          cost: 5000.0,
          status: a['status'] as String,
          nextMaintenanceDate: DateTime.now().add(const Duration(days: 30)),
        ).toMap());
      }

      // 8. Seed Notices
      setState(() => status = 'Seeding Notices...');
      final notices = [
        {'title': 'Annual General Meeting', 'content': 'Please join us for the AGM this Sunday at 10 AM in the clubhouse.'},
        {'title': 'Water Maintenance Notice', 'content': 'Water supply will be suspended from 2 PM to 5 PM for tank cleaning.'},
        {'title': 'New Parking Rules', 'content': 'Visitors must park in the designated yellow zones starting next week.'},
      ];

      for (var n in notices) {
        await societyRef.collection('notices').add({
          'title': n['title'],
          'content': n['content'],
          'category': 'Announcement',
          'authorId': adminId,
          'authorName': 'Admin Alex',
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        });
      }

      // 9. Seed Invoices & Transactions
      setState(() => status = 'Seeding Financials...');
      final invoice1Ref = db.collection('invoices').doc();
      await invoice1Ref.set(InvoiceModel.create(
        id: invoice1Ref.id,
        societyId: societyRef.id,
        unitId: unitRef.id,
        propertyId: propRef.id,
        residentId: residentId,
        residentName: 'Resident Ryan',
        unitNumber: 'A-101',
        propertyName: 'Block A',
        lineItems: [InvoiceLineItem(description: 'Monthly Rent', category: InvoiceCategory.rent, amount: 3500.0)],
        billingMonth: '2026-04',
        issueDate: DateTime.now().subtract(const Duration(days: 40)),
        dueDate: DateTime.now().subtract(const Duration(days: 35)),
      ).copyWith(status: InvoiceStatus.paid, paidDate: DateTime.now().subtract(const Duration(days: 36))).toFirestore());

      // Create some past transactions
      for (int i = 1; i <= 5; i++) {
        await db.collection('rentRecords').add({
          'ownerId': adminId,
          'propertyId': propRef.id,
          'unitId': unitRef.id,
          'tenantId': residentId,
          'amount': 3500.0,
          'status': 'paid',
          'paymentDate': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 30 * i))),
          'month': '2026-0${5-i}',
          'description': 'Rent Payment',
        });
      }

      // 10. Seed Gate Logs
      setState(() => status = 'Seeding Gate Logs...');
      final logs = [
        {'name': 'John Doe', 'type': 'visitor', 'purpose': 'Guest', 'status': 'entered'},
        {'name': 'Zomato Delivery', 'type': 'delivery', 'purpose': 'Food', 'status': 'entered'},
        {'name': 'Uber - SF 1234', 'type': 'taxi', 'purpose': 'Pickup', 'status': 'exited'},
      ];

      for (var l in logs) {
        await societyRef.collection('gate_logs').add({
          'visitorName': l['name'],
          'visitorType': l['type'],
          'purpose': l['purpose'],
          'status': l['status'],
          'entryTime': FieldValue.serverTimestamp(),
          'unitNumber': 'A-101',
          'approvedBy': residentId,
        });
      }

      // 11. Seed Helpdesk Tickets
      await auth.signInWithEmailAndPassword(email: 'resident@example.com', password: 'password123');
      setState(() => status = 'Seeding Tickets...');
      final tickets = [
        {'title': 'Light flickering', 'desc': 'Hallway light outside A-101 is flickering.', 'cat': TicketCategory.electrical, 'status': TicketStatus.open},
        {'title': 'Tap Leakage', 'desc': 'Kitchen tap is leaking since morning.', 'cat': TicketCategory.plumbing, 'status': TicketStatus.resolved},
      ];

      for (var t in tickets) {
        final tRef = db.collection('tickets').doc();
        await tRef.set(TicketModel(
          id: tRef.id,
          societyId: societyRef.id,
          unitId: unitRef.id,
          residentId: residentId,
          residentName: 'Resident Ryan',
          unitNumber: 'A-101',
          title: t['title'] as String,
          description: t['desc'] as String,
          category: t['cat'] as TicketCategory,
          priority: TicketPriority.medium,
          status: t['status'] as TicketStatus,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ).toFirestore());
      }

      setState(() => status = 'RICH SETUP COMPLETE!\n\nadmin@example.com\nresident@example.com\nguard@example.com\n(Password: password123)');
      
      print('SETUP COMPLETE');
      await auth.signInWithEmailAndPassword(email: 'admin@example.com', password: 'password123');
      
      Future.delayed(const Duration(seconds: 5), () {
        if (!kIsWeb) exit(0);
      });

    } catch (e) {
      if(mounted) {
        setState(() => status = 'An error occurred: $e');
        print('SETUP ERROR: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Niyan Rich Demo Seeder')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
