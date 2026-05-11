import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:myapp/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _initialized = false;
  bool get initialized => _initialized;

  User? get currentUser => _auth.currentUser;

  Stream<UserModel?> get user {
    return _auth.authStateChanges().doOnData((_) => _initialized = true).switchMap((User? firebaseUser) {

      if (firebaseUser != null) {
        return _db
            .collection('users')
            .doc(firebaseUser.uid)
            .snapshots()
            .map((snapshot) {
          if (snapshot.exists) {
            return UserModel.fromFirestore(snapshot);
          } else {
            return UserModel(uid: firebaseUser.uid, email: firebaseUser.email);
          }
        });
      } else {
        return Stream.value(null);
      }
    });
  }

  UserModel? _userFromFirebaseUser(User? user) {
    return user != null ? UserModel(uid: user.uid, email: user.email) : null;
  }

  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required AppRole role,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      if (user != null) {
        // --- Automated Tenant Onboarding ---
        // Check if this email is already registered as a tenant in any society
        final tenantQuery = await _db.collection('tenants')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        String? autoSocietyId;
        bool isAutoResident = false;

        if (tenantQuery.docs.isNotEmpty) {
          final tenantData = tenantQuery.docs.first.data();
          final String? foundSocietyId = tenantData['societyId'] as String?;
          
          // Only auto-onboard if the tenant is associated with a society
          if (foundSocietyId != null) {
            autoSocietyId = foundSocietyId;
            isAutoResident = true;
            
            // 1. Add to society's member list
            await _db.collection('societies').doc(autoSocietyId).update({
              'memberIds': FieldValue.arrayUnion([user.uid])
            });

            // 2. Create the member record
            await _db.collection('societies').doc(autoSocietyId).collection('members').doc(user.uid).set({
              'id': user.uid,
              'societyId': autoSocietyId,
              'role': 'SocietyRole.tenant',
              'displayName': name,
              'status': 'MemberStatus.active',
              'joinedAt': FieldValue.serverTimestamp(),
              'unitIds': [tenantData['assignedUnitId']],
            });
          }
        }

        final userData = {
          'email': user.email,
          'name': name,
          'currentRole': isAutoResident ? AppRole.resident.toString() : role.toString(),
          'createdAt': FieldValue.serverTimestamp(),
          'societyIds': autoSocietyId != null ? [autoSocietyId] : [],
          'activeSocietyId': autoSocietyId,
          'activeMode': autoSocietyId != null ? 'society' : 'standalone',
          'notificationsEnabled': true,
        };

        await _db.collection('users').doc(user.uid).set(userData);
        return UserModel.fromFirestore(await _db.collection('users').doc(user.uid).get());
      }
      return null;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<UserModel?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      if (user != null) {
        // Create an initial empty user document in Firestore
        await _db.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return _userFromFirebaseUser(user);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      return await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint(e.toString());
      return;
    }
  }

  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      debugPrint(e.toString());
      return;
    }
  }

  /// Persist the user's active mode and active society ID to Firestore
  /// so it can be restored on any device at login.
  static Future<void> persistUserMode({
    required String uid,
    required String mode, // 'standalone' or 'society'
    String? activeSocietyId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'activeMode': mode,
        'activeSocietyId': activeSocietyId,
      });
    } catch (e) {
      debugPrint('persistUserMode error: $e');
    }
  }
}
