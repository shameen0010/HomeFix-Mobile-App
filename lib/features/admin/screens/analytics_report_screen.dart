import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/admin_kpi_card.dart';
import 'admin_dashboard_screen.dart';

class AnalyticsReportScreen extends StatelessWidget {
  const AnalyticsReportScreen({super.key});
  @override
  Widget build(BuildContext context) => adminPage(
    'Analytics reports',
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final completed = docs
            .where(
              (d) =>
                  (d.data()['status'] ?? '').toString().toLowerCase() ==
                  'completed',
            )
            .length;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminKpiCard(
              label: 'Total bookings',
              value: '${docs.length}',
              icon: Icons.calendar_month,
            ),
            AdminKpiCard(
              label: 'Completed bookings',
              value: '$completed',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text('Live metrics update from Firestore.'),
          ],
        );
      },
    ),
  );
}
