import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../admin/data/models/model_utils.dart';

/// Firestore: chats/{id}. id == bookingId, or "{customerId}_{providerId}" for
/// direct enquiries from Search. Same documents the provider module reads.
class CustomerThread {
  const CustomerThread({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.bookingNo,
    this.providerPhotoUrl,
    this.bookingId,
    this.lastMessage,
    this.lastAt,
  });
  final String id, providerId, providerName, bookingNo;
  final String? providerPhotoUrl, bookingId, lastMessage;
  final DateTime? lastAt;

  bool get isDirect => bookingId == null;

  factory CustomerThread.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return CustomerThread(
      id: doc.id,
      providerId: asString(d['providerId']),
      providerName: asString(d['providerName'], 'Service provider'),
      providerPhotoUrl: d['providerPhotoUrl'] as String?,
      bookingNo: asString(d['bookingNo'], 'direct'),
      bookingId: d['bookingId'] as String?,
      lastMessage: d['lastMessage'] as String?,
      lastAt: asDate(d['lastAt']),
    );
  }
}

class CustomerMessage {
  const CustomerMessage({required this.id, required this.senderId, required this.text, this.imageUrl, this.createdAt});
  final String id, senderId, text;
  final String? imageUrl;
  final DateTime? createdAt;

  factory CustomerMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return CustomerMessage(
      id: doc.id,
      senderId: asString(d['senderId']),
      text: asString(d['text']),
      imageUrl: d['imageUrl'] as String?,
      createdAt: asDate(d['createdAt']),
    );
  }
}
