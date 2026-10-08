import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../admin/data/models/model_utils.dart';

/// Firestore: reviews/{id}  (providerId == provider uid)
class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.service,
    required this.comment,
    required this.verified,
    this.photoUrl,
    this.createdAt,
    this.replyText,
  });
  final String id, customerName, service, comment;
  final double rating;
  final bool verified;
  final String? photoUrl, replyText;
  final DateTime? createdAt;

  factory ReviewModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final reply = d['reply'];
    return ReviewModel(
      id: doc.id,
      customerName: asString(d['customerName'], 'Customer'),
      rating: asDouble(d['rating']),
      service: asString(d['service']),
      comment: asString(d['comment']),
      verified: asBool(d['verified'], true),
      photoUrl: d['customerPhotoUrl'] as String?,
      createdAt: asDate(d['createdAt']),
      replyText: reply is Map ? reply['text'] as String? : null,
    );
  }
}
