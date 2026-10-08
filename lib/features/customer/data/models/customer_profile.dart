import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../admin/data/models/model_utils.dart';

/// Firestore: users/{uid} (role == 'customer')
class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.alertsEnabled,
    required this.gateCode,
    required this.petSafety,
    required this.secondaryPhone,
    required this.extraNotes,
    this.photoUrl,
  });
  final String id, name, email, phone, location, gateCode, petSafety, secondaryPhone, extraNotes;
  final bool alertsEnabled;
  final String? photoUrl;

  String get firstName => name.trim().split(' ').first;

  factory CustomerProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final e = d['emergencyInfo'] is Map ? Map<String, dynamic>.from(d['emergencyInfo'] as Map) : <String, dynamic>{};
    return CustomerProfile(
      id: doc.id,
      name: asString(d['name'], 'Customer'),
      email: asString(d['email']),
      phone: asString(d['phone'], '-'),
      location: asString(d['location']),
      alertsEnabled: asBool(d['alertsEnabled'], true),
      gateCode: asString(e['gateCode']),
      petSafety: asString(e['petSafety']),
      secondaryPhone: asString(e['secondaryPhone']),
      extraNotes: asString(e['notes']),
      photoUrl: d['photoUrl'] as String?,
    );
  }
}

/// Firestore: users/{uid}/addresses/{id}
class SavedAddress {
  const SavedAddress({required this.id, required this.label, required this.address, required this.isDefault});
  final String id, label, address;
  final bool isDefault;

  factory SavedAddress.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return SavedAddress(
      id: doc.id,
      label: asString(d['label'], 'Home'),
      address: asString(d['address']),
      isDefault: asBool(d['isDefault']),
    );
  }
}

/// Firestore: featured_services/{id} (Home "Popular Services" cards)
class FeaturedService {
  const FeaturedService({required this.id, required this.title, required this.subtitle, required this.category, this.imageUrl});
  final String id, title, subtitle, category;
  final String? imageUrl;

  factory FeaturedService.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return FeaturedService(
      id: doc.id,
      title: asString(d['title'], 'Service'),
      subtitle: asString(d['subtitle']),
      category: asString(d['category']),
      imageUrl: d['imageUrl'] as String?,
    );
  }
}
