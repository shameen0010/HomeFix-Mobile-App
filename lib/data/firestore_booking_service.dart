import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreBookingService {
  FirestoreBookingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('bookings');

  Future<String> createBooking({
    required String customerId,
    required String customerName,
    required String providerId,
    required String providerName,
    required String serviceTitle,
    required DateTime scheduledAt,
    required double amount,
    String? address,
    String? notes,
    String? contactPhone,
  }) async {
    final reference = _bookings.doc();
    await reference.set({
      'customerId': customerId,
      'customerName': customerName,
      'providerId': providerId,
      'providerName': providerName,
      'service': serviceTitle,
      'serviceTitle': serviceTitle,
      'serviceType': serviceTitle,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'scheduledDate': Timestamp.fromDate(scheduledAt),
      'amount': amount,
      'totalPrice': amount,
      'paymentMethod': 'Cash on Completion',
      'address': address,
      'notes': notes,
      'contactPhone': contactPhone,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> providerRequests(
    String providerId,
  ) {
    return _bookings
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> updateStatus(String bookingId, String status) {
    return _updateStatusWithNotification(bookingId, status);
  }

  Future<void> _updateStatusWithNotification(String bookingId, String status) async {
    final booking = await _bookings.doc(bookingId).get();
    if (booking.data() == null) throw StateError('Booking not found.');
    await booking.reference.update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
