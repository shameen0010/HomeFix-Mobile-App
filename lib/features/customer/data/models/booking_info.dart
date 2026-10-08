import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../admin/data/models/model_utils.dart';

class ProofPhoto {
  const ProofPhoto({required this.url, required this.label});
  final String url, label;
}

/// Customer-side view of bookings/{id}.
class BookingInfo {
  const BookingInfo({
    required this.id,
    required this.bookingNo,
    required this.title,
    required this.category,
    required this.customerId,
    required this.customerName,
    required this.providerId,
    required this.providerName,
    required this.address,
    required this.status,
    required this.stage,
    required this.amount,
    required this.isEmergency,
    required this.providerConfirmed,
    required this.customerAttested,
    required this.reviewed,
    required this.photos,
    this.scheduledAt,
    this.completedAt,
    this.finishedAt,
    this.customerAttestedAt,
    this.cancelReason,
  });

  final String id, bookingNo, title, category, customerId, customerName, providerId, providerName, address, status, stage;
  final double amount;
  final bool isEmergency, providerConfirmed, customerAttested, reviewed;
  final List<ProofPhoto> photos;
  final DateTime? scheduledAt, completedAt, finishedAt, customerAttestedAt;
  final String? cancelReason;

  String get code => '#HF-$bookingNo';
  bool get isActive => status == 'pending' || status == 'confirmed' || status == 'in_progress';
  bool get jobDone => stage == 'done' || status == 'completed';
  bool get hasProvider => providerId.isNotEmpty;

  String get stageLabel {
    switch (stage) {
      case 'arrived':
        return 'ARRIVED';
      case 'working':
        return 'WORKING';
      case 'done':
        return 'FINISHED';
      default:
        return 'EN ROUTE';
    }
  }

  factory BookingInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return BookingInfo(
      id: doc.id,
      bookingNo: asString(d['bookingNo'], shortId(doc.id)),
      title: asString(d['title'], asString(d['service'], 'Service request')),
      category: asString(d['category'], 'General'),
      customerId: asString(d['customerId']),
      customerName: asString(d['customerName'], 'Customer'),
      providerId: asString(d['providerId']),
      providerName: asString(d['providerName'], 'Unassigned'),
      address: asString(d['address'], '-'),
      status: asString(d['status'], 'pending'),
      stage: asString(d['stage'], 'en_route'),
      amount: asDouble(d['amount']),
      isEmergency: asBool(d['isEmergency']),
      providerConfirmed: asBool(d['receiptConfirmed']),
      customerAttested: asBool(d['customerAttested']),
      reviewed: asBool(d['reviewed']),
      photos: (d['photos'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => ProofPhoto(url: asString(m['url']), label: asString(m['label'], 'Photo')))
          .toList(),
      scheduledAt: asDate(d['scheduledAt']),
      completedAt: asDate(d['completedAt']),
      finishedAt: asDate(d['finishedAt']),
      customerAttestedAt: asDate(d['customerAttestedAt']),
      cancelReason: d['cancelReason'] as String?,
    );
  }
}
