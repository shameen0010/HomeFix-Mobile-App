import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/customer_actions.dart';
import '../widgets/customer_header.dart';
import 'cancel_booking_screen.dart';

/// Live tracker of an emergency booking (FR-B07, FR-B08).
class EmergencyStatusScreen extends StatefulWidget {
  const EmergencyStatusScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<EmergencyStatusScreen> createState() => _EmergencyStatusScreenState();
}

class _EmergencyStatusScreenState extends State<EmergencyStatusScreen> {
  final _repo = CustomerRepository.instance;
  late final Stream<BookingInfo?> _stream = _repo.watchBooking(widget.bookingId);
  String _providerId = '';
  Stream<ProviderProfile?>? _providerStream;

  Stream<ProviderProfile?>? _providerFor(String id) {
    if (id.isEmpty) return null;
    if (id != _providerId) {
      _providerId = id;
      _providerStream = _repo.watchProvider(id);
    }
    return _providerStream;
  }

  static const _steps = [
    ('Request Sent', 'System received your urgent request'),
    ('Provider Accepted', 'Technician assigned & prepped toolset'),
    ('On the Way', 'Provider heading to your address with priority service van'),
    ('Service Started', 'Inspection and initial stabilization'),
    ('Completed', 'Sign-off, safety test, and diagnostic receipt'),
  ];

  DateTime? _timeOf(BookingInfo b, int i) {
    switch (i) {
      case 0:
        return b.createdAt;
      case 1:
        return b.acceptedAt;
      case 2:
        return b.startedAt;
      case 4:
        return b.finishedAt ?? b.completedAt;
      default:
        return null;
    }
  }

