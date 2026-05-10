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
        await _db.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': name,
          'currentRole': role.toString(),
          'createdAt': FieldValue.serverTimestamp(),
          'societyIds': [],
          'notificationsEnabled': true,
        });
        return UserModel(uid: user.uid, email: user.email, name: name, currentRole: role);
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
}
