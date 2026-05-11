import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a society/community/apartment complex in the ERP.
/// This is the top-level organizational unit that groups properties,
/// members, and all operational data.
class SocietyModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? state;
  final String? pincode;
  final String? logoUrl;
  final String createdBy; // userId of the creator (becomes super admin)
  final DateTime createdAt;
  final List<String> memberIds;
  final SocietySettings settings;

  SocietyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.state,
    this.pincode,
    this.logoUrl,
    required this.createdBy,
    required this.createdAt,
    this.memberIds = const [],
    this.settings = const SocietySettings(),
  });

  factory SocietyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocietyModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'],
      pincode: data['pincode'],
      logoUrl: data['logoUrl'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      settings: data['settings'] != null
          ? SocietySettings.fromMap(data['settings'] as Map<String, dynamic>)
          : const SocietySettings(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'logoUrl': logoUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'memberIds': memberIds,
      'settings': settings.toMap(),
    };
  }

  SocietyModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? logoUrl,
    String? createdBy,
    DateTime? createdAt,
    List<String>? memberIds,
    SocietySettings? settings,
  }) {
    return SocietyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      logoUrl: logoUrl ?? this.logoUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      memberIds: memberIds ?? this.memberIds,
      settings: settings ?? this.settings,
    );
  }
}

/// Society-wide configuration for billing, compliance, and preferences.
class SocietySettings {
  final String currency;
  final String billingCycle; // 'monthly', 'quarterly', 'annually'
  final bool gstEnabled;
  final String? gstNumber;
  final double? gstRate; // e.g. 18.0
  final double? maintenanceThreshold; // e.g. 7500 — above this, GST applies
  final bool tdsEnabled;
  final String? panNumber;
  final int defaultDueDay; // day of month rent/maintenance is due
  final int gracePeriodDays; // days after due date before late fee
   final double? lateFeePercent;
   final double? lateFeeFlat;
   final bool lateFeeEnabled;
   final bool autoGenerateInvoices;

   const SocietySettings({
     this.currency = 'INR',
     this.billingCycle = 'monthly',
     this.gstEnabled = false,
     this.gstNumber,
     this.gstRate,
     this.maintenanceThreshold,
     this.tdsEnabled = false,
     this.panNumber,
     this.defaultDueDay = 1,
     this.gracePeriodDays = 7,
     this.lateFeePercent,
     this.lateFeeFlat,
     this.lateFeeEnabled = true,
     this.autoGenerateInvoices = true,
   });

  factory SocietySettings.fromMap(Map<String, dynamic> data) {
    return SocietySettings(
      currency: data['currency'] ?? 'INR',
      billingCycle: data['billingCycle'] ?? 'monthly',
      gstEnabled: data['gstEnabled'] ?? false,
      gstNumber: data['gstNumber'],
      gstRate: (data['gstRate'] as num?)?.toDouble(),
      maintenanceThreshold: (data['maintenanceThreshold'] as num?)?.toDouble(),
      tdsEnabled: data['tdsEnabled'] ?? false,
      panNumber: data['panNumber'],
      defaultDueDay: (data['defaultDueDay'] as num?)?.toInt() ?? 1,
      gracePeriodDays: (data['gracePeriodDays'] as num?)?.toInt() ?? 7,
      lateFeePercent: (data['lateFeePercent'] as num?)?.toDouble(),
      lateFeeFlat: (data['lateFeeFlat'] as num?)?.toDouble(),
      lateFeeEnabled: data['lateFeeEnabled'] ?? true,
      autoGenerateInvoices: data['autoGenerateInvoices'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currency': currency,
      'billingCycle': billingCycle,
      'gstEnabled': gstEnabled,
      'gstNumber': gstNumber,
      'gstRate': gstRate,
      'maintenanceThreshold': maintenanceThreshold,
      'tdsEnabled': tdsEnabled,
      'panNumber': panNumber,
      'defaultDueDay': defaultDueDay,
      'gracePeriodDays': gracePeriodDays,
      'lateFeePercent': lateFeePercent,
      'lateFeeFlat': lateFeeFlat,
      'lateFeeEnabled': lateFeeEnabled,
      'autoGenerateInvoices': autoGenerateInvoices,
    };
  }

  SocietySettings copyWith({
    String? currency,
    String? billingCycle,
    bool? gstEnabled,
    String? gstNumber,
    double? gstRate,
    double? maintenanceThreshold,
    bool? tdsEnabled,
    String? panNumber,
    int? defaultDueDay,
    int? gracePeriodDays,
    double? lateFeePercent,
    double? lateFeeFlat,
    bool? lateFeeEnabled,
    bool? autoGenerateInvoices,
  }) {
    return SocietySettings(
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      gstEnabled: gstEnabled ?? this.gstEnabled,
      gstNumber: gstNumber ?? this.gstNumber,
      gstRate: gstRate ?? this.gstRate,
      maintenanceThreshold: maintenanceThreshold ?? this.maintenanceThreshold,
      tdsEnabled: tdsEnabled ?? this.tdsEnabled,
      panNumber: panNumber ?? this.panNumber,
      defaultDueDay: defaultDueDay ?? this.defaultDueDay,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      lateFeePercent: lateFeePercent ?? this.lateFeePercent,
      lateFeeFlat: lateFeeFlat ?? this.lateFeeFlat,
      lateFeeEnabled: lateFeeEnabled ?? this.lateFeeEnabled,
      autoGenerateInvoices: autoGenerateInvoices ?? this.autoGenerateInvoices,
    );
  }
}
