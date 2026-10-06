import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/admin_booking_model.dart';
import '../widgets/status_badge_chip.dart';
import 'admin_dashboard_screen.dart';

class BookingMonitoringScreen extends StatelessWidget {
  const BookingMonitoringScreen({super.key});
  @override
  Widget build(BuildContext context) => adminPage(
    'Booking monitoring',
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('scheduledAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Text('Unable to load bookings: ${snapshot.error}'),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return ListView(
          padding: const EdgeInsets.all(12),
          children: snapshot.data!.docs.map((doc) {
            final booking = AdminBookingModel.fromDocument(doc);
            return Card(
              child: ListTile(
                title: Text(booking.service),
                subtitle: Text(
                  '${booking.customerName} • ${booking.providerName}',
                ),
                trailing: StatusBadgeChip(status: booking.status),
              ),
            );
          }).toList(),
        );
      },
    ),
  );
}
