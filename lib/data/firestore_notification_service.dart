import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreNotificationService {
  FirestoreNotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> notifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> create({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? bookingId,
  }) {
    return _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'bookingId': bookingId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markRead(String notificationId) {
    return _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }
}
