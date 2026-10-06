import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBookingModel {
  final String id;
  final String customerName;
  final String providerName;
  final String service;
  final String status;
  final num amount;
  final DateTime? scheduledAt;

  const AdminBookingModel({
    required this.id,
    this.customerName = 'Customer',
    this.providerName = 'Unassigned',
    this.service = 'Service',
    this.status = 'pending',
    this.amount = 0,
    this.scheduledAt,
  });

  factory AdminBookingModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final timestamp = data['scheduledAt'] ?? data['date'];
    return AdminBookingModel(
      id: doc.id,
      customerName: (data['customerName'] ?? data['userName'] ?? 'Customer')
          .toString(),
      providerName: (data['providerName'] ?? 'Unassigned').toString(),
      service: (data['service'] ?? data['category'] ?? 'Service').toString(),
      status: (data['status'] ?? 'pending').toString(),
      amount: data['amount'] is num ? data['amount'] as num : 0,
      scheduledAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
