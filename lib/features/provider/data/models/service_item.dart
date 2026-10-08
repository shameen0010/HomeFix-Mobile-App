import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../admin/data/models/model_utils.dart';

/// Firestore: providers/{uid}/services/{id}
class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.priceType,
    required this.durationMin,
    required this.durationMax,
    required this.isActive,
  });
  final String id, name, category, priceType; // priceType: hourly | fixed
  final double price;
  final int durationMin, durationMax;
  final bool isActive;

  String get priceLabel => priceType == 'hourly' ? 'base/hr' : 'fixed';
  String get durationLabel => durationMin == durationMax
      ? '$durationMin mins est.'
      : '$durationMin-$durationMax mins est.';

  factory ServiceItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return ServiceItem(
      id: doc.id,
      name: asString(d['name'], 'Service'),
      category: asString(d['category'], 'General'),
      price: asDouble(d['price']),
      priceType: asString(d['priceType'], 'fixed'),
      durationMin: asInt(d['durationMin']),
      durationMax: asInt(d['durationMax']),
      isActive: asBool(d['isActive'], true),
    );
  }
}
