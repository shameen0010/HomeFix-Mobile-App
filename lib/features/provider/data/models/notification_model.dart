import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../admin/data/models/model_utils.dart';

/// Firestore: notifications/{id}  (userId == recipient uid)
/// type: urgent | booking | payment | review | message | system
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    this.jobId,
    this.createdAt,
  });
  final String id, type, title, body;
  final bool read;
  final String? jobId;
  final DateTime? createdAt;

  bool get isBooking => type == 'urgent' || type == 'booking' || type == 'payment';

  factory NotificationModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return NotificationModel(
      id: doc.id,
      type: asString(d['type'], 'system'),
      title: asString(d['title'], 'Notification'),
      body: asString(d['body']),
      read: asBool(d['read']),
      jobId: d['jobId'] as String?,
      createdAt: asDate(d['createdAt']),
    );
  }
}
