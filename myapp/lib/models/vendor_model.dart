import 'package:cloud_firestore/cloud_firestore.dart';

enum VendorCategory {
  plumbing,
  electrical,
  carpentry,
  painting,
  housekeeping,
  security,
  landscaping,
  pest_control,
  elevator,
  generator,
  it_networking,
  other,
}

extension VendorCategoryLabel on VendorCategory {
  String get label {
    switch (this) {
      case VendorCategory.plumbing:        return 'Plumbing';
      case VendorCategory.electrical:      return 'Electrical';
      case VendorCategory.carpentry:       return 'Carpentry';
      case VendorCategory.painting:        return 'Painting';
      case VendorCategory.housekeeping:    return 'Housekeeping';
      case VendorCategory.security:        return 'Security';
      case VendorCategory.landscaping:     return 'Landscaping';
      case VendorCategory.pest_control:    return 'Pest Control';
      case VendorCategory.elevator:        return 'Elevator / Lift';
      case VendorCategory.generator:       return 'Generator / DG';
      case VendorCategory.it_networking:   return 'IT / Networking';
      case VendorCategory.other:           return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case VendorCategory.plumbing:        return '🔧';
      case VendorCategory.electrical:      return '⚡';
      case VendorCategory.carpentry:       return '🪚';
      case VendorCategory.painting:        return '🎨';
      case VendorCategory.housekeeping:    return '🧹';
      case VendorCategory.security:        return '🛡️';
      case VendorCategory.landscaping:     return '🌿';
      case VendorCategory.pest_control:    return '🐛';
      case VendorCategory.elevator:        return '🛗';
      case VendorCategory.generator:       return '⚙️';
      case VendorCategory.it_networking:   return '💻';
      case VendorCategory.other:           return '🏢';
    }
  }
}

/// A vendor / service provider used by the society.
class VendorModel {
  final String id;
  final String? societyId;    // null if shared across societies
  final String? ownerId;      // null in society mode
  final String name;
  final VendorCategory category;
  final String phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final String? panNumber;
  final double rating;        // 0.0–5.0, average of reviews
  final int totalJobs;
  final bool isActive;
  final String? notes;
  final String? logoUrl;
  final DateTime createdAt;

  VendorModel({
    required this.id,
    this.societyId,
    this.ownerId,
    required this.name,
    required this.category,
    required this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.panNumber,
    this.rating = 0.0,
    this.totalJobs = 0,
    this.isActive = true,
    this.notes,
    this.logoUrl,
    required this.createdAt,
  });

  factory VendorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VendorModel(
      id: doc.id,
      societyId: data['societyId'],
      ownerId: data['ownerId'],
      name: data['name'] ?? '',
      category: VendorCategory.values.firstWhere(
        (e) => e.toString() == data['category'],
        orElse: () => VendorCategory.other,
      ),
      phone: data['phone'] ?? '',
      email: data['email'],
      address: data['address'],
      gstNumber: data['gstNumber'],
      panNumber: data['panNumber'],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalJobs: (data['totalJobs'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] ?? true,
      notes: data['notes'],
      logoUrl: data['logoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'societyId': societyId,
      'ownerId': ownerId,
      'name': name,
      'category': category.toString(),
      'phone': phone,
      'email': email,
      'address': address,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'rating': rating,
      'totalJobs': totalJobs,
      'isActive': isActive,
      'notes': notes,
      'logoUrl': logoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  VendorModel copyWith({
    String? name,
    VendorCategory? category,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    String? panNumber,
    double? rating,
    int? totalJobs,
    bool? isActive,
    String? notes,
    String? logoUrl,
  }) {
    return VendorModel(
      id: id,
      societyId: societyId,
      ownerId: ownerId,
      name: name ?? this.name,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      rating: rating ?? this.rating,
      totalJobs: totalJobs ?? this.totalJobs,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt,
    );
  }
}
