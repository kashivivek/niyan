import 'package:cloud_firestore/cloud_firestore.dart';

enum PropertyType { flat, house, shop, pg }

class PropertyModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? imageUrl;
  final PropertyType type;
  final String ownerId;

  PropertyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.imageUrl,
    required this.type,
    required this.ownerId,
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
  }) {
    return PropertyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
