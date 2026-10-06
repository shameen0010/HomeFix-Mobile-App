import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/hf_theme.dart';
import '../../../core/widgets/hf_widgets.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Upcoming', 'Active', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _emptyState(context, 'Please log in to view your bookings.');
    }

    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('customerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _emptyState(context, 'Unable to load your bookings.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs
              .where((document) => _bucket(_status(document.data())) == _selectedTab)
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const HfBrandMark(compact: true),
                    const Spacer(),
                    CircleAvatar(
                      backgroundColor: HfColors.primary,
                      radius: 20,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Bookings', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Manage your service bookings', style: TextStyle(color: HfColors.muted, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tabs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: HfPill(
                        label: _tabs[index],
                        selected: _selectedTab == index,
                        onTap: () => setState(() => _selectedTab = index),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (bookings.isEmpty)
                      _emptyState(context, 'No bookings yet', showAction: true)
                    else
                      for (final booking in bookings) _bookingCard(context, booking),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bookingCard(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final status = _status(data);
    final statusLabel = _statusLabel(status);
    final service = (data['serviceTitle'] ?? data['serviceType'] ?? data['service'] ?? 'Home service').toString();
    final provider = (data['providerName'] ?? 'Provider pending').toString();
    final amount = _number(data['totalPrice'] ?? data['amount']);
    final scheduled = _dateLabel(data['scheduledDate'] ?? data['scheduledAt']);

    return HfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: HfColors.primarySoft,
                radius: 28,
                child: const Icon(Icons.home_repair_service_outlined, color: HfColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(provider, style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              HfBadge(label: statusLabel, tone: BadgeTone.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: HfColors.muted),
              const SizedBox(width: 4),
              Text(scheduled, style: const TextStyle(fontSize: 12, color: HfColors.muted)),
              const Spacer(),
              Text('Rs. ${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HfSoftButton(
                  label: 'View Details',
                  onPressed: () => context.push('/booking-checkout/${document.id}'),
                ),
              ),
              if (status == 'pending' || status == 'accepted' || status == 'confirmed') ...[
                const SizedBox(width: 8),
                HfSoftButton(
                  label: 'Cancel',
                  color: HfColors.danger.withValues(alpha: 0.1),
                  foreground: HfColors.danger,
                  onPressed: () => context.push('/cancel-booking/${document.id}'),
                ),
              ],
            ],
          ),
          if (status == 'in_progress' || status == 'started' || status == 'scheduled' || status == 'en_route') ...[
            const SizedBox(height: 8),
            HfPrimaryButton(
              label: 'Track Status',
              onPressed: () => context.push('/booking-checkout/${document.id}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, String message, {bool showAction = false}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 64, color: HfColors.muted),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          if (showAction) ...[
            const SizedBox(height: 8),
            const Text('Book your first service to get started', style: TextStyle(color: HfColors.muted)),
            const SizedBox(height: 16),
            HfPrimaryButton(label: 'Book a Service', onPressed: () => context.go('/c/search')),
          ],
        ],
      ),
    );
  }

  String _status(Map<String, dynamic> data) => (data['status'] ?? 'pending').toString().toLowerCase();

  int _bucket(String status) {
    switch (status) {
      case 'completed':
        return 2;
      case 'cancelled':
        return 3;
      case 'accepted':
      case 'confirmed':
      case 'en_route':
      case 'in_progress':
      case 'started':
      case 'scheduled':
        return 1;
      default:
        return 0;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'ACCEPTED';
      case 'confirmed':
        return 'CONFIRMED';
      case 'scheduled':
        return 'SCHEDULED';
      case 'en_route':
        return 'EN ROUTE';
      case 'in_progress':
      case 'started':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return 'PENDING';
    }
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _dateLabel(dynamic value) {
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }
    if (date == null) return 'Schedule not set';
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day}/${date.month}/${date.year} • $hour:$minute $period';
  }
}