  String _eta(BookingInfo b, ProviderProfile? p) {
    if (b.stage == 'arrived' || b.stage == 'working' || b.stage == 'done' || b.status == 'completed') return 'Arrived';
    final buf = p?.travelBufferMins ?? 30;
    final low = buf - 15 < 10 ? 10 : buf - 15;
    return '$low-${low + 10} minutes';
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Dispatch Status', showBack: true),
        Expanded(
          child: StreamBuilder<BookingInfo?>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load this request.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final b = snap.data;
              if (b == null) return const EmptyView(message: 'This request no longer exists', icon: Icons.search_off_rounded);
              final ps = _providerFor(b.providerId);
              if (ps == null) return _content(b, null);
              return StreamBuilder<ProviderProfile?>(stream: ps, builder: (_, p) => _content(b, p.data));
            },
          ),
        ),
      ]),
    );
  }

  Widget _content(BookingInfo b, ProviderProfile? p) {
    final cancelled = b.status == 'cancelled';
    final expired = b.status == 'pending' && b.expiresAt != null && b.expiresAt!.isBefore(DateTime.now());
    final allDone = b.status == 'completed';
    final active = b.emergencyStep;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: cancelled ? AdminColors.red : AdminColors.orange, borderRadius: BorderRadius.circular(20)),
          child: Text(
              cancelled
                  ? 'EMERGENCY REQUEST CANCELLED \u2022 #EMG-${b.bookingNo}'
                  : 'EMERGENCY REQUEST ACTIVE \u2022 BOOKING #EMG-${b.bookingNo}',
              style: ts(10, w: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text('Emergency\nBooking Status', style: ts(23, w: FontWeight.w700, height: 1.2))),
          if (!cancelled) StatusPill(allDone ? 'Completed' : 'Priority Dispatched', tone: Tone.blue, size: 10.5),
        ]),
        const SizedBox(height: 12),
        if (!b.hasProvider && !cancelled)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: NoticeBox(
                icon: Icons.sync_rounded,
                title: 'Finding another technician',
                text: 'The previous technician declined. We are reassigning your request.',
                bg: AdminColors.orangeBg,
                fg: Color(0xFF92400E)),
          ),
        if (expired)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: NoticeBox(
                icon: Icons.timer_off_outlined,
                title: 'Waiting longer than expected',
                text: 'The 15-minute acceptance window has passed. You can cancel and choose another provider.',
                bg: AdminColors.redBg,
                fg: Color(0xFF7F1D1D)),
          ),
        if (!cancelled)
          AdminCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('PROGRESS TRACKER', style: ts(10, w: FontWeight.w700, color: AdminColors.grey)),
                const Spacer(),
                StatusPill('Step ${allDone ? 5 : active + 1} of 5', tone: Tone.orange, size: 10),
              ]),
              const SizedBox(height: 10),
              for (var i = 0; i < _steps.length; i++) _step(b, i, active, allDone),
            ]),
          ),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(children: [
            if (b.hasProvider)
              Row(children: [
                AdminAvatar(name: b.providerName, photoUrl: p?.photoUrl, radius: 26,
                    badgeColor: AdminColors.orange, badgeIcon: Icons.verified_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.providerName, style: ts(15, w: FontWeight.w700)),
                    Text(p?.headline ?? 'Service professional', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: ts(11, color: AdminColors.grey)),
                    if (p != null)
                      Text('Dispatched from ${p.coverageArea}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: ts(10.5, w: FontWeight.w600, color: AdminColors.primary)),
                  ]),
                ),
                if (p != null) StatusPill('\u2605 ${p.rating.toStringAsFixed(1)} (${p.reviewCount})', tone: Tone.orange, size: 10),
              ])
            else
              Text('A technician will appear here once assigned.', style: ts(12, color: AdminColors.grey)),
            if (b.hasProvider && !cancelled) ...[
              const SizedBox(height: 12),
              AdminButton('Chat with Provider', kind: ButtonKind.tonal, icon: Icons.chat_bubble_outline_rounded,
                  height: 44, onPressed: () => openBookingChat(context, b)),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Booking Details', style: ts(15, w: FontWeight.w700)),
              const Spacer(),
              const StatusPill('Urgent Tier', tone: Tone.blue, size: 10),
            ]),
            const SizedBox(height: 10),
            _detail(Icons.build_outlined, 'Service', b.title),
            _detail(Icons.place_outlined, 'Service Address', b.address),
            _detail(Icons.schedule_rounded, 'Booking Date & Time', formatDate(b.createdAt ?? b.scheduledAt, 'EEE, MMM d \u2022 h:mm a')),
            if (!cancelled && !allDone) _detail(Icons.timer_outlined, 'Estimated Arrival', _eta(b, p), highlight: true),
            _detail(Icons.payments_outlined, 'Payment Terms',
                'Cash settlement on completion (${formatMoney(b.amount)} base diagnostic)'),
            if (b.notes.isNotEmpty) _detail(Icons.notes_rounded, 'Problem', b.notes),
          ]),
        ),
        const SizedBox(height: 12),
        if (!cancelled && !allDone)
          const NoticeBox(
              icon: Icons.info_outline_rounded,
              text: 'Please ensure your building gate or front door is accessible for technician arrival.'),
        const SizedBox(height: 12),
        if (b.jobDone && !cancelled && !(b.status == 'completed' && b.reviewed))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AdminButton(b.status == 'completed' ? 'Rate Service' : 'Confirm Cash Handover',
                kind: ButtonKind.filled, icon: Icons.payments_outlined, height: 48,
                onPressed: () => openBooking(context, b)),
          ),
        if (b.canCancel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AdminButton('Cancel Request', kind: ButtonKind.danger, height: 46,
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => CancelBookingScreen(bookingId: b.id)))),
          ),
        AdminButton('Return to Dashboard', kind: ButtonKind.tonal, height: 48, onPressed: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          CustomerNav.goTab(0);
        }),
        const SizedBox(height: 6),
        Center(child: Text('Cash only. No cancellation fee for customers.', style: ts(10.5, color: AdminColors.grey))),
      ],
    );
  }

  Widget _step(BookingInfo b, int i, int active, bool allDone) {
    final done = allDone || i < active;
    final current = !allDone && i == active;
    final t = _timeOf(b, i);
    final (title, sub) = _steps[i];
    final row = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(
        radius: 13,
        backgroundColor: done ? AdminColors.primary : (current ? AdminColors.orange : AdminColors.chipBg),
        child: Icon(done ? Icons.check_rounded : (current ? Icons.navigation_rounded : Icons.circle_outlined),
            size: 14, color: done || current ? Colors.white : AdminColors.grey),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(title,
                  style: ts(current ? 15 : 14, w: FontWeight.w700,
                      color: current ? const Color(0xFF92400E) : (done ? AdminColors.dark : AdminColors.grey))),
            ),
            if (t != null && (done || current)) Text(formatDate(t, 'h:mm a'), style: ts(10.5, color: AdminColors.grey)),
          ]),
          Text(sub, style: ts(10.5, height: 1.35, color: AdminColors.grey)),
          if (current)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: StatusPill('Active Now', tone: Tone.orange, size: 9.5),
            ),
        ]),
      ),
    ]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: current
          ? Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AdminColors.orangeBg, borderRadius: BorderRadius.circular(12)),
              child: row)
          : row,
    );
  }

  Widget _detail(IconData icon, String label, String value, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
              radius: 15,
              backgroundColor: highlight ? AdminColors.orangeBg : AdminColors.chipBg,
              child: Icon(icon, size: 15, color: highlight ? AdminColors.orange : AdminColors.primary)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: ts(10, color: highlight ? const Color(0xFF92400E) : AdminColors.grey)),
              Text(value, style: ts(highlight ? 17 : 12.5, w: FontWeight.w700,
                  color: highlight ? const Color(0xFF92400E) : AdminColors.dark)),
            ]),
          ),
        ]),
      );
}
