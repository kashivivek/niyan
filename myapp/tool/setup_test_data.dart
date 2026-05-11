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
import 'package:myapp/models/tenant_model.dart';

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
      'activeMode': 'society',
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
    setState(() => status = 'Creating Rich Demo Data...');

    try {
      final societyId = 'test_society_zillow'; 
      
      // 1. Create Society with all member IDs pre-populated
      setState(() => status = 'Seeding Society...');
      final memberEmails = [
        'admin@example.com',
        'manager@example.com',
        'owner@example.com',
        'resident@example.com',
        'guard@example.com'
      ];
      
      // We'll map these to UIDs after creation
      Map<String, String> emailToUid = {};

      for (var email in memberEmails) {
        final name = email.split('@')[0].toUpperCase();
        AppRole role = AppRole.resident;
        if (email.contains('admin')) role = AppRole.societyAdmin;
        if (email.contains('manager')) role = AppRole.societyAdmin; // Mapping to global role
        if (email.contains('guard')) role = AppRole.guard;
        if (email.contains('owner')) role = AppRole.owner;

        final cred = await _getOrCreateUser(email, 'password123', name, role, societyId);
        emailToUid[email] = cred.user!.uid;
      }

      final adminId = emailToUid['admin@example.com']!;
      final managerId = emailToUid['manager@example.com']!;
      final ownerId = emailToUid['owner@example.com']!;
      final residentId = emailToUid['resident@example.com']!;
      final guardId = emailToUid['guard@example.com']!;

      final societyRef = db.collection('societies').doc(societyId);
      final society = SocietyModel(
        id: societyId,
        name: 'The Zillow Residences',
        address: '100 Silicon Valley Way',
        city: 'San Francisco',
        createdBy: adminId,
        createdAt: DateTime.now(),
        memberIds: emailToUid.values.toList(),
        settings: const SocietySettings(
          currency: 'USD',
          lateFeeFlat: 50.0,
          gracePeriodDays: 5,
        ),
      );
      await societyRef.set(society.toFirestore());

      // 2. Assign Society Roles (Members subcollection)
      setState(() => status = 'Assigning Society Roles...');
      final members = {
        adminId: SocietyRole.admin,
        managerId: SocietyRole.committee,
        ownerId: SocietyRole.owner,
        residentId: SocietyRole.tenant,
        guardId: SocietyRole.guard,
      };

      for (var entry in members.entries) {
        await societyRef.collection('members').doc(entry.key).set(
          MemberModel(
            id: entry.key,
            societyId: societyId,
            role: entry.value,
            displayName: memberEmails.firstWhere((e) => emailToUid[e] == entry.key).split('@')[0].toUpperCase(),
            status: MemberStatus.active,
            joinedAt: DateTime.now(),
          ).toFirestore()
        );
      }

      // 3. Create Properties and Units
      setState(() => status = 'Creating Blocks & Units...');
      
      // Block A (Managed by Society Admin)
      final blockA = PropertyModel(
        id: 'block_a',
        name: 'Block A',
        address: '100 Silicon Valley Way',
        ownerId: adminId,
        societyId: societyId,
        city: 'San Francisco',
        type: PropertyType.flat,
      );
      await db.collection('properties').doc(blockA.id).set(blockA.toFirestore());

      // Block B (Owned by a specific Unit Owner)
      final blockB = PropertyModel(
        id: 'block_b',
        name: 'Block B (Private)',
        address: '102 Silicon Valley Way',
        ownerId: ownerId,
        societyId: societyId,
        city: 'San Francisco',
        type: PropertyType.house,
      );
      await db.collection('properties').doc(blockB.id).set(blockB.toFirestore());

      // Units for Block A
      final unitA1 = UnitModel(
        id: 'a101',
        propertyId: blockA.id,
        ownerId: adminId,
        societyId: societyId,
        unitNumber: 'A-101',
        monthlyRent: 3500.0,
        rentDueDate: 5,
        status: 'occupied',
        sqft: 1200, bedrooms: 2, bathrooms: 2,
        currentTenantId: residentId,
      );
      await db.collection('properties').doc(blockA.id).collection('units').doc(unitA1.id).set(unitA1.toFirestore());

      // Units for Block B (Owned by Unit Owner)
      final unitB1 = UnitModel(
        id: 'b101',
        propertyId: blockB.id,
        ownerId: ownerId,
        societyId: societyId,
        unitNumber: 'B-101',
        monthlyRent: 4500.0,
        rentDueDate: 1,
        status: 'occupied',
        sqft: 2000, bedrooms: 3, bathrooms: 3,
        currentTenantId: 'external_tenant_id',
      );
      await db.collection('properties').doc(blockB.id).collection('units').doc(unitB1.id).set(unitB1.toFirestore());

      // 4. Seed Tenants
      setState(() => status = 'Seeding Tenants...');
      await db.collection('tenants').doc(residentId).set(TenantModel(
        id: residentId,
        name: 'Resident Ryan',
        email: 'resident@example.com',
        ownerId: adminId,
        societyId: societyId,
        propertyId: blockA.id,
        assignedUnitId: unitA1.id,
        isAssignedToUnit: true,
        dueDate: DateTime.now(),
        moveInDate: DateTime.now().subtract(const Duration(days: 90)),
      ).toFirestore());

      // 5. Seed Assets
      setState(() => status = 'Seeding Community Assets...');
      final assets = [
        {'name': 'Main Backup Generator', 'category': 'machinery', 'loc': 'Basement B1', 'status': 'active'},
        {'name': 'Elevator Block A', 'category': 'machinery', 'loc': 'Block A', 'status': 'active'},
        {'name': 'Gym Equipment Set', 'category': 'gym', 'loc': 'Clubhouse L1', 'status': 'active'},
      ];

      for (var a in assets) {
        final assetRef = db.collection('assets').doc();
        await assetRef.set(AssetModel(
          id: assetRef.id,
          societyId: societyId,
          name: a['name'] as String,
          category: a['category'] as String,
          location: a['loc'] as String,
          purchaseDate: DateTime.now().subtract(const Duration(days: 365)),
          cost: 5000.0,
          status: a['status'] as String,
          nextMaintenanceDate: DateTime.now().add(const Duration(days: 30)),
        ).toMap());
      }

      // 6. Seed Community Posts
      setState(() => status = 'Seeding Community Forum...');
      final post1Ref = db.collection('communityPosts').doc();
      await post1Ref.set({
        'societyId': societyId,
        'authorId': adminId,
        'authorName': 'ADMIN',
        'authorAvatar': null,
        'caption': 'Welcome to the Zillow Residences! Please use this forum to connect with your neighbors, share updates, and help each other out. Happy living! 🏡✨',
        'imageUrl': 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&q=80&w=1000',
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [ownerId, residentId],
        'commentCount': 1,
      });

      await db.collection('postComments').add({
        'postId': post1Ref.id,
        'authorId': residentId,
        'authorName': 'RESIDENT',
        'text': 'Thank you! Excited to be here.',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final post2Ref = db.collection('communityPosts').doc();
      await post2Ref.set({
        'societyId': societyId,
        'authorId': residentId,
        'authorName': 'RESIDENT',
        'authorAvatar': null,
        'caption': 'Has anyone found a set of keys near the Block A parking? Please let me know!',
        'imageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'commentCount': 0,
      });

      setState(() => status = 'RICH SETUP COMPLETE!\n\nadmin@example.com\nmanager@example.com\nowner@example.com\nresident@example.com\nguard@example.com\n(Password: password123)');
      
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
