import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_utils.dart';

/// Firestore: bookings/{id}
/// status: pending | confirmed | in_progress | completed | cancelled
class BookingModel {
  const BookingModel({
    required this.id,
    required this.bookingNo,
    required this.title,
    required this.category,
    required this.customerId,
    required this.customerName,
    required this.address,
    required this.status,
    required this.isEmergency,
    required this.amount,
    this.providerId,
    this.providerName,
    this.rating,
    this.cancelReason,
    this.notes,
    this.scheduledAt,
    this.createdAt,
  });

  final String id, bookingNo, title, category, customerId, customerName, address, status;
  final bool isEmergency;
  final double amount;
  final String? providerId, providerName, cancelReason, notes;
  final double? rating;
  final DateTime? scheduledAt, createdAt;

  String get code => '#BK-$bookingNo';
  bool get isActive =>
      status == 'pending' || status == 'confirmed' || status == 'in_progress';
  bool get hasProvider => (providerId ?? '').isNotEmpty;
  DateTime? get date => createdAt ?? scheduledAt;

  factory BookingModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return BookingModel(
      id: doc.id,
      bookingNo: asString(d['bookingNo'], shortId(doc.id)),
      title: asString(d['title'], asString(d['service'], 'Service request')),
      category: asString(d['category'], 'General'),
      customerId: asString(d['customerId']),
      customerName: asString(d['customerName'], 'Customer'),
      providerId: d['providerId'] as String?,
      providerName: d['providerName'] as String?,
      address: asString(d['address'], '-'),
      status: asString(d['status'], 'pending'),
      isEmergency: asBool(d['isEmergency']),
      amount: asDouble(d['amount']),
      rating: d['rating'] is num ? (d['rating'] as num).toDouble() : null,
      cancelReason: d['cancelReason'] as String?,
      notes: d['notes'] as String?,
      scheduledAt: asDate(d['scheduledAt']),
      createdAt: asDate(d['createdAt']),
    );
  }
}
