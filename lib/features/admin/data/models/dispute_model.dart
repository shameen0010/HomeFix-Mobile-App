import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_utils.dart';

/// Firestore: disputes/{id}
/// type: complaint | review ; status: pending | under_review | resolved | archived
class DisputeModel {
  const DisputeModel({
    required this.id,
    required this.type,
    required this.status,
    required this.bookingNo,
    required this.customerName,
    required this.providerName,
    required this.service,
    required this.comment,
    this.rating,
    this.resolution,
    this.createdAt,
  });

  final String id, type, status, bookingNo, customerName, providerName, service, comment;
  final double? rating;
  final String? resolution;
  final DateTime? createdAt;

  bool get isReview => type == 'review';
  String get title => isReview ? 'Negative Review' : 'Dispute / Complaint';

  factory DisputeModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return DisputeModel(
      id: doc.id,
      type: asString(d['type'], 'complaint'),
      status: asString(d['status'], 'pending'),
      bookingNo: asString(d['bookingNo'], shortId(doc.id)),
      customerName: asString(d['customerName'], 'Customer'),
      providerName: asString(d['providerName'], 'Provider'),
      service: asString(d['service'], '-'),
      comment: asString(d['comment']),
      rating: d['rating'] is num ? (d['rating'] as num).toDouble() : null,
      resolution: d['resolution'] as String?,
      createdAt: asDate(d['createdAt']),
    );
  }
}
