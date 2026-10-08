import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/customer_actions.dart';
import '../widgets/customer_header.dart';

/// Minimal bookings list (cancel, chat, cash confirmation, review).
/// Replace or extend it when you add the full booking flow screens.
class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  final _repo = CustomerRepository.instance;
  late final Stream<List<BookingInfo>> _stream = _repo.watchMyBookings();
  bool _past = false;

  (String, Tone) _chip(BookingInfo b) {
    switch (b.status) {
      case 'pending':
        return (b.hasProvider ? 'Awaiting provider' : 'Finding provider', Tone.orange);
      case 'confirmed':
        return ('Confirmed', Tone.blue);
      case 'in_progress':
        return (b.stageLabel, Tone.orange);
      case 'completed':
        return ('Completed', Tone.green);
      case 'cancelled':
        return ('Cancelled', Tone.red);
      default:
        return (b.status, Tone.grey);
    }
  }

  Future<void> _cancel(BookingInfo b) async {
    final reason = await promptText(context,
        title: 'Cancel ${b.code}?', hint: 'Reason for cancelling', confirmLabel: 'Cancel booking');
    if (reason == null || !mounted) return;
    await runAdminAction(context, () => _repo.cancelBooking(b.id, reason), success: '${b.code} cancelled');
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'My Bookings'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            AdminChoiceChip(label: 'Upcoming', selected: !_past, onTap: () => setState(() => _past = false)),
            AdminChoiceChip(label: 'Past', selected: _past, onTap: () => setState(() => _past = true)),
          ]),
        ),
        Expanded(
          child: StreamBuilder<List<BookingInfo>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load bookings.\n${snap.error}');
              if (!snap.hasData) return const LoadingView();
              final list = snap.data!.where((b) {
                final past = b.status == 'cancelled' || (b.status == 'completed' && b.reviewed);
                return _past ? past : !past;
              }).toList();
              if (list.isEmpty) {
                return EmptyView(
                    message: _past ? 'No past bookings yet' : 'No upcoming bookings',
                    icon: Icons.event_busy_outlined);
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  for (final b in list)
                    Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(b)),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _card(BookingInfo b) {
    final (label, tone) = _chip(b);
    final needsCash = b.jobDone && b.status != 'cancelled' && !(b.customerAttested && b.status == 'completed');
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(b.code, style: ts(11.5, w: FontWeight.w700, color: AdminColors.grey)),
          const SizedBox(width: 8),
          StatusPill(label, tone: tone, size: 10),
          const Spacer(),
          Text(formatMoney(b.amount), style: ts(14, w: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Text(b.title, style: ts(16, w: FontWeight.w700)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.engineering_outlined, size: 14, color: AdminColors.grey),
          const SizedBox(width: 4),
          Expanded(child: Text(b.providerName, style: ts(12, color: AdminColors.grey))),
          const Icon(Icons.schedule_rounded, size: 14, color: AdminColors.grey),
          const SizedBox(width: 4),
          Text(formatDate(b.scheduledAt, 'MMM d, h:mm a'), style: ts(11.5, color: AdminColors.grey)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.place_outlined, size: 14, color: AdminColors.grey),
          const SizedBox(width: 4),
          Expanded(child: Text(b.address, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: ts(11.5, color: AdminColors.grey))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          if (needsCash)
            Expanded(
              child: AdminButton('Confirm cash', kind: ButtonKind.filled, icon: Icons.payments_outlined,
                  height: 40, onPressed: () => openBooking(context, b)),
            )
          else if (b.status == 'completed' && !b.reviewed)
            Expanded(
              child: AdminButton('Rate service', kind: ButtonKind.filled, icon: Icons.star_border_rounded,
                  height: 40, onPressed: () => openReview(context, b.id)),
            )
          else if (b.hasProvider && b.status != 'cancelled')
            Expanded(
              child: AdminButton('Message provider', icon: Icons.chat_bubble_outline_rounded,
                  height: 40, onPressed: () => openBookingChat(context, b)),
            )
          else
            const Spacer(),
          if (b.status == 'pending' || b.status == 'confirmed') ...[
            const SizedBox(width: 8),
            AdminButton('Cancel', kind: ButtonKind.danger, height: 40, onPressed: () => _cancel(b)),
          ],
        ]),
      ]),
    );
  }
}
