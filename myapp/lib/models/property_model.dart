import 'package:cloud_firestore/cloud_firestore.dart';

enum PropertyType { flat, house, shop, pg }

class MaintenanceContact {
  final String name;
  final String category;
  final String phone;

  MaintenanceContact({
    required this.name,
    required this.category,
    required this.phone,
  });

  factory MaintenanceContact.fromMap(Map<String, dynamic> map) {
    return MaintenanceContact(
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'phone': phone,
    };
  }
}

class PropertyModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? imageUrl;
  final PropertyType type;
  final String ownerId;
  final List<MaintenanceContact> maintenanceContacts;

  PropertyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.imageUrl,
    required this.type,
    required this.ownerId,
    this.maintenanceContacts = const [],
  });

  factory PropertyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      imageUrl: data['imageUrl'],
      type: PropertyType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => PropertyType.flat,
      ),
      ownerId: data['ownerId'] ?? '',
      maintenanceContacts: (data['maintenanceContacts'] as List? ?? [])
          .map((item) => MaintenanceContact.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'imageUrl': imageUrl,
      'type': type.toString(),
      'ownerId': ownerId,
      'maintenanceContacts': maintenanceContacts.map((c) => c.toMap()).toList(),
    };
  }

  PropertyModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? imageUrl,
    PropertyType? type,
    String? ownerId,
    List<MaintenanceContact>? maintenanceContacts,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      maintenanceContacts: maintenanceContacts ?? this.maintenanceContacts,
    );
  }
}
