import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/customer_header.dart';

/// Cancel a pending/confirmed booking with a required reason (FR-B06).
class CancelBookingScreen extends StatefulWidget {
  const CancelBookingScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends State<CancelBookingScreen> {
  final _repo = CustomerRepository.instance;
  late final Stream<BookingInfo?> _stream = _repo.watchBooking(widget.bookingId);
  final _comments = TextEditingController();
  String? _reason;
  bool _release = false;

  static const _reasons = [
    (Icons.swap_horiz_rounded, 'Selected another provider'),
    (Icons.handyman_outlined, 'Repair no longer needed / fixed myself'),
    (Icons.edit_calendar_outlined, 'Booked by mistake'),
    (Icons.schedule_rounded, 'Provider delayed or unavailable'),
    (Icons.request_quote_outlined, 'Change in budget / pricing concern'),
    (Icons.more_horiz_rounded, 'Other'),
  ];

  @override
  void dispose() {
    _comments.dispose();
    super.dispose();
  }

  Future<void> _cancel(BookingInfo b) async {
    final reason = _reason;
    if (reason == null) {
      showAdminSnack(context, 'Please choose a reason for cancelling.', error: true);
      return;
    }
    if (!_release) {
      showAdminSnack(context, 'Tick the box to confirm releasing the schedule slot.', error: true);
      return;
    }
    final ok = await runAdminAction(
      context,
      () => _repo.cancelBooking(b.id, reason, comments: _comments.text),
      success: '${b.code} cancelled',
    );
    if (ok && mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Cancel Booking', showBack: true),
        Expanded(
          child: StreamBuilder<BookingInfo?>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load this booking.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final b = snap.data;
              if (b == null) return const EmptyView(message: 'Booking not found', icon: Icons.search_off_rounded);
              if (!b.canCancel) {
                return EmptyView(
                    message: b.status == 'cancelled'
                        ? '${b.code} has been cancelled'
                        : '${b.code} can no longer be cancelled (${b.status.replaceAll('_', ' ')})',
                    icon: Icons.block_rounded);
              }
              return _form(b);
            },
          ),
        ),
      ]),
    );
  }

  Widget _form(BookingInfo b) {
    final first = b.providerName.split(' ').first;
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            NoticeBox(
              icon: Icons.help_outline_rounded,
              title: 'Cancel Booking ${b.code}?',
              text: b.hasProvider ? '${b.providerName} has reserved this slot for your ${b.category.toLowerCase()} service.' : 'Your request is still looking for a provider.',
              bg: AdminColors.orangeBg,
              fg: const Color(0xFF92400E),
            ),
            const SizedBox(height: 12),
            AdminCard(
              child: Column(children: [
                Row(children: [
                  AdminAvatar(name: b.providerName, radius: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(b.title, style: ts(15, w: FontWeight.w700))),
                        Text(formatMoney(b.amount), style: ts(15, w: FontWeight.w700, color: AdminColors.primary)),
                      ]),
                      Text(b.hasProvider ? b.providerName : 'Unassigned', style: ts(11, color: AdminColors.grey)),
                      Text(formatDate(b.scheduledAt, 'EEE, MMM d \u2022 h:mm a'), style: ts(11, color: AdminColors.grey)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.payments_outlined, size: 15, color: AdminColors.grey),
                    const SizedBox(width: 6),
                    Text('Payment Method', style: ts(11, color: AdminColors.grey)),
                    const Spacer(),
                    Text('Cash on Arrival', style: ts(11, w: FontWeight.w700)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            NoticeBox(
              icon: Icons.verified_outlined,
              title: '100% Free Cancellation Guarantee',
              text: 'Since $first has not started transit or work, there are zero cancellation fees. Cash is only paid upon in-person completion.',
            ),
            const SizedBox(height: 16),
            Row(children: [
              Text('Reason for cancelling', style: ts(16, w: FontWeight.w700)),
              const Spacer(),
              Text('REQUIRED', style: ts(9.5, w: FontWeight.w700, color: AdminColors.grey)),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text('Help $first and our home care community understand what happened.',
                  style: ts(11, color: AdminColors.grey)),
            ),
            for (final (icon, text) in _reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _reason = text),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _reason == text ? AdminColors.primary : AdminColors.border),
                    ),
                    child: Row(children: [
                      Icon(icon, size: 17, color: AdminColors.grey),
                      const SizedBox(width: 10),
                      Expanded(child: Text(text,
                          style: ts(12.5, w: _reason == text ? FontWeight.w700 : FontWeight.w500))),
                      Icon(_reason == text ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked,
                          color: _reason == text ? AdminColors.primary : AdminColors.border),
                    ]),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            AdminCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Additional comments ', style: ts(12.5, w: FontWeight.w700)),
                  TextSpan(text: '(Optional)', style: ts(11, color: AdminColors.grey)),
                ])),
                const SizedBox(height: 8),
                TextField(
                    controller: _comments,
                    maxLines: 3,
                    maxLength: 250,
                    decoration: fieldDeco('Tell us how we can improve our service or $first\'s dispatch...')),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Private note for support team', style: ts(10, color: AdminColors.grey)),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            AdminCard(
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _release,
                onChanged: (v) => setState(() => _release = v ?? false),
                title: Text('Release schedule slot', style: ts(12.5, w: FontWeight.w700)),
                subtitle: Text(
                    'I confirm I want to release ${b.hasProvider ? '$first\'s' : 'this'} calendar for ${formatDate(b.scheduledAt, 'EEE, MMM d')}. Another customer will be allowed to book.',
                    style: ts(10.5, height: 1.4, color: AdminColors.grey)),
              ),
            ),
          ],
        ),
      ),
      BottomActionBar(children: [
        AdminButton('Keep My Booking', kind: ButtonKind.filled, icon: Icons.event_available_outlined, height: 48,
            onPressed: () => Navigator.of(context).maybePop()),
        const SizedBox(height: 8),
        AdminButton('Cancel My Booking', kind: ButtonKind.danger, icon: Icons.event_busy_outlined, height: 46,
            onPressed: () => _cancel(b)),
        const SizedBox(height: 6),
        Text('Safe & encrypted transaction \u2022 Zero penalty', style: ts(10, color: AdminColors.grey)),
      ]),
    ]);
  }
}
