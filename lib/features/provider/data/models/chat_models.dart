import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../admin/data/models/model_utils.dart';
import 'job_model.dart';

/// Firestore: chats/{bookingId}  (+ subcollection messages/{id})
class ChatThread {
  const ChatThread({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.bookingNo,
    this.customerPhotoUrl,
    this.lastMessage,
    this.lastAt,
    this.scheduledAt,
  });
  final String id, customerId, customerName, bookingNo;
  final String? customerPhotoUrl, lastMessage;
  final DateTime? lastAt, scheduledAt;

  factory ChatThread.fromJob(JobModel j) => ChatThread(
        id: j.id,
        customerId: j.customerId,
        customerName: j.customerName,
        customerPhotoUrl: j.customerPhotoUrl,
        bookingNo: j.bookingNo,
        scheduledAt: j.scheduledAt,
      );

  factory ChatThread.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return ChatThread(
      id: doc.id,
      customerId: asString(d['customerId']),
      customerName: asString(d['customerName'], 'Customer'),
      customerPhotoUrl: d['customerPhotoUrl'] as String?,
      bookingNo: asString(d['bookingNo'], shortId(doc.id)),
      lastMessage: d['lastMessage'] as String?,
      lastAt: asDate(d['lastAt']),
      scheduledAt: asDate(d['scheduledAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'customerName': customerName,
        'customerPhotoUrl': customerPhotoUrl,
        'bookingNo': bookingNo,
        'bookingId': id,
        if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt!),
      };
}

class ChatMessage {
  const ChatMessage({required this.id, required this.senderId, required this.text, this.imageUrl, this.createdAt});
  final String id, senderId, text;
  final String? imageUrl;
  final DateTime? createdAt;

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return ChatMessage(
      id: doc.id,
      senderId: asString(d['senderId']),
      text: asString(d['text']),
      imageUrl: d['imageUrl'] as String?,
      createdAt: asDate(d['createdAt']),
    );
  }
}
