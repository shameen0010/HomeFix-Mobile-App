import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/customer_header.dart';
import 'booking_tracking_screen.dart';
import 'cancel_booking_screen.dart';

/// Shown right after a booking is created (FR-B05).
class BookingSuccessScreen extends StatefulWidget {
  const BookingSuccessScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  late final Stream<BookingInfo?> _stream = CustomerRepository.instance.watchBooking(widget.bookingId);

  String _status(BookingInfo b) {
    switch (b.status) {
      case 'confirmed':
        return 'Provider accepted your booking';
      case 'in_progress':
        return 'Your provider is on the job';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return b.hasProvider ? 'Pending Provider Acceptance' : 'Finding another provider';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Customer Status', showBack: true),
        Expanded(
          child: StreamBuilder<BookingInfo?>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load this booking.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final b = snap.data;
              if (b == null) return const EmptyView(message: 'Booking not found', icon: Icons.search_off_rounded);
              final (_, tone) = bookingChip(b);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: [
                  Center(
                    child: Stack(clipBehavior: Clip.none, children: [
                      const CircleAvatar(
                          radius: 38, backgroundColor: AdminColors.primary,
                          child: Icon(Icons.check_rounded, color: Colors.white, size: 42)),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AdminColors.orange, shape: BoxShape.circle),
                          child: const Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Center(child: Text('Booking Submitted!', style: ts(24, w: FontWeight.w700))),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(20)),
                      child: Text('BOOKING ID  ${b.code}',
                          style: ts(11, w: FontWeight.w700, color: AdminColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Relax, your home is in safe hands. We\'re connecting you with an expert now.',
                      textAlign: TextAlign.center, style: ts(12.5, height: 1.45, color: AdminColors.grey)),
                  const SizedBox(height: 18),
                  AdminCard(
                    child: Row(children: [
                      Icon(Icons.circle, size: 10,
                          color: tone == Tone.green ? AdminColors.green : (tone == Tone.red ? AdminColors.red : AdminColors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_status(b), style: ts(12.5, w: FontWeight.w700))),
                    ]),
                  ),
                  const SizedBox(height: 40),
                  AdminButton('Track Booking Status',
                      kind: ButtonKind.filled, icon: Icons.track_changes_rounded, height: 50,
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => BookingTrackingScreen(bookingId: b.id)))),
                  const SizedBox(height: 8),
                  AdminButton('Go to My Bookings', kind: ButtonKind.tonal, icon: Icons.receipt_long_outlined, height: 48,
                      onPressed: () {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                        CustomerNav.goTab(2);
                      }),
                  if (b.canCancel)
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => CancelBookingScreen(bookingId: b.id))),
                      child: const Text('Cancel this request'),
                    ),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}
