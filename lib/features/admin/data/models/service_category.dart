import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_utils.dart';

/// Firestore: categories/{id}
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.servicesCount,
    required this.prosCount,
    required this.isActive,
    required this.order,
  });
  final String id, name, icon;
  final int servicesCount, prosCount, order;
  final bool isActive;

  factory ServiceCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return ServiceCategory(
      id: doc.id,
      name: asString(d['name'], 'Untitled'),
      icon: asString(d['icon'], 'other'),
      servicesCount: asInt(d['servicesCount']),
      prosCount: asInt(d['prosCount']),
      isActive: asBool(d['isActive'], true),
      order: asInt(d['order']),
    );
  }
}
