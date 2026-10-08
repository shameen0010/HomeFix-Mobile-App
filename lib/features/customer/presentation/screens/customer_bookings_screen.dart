import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/customer_actions.dart';
import '../widgets/customer_header.dart';
import '../widgets/reschedule_sheet.dart';
import 'cancel_booking_screen.dart';

/// My Bookings tab: Upcoming / Active / Completed / Cancelled (FR-C06, FR-C09, FR-B07).
class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

enum _Tab { upcoming, active, completed, cancelled }

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  final _repo = CustomerRepository.instance;
  late final Stream<List<BookingInfo>> _stream = _repo.watchMyBookings();
  _Tab _tab = _Tab.upcoming;
  DateTime? _date;

  bool _inTab(BookingInfo b, _Tab t) {
    switch (t) {
      case _Tab.upcoming:
        return b.status == 'pending' || b.status == 'confirmed' || b.status == 'in_progress';
      case _Tab.active:
        return b.status == 'in_progress';
      case _Tab.completed:
        return b.status == 'completed';
      case _Tab.cancelled:
        return b.status == 'cancelled';
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (d != null && mounted) setState(() => _date = d);
  }

  String _chipLabel(String name, int n) => n == 0 ? name : '$name ($n)';

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('My Bookings', style: ts(24, w: FontWeight.w700)),
                Text('Manage your home services and real-time repairs', style: ts(11.5, color: AdminColors.grey)),
              ]),
            ),
            IconButton.filledTonal(
              tooltip: 'Filter by date',
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_rounded),
            ),
          ]),
        ),
        Expanded(
          child: StreamBuilder<List<BookingInfo>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load bookings.\n${snap.error}');
              if (!snap.hasData) return const LoadingView();
              final all = snap.data!;
              int count(_Tab t) => all.where((b) => _inTab(b, t)).length;
              final list = all.where((b) {
                if (!_inTab(b, _tab)) return false;
                final d = _date, at = b.scheduledAt;
                if (d == null) return true;
                return at != null && at.year == d.year && at.month == d.month && at.day == d.day;
              }).toList();
              return Column(children: [
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      AdminChoiceChip(label: 'Upcoming', selected: _tab == _Tab.upcoming,
                          onTap: () => setState(() => _tab = _Tab.upcoming)),
                      AdminChoiceChip(label: _chipLabel('Active', count(_Tab.active)), selected: _tab == _Tab.active,
                          onTap: () => setState(() => _tab = _Tab.active)),
                      AdminChoiceChip(label: _chipLabel('Completed', count(_Tab.completed)),
                          selected: _tab == _Tab.completed, onTap: () => setState(() => _tab = _Tab.completed)),
                      AdminChoiceChip(label: _chipLabel('Cancelled', count(_Tab.cancelled)),
                          selected: _tab == _Tab.cancelled, onTap: () => setState(() => _tab = _Tab.cancelled)),
                    ],
                  ),
                ),
                if (_date != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                        label: Text('Date: ${formatDate(_date, 'MMM d, yyyy')}'),
                        onDeleted: () => setState(() => _date = null),
                      ),
                    ),
                  ),
                Expanded(
                  child: list.isEmpty
                      ? EmptyView(
                          message: _date != null ? 'No bookings on this date' : 'No ${_tab.name} bookings',
                          icon: Icons.event_busy_outlined)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            for (final b in list)
                              Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(b)),
                          ],
                        ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  String _live(BookingInfo b) {
    final first = b.providerName.split(' ').first;
    switch (b.stage) {
      case 'arrived':
        return '$first has arrived';
      case 'working':
        return '$first is working on it';
      case 'done':
        return '$first has finished the job';
      default:
        return '$first is on the way';
    }
  }

  Widget _card(BookingInfo b) {
    final (label, tone) = bookingChip(b);
    final needsCash = b.jobDone && b.status != 'cancelled' && !(b.customerAttested && b.status == 'completed');
    final rate = b.status == 'completed' && b.customerAttested && !b.reviewed;
    final primaryLabel = needsCash
        ? 'Confirm Cash'
        : rate
            ? 'Rate Service'
            : b.status == 'in_progress'
                ? 'Track Status'
                : 'View Details';
    final primaryIcon = needsCash
        ? Icons.payments_outlined
        : rate
            ? Icons.star_border_rounded
            : b.status == 'in_progress'
                ? Icons.navigation_outlined
                : Icons.chevron_right_rounded;
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AdminAvatar(name: b.hasProvider ? b.providerName : b.title, radius: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(15.5, w: FontWeight.w700)),
              Text('${b.hasProvider ? b.providerName : 'Finding provider'} \u2022 ${b.category}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, color: AdminColors.grey)),
            ]),
          ),
          StatusPill(label, tone: tone, size: 10),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 15, color: AdminColors.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(formatDate(b.scheduledAt, 'MMM d, h:mm a'), style: ts(12, w: FontWeight.w600))),
              Text(b.code, style: ts(10.5, w: FontWeight.w700, color: AdminColors.grey)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.place_outlined, size: 15, color: AdminColors.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(b.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11.5))),
            ]),
          ]),
        ),
        if (b.status == 'in_progress') ...[
          const SizedBox(height: 8),
          NoticeBox(icon: Icons.navigation_outlined, title: _live(b), text: 'Tap Track Status for live updates.'),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.status == 'completed' ? 'Paid in cash' : 'Cash total', style: ts(10, color: AdminColors.grey)),
              Text(formatMoney(b.amount), style: ts(18, w: FontWeight.w700)),
            ]),
          ),
          AdminButton(primaryLabel,
              kind: b.status == 'in_progress' || needsCash || rate ? ButtonKind.filled : ButtonKind.tonal,
              icon: primaryIcon,
              height: 42,
              onPressed: () {
                if (needsCash) {
                  openBooking(context, b);
                } else if (rate) {
                  openReview(context, b.id);
                } else {
                  openTracking(context, b);
                }
              }),
        ]),
        if (b.canReschedule || b.canCancel)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (b.canReschedule && b.hasProvider)
                TextButton(onPressed: () => showRescheduleSheet(context, b), child: const Text('Reschedule')),
              if (b.hasProvider)
                TextButton(onPressed: () => openBookingChat(context, b), child: const Text('Message')),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => CancelBookingScreen(bookingId: b.id))),
                child: Text('Cancel', style: ts(13, w: FontWeight.w600, color: AdminColors.red)),
              ),
            ]),
          ),
      ]),
    );
  }
}
