import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? name;
  final String? photoUrl;
  final String? phone;
  final String plan;
  final String currency;
  final bool notificationsEnabled;
  final String notificationTime;
  final String notificationFrequency;

  UserModel({
    required this.uid,
    this.email,
    this.name,
    this.photoUrl,
    this.phone,
    this.plan = 'free',
    this.currency = 'USD',
    this.notificationsEnabled = false,
    this.notificationTime = '09:00',
    this.notificationFrequency = 'Daily',
  });

  factory UserModel.fromFirebaseAuthUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      name: user.displayName,
      photoUrl: user.photoURL,
      phone: user.phoneNumber,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'],
      name: data['name'],
      photoUrl: data['photoUrl'],
      phone: data['phone'],
      plan: data['plan'] ?? 'free',
      currency: data['currency'] ?? 'USD',
      notificationsEnabled: data['notificationsEnabled'] ?? false,
      notificationTime: data['notificationTime'] ?? '09:00',
      notificationFrequency: data['notificationFrequency'] ?? 'Daily',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'phone': phone,
      'plan': plan,
      'currency': currency,
      'notificationsEnabled': notificationsEnabled,
      'notificationTime': notificationTime,
      'notificationFrequency': notificationFrequency,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? plan,
    String? currency,
    bool? notificationsEnabled,
    String? notificationTime,
    String? notificationFrequency,
  }) {
    return UserModel(
      uid: uid,
      photoUrl: photoUrl,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      plan: plan ?? this.plan,
      currency: currency ?? this.currency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      notificationFrequency: notificationFrequency ?? this.notificationFrequency,
    );
  }
}
