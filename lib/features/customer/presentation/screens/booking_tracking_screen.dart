import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/customer_actions.dart';
import '../widgets/customer_header.dart';
import '../widgets/reschedule_sheet.dart';
import 'cancel_booking_screen.dart';
import 'help_support_screen.dart';

/// Booking details + live status tracking (FR-B06, FR-B07, FR-B08, FR-C06).
class BookingTrackingScreen extends StatefulWidget {
  const BookingTrackingScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen> {
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

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Booking Details', showBack: true),
        Expanded(
          child: StreamBuilder<BookingInfo?>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load this booking.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final b = snap.data;
              if (b == null) return const EmptyView(message: 'This booking no longer exists', icon: Icons.search_off_rounded);
              final ps = _providerFor(b.providerId);
              if (ps == null) return _content(b, null);
              return StreamBuilder<ProviderProfile?>(stream: ps, builder: (_, p) => _content(b, p.data));
            },
          ),
        ),
      ]),
    );
  }

  Widget _tracker(BookingInfo b) {
    final labels = [
      'Pending',
      'Confirmed',
      b.stage == 'arrived' ? 'Arrived' : (b.stage == 'working' ? 'Working' : 'En Route'),
      'Done',
    ];
    final cur = b.trackStep;
    final allDone = b.status == 'completed';
    Widget dot(int i) {
      final done = allDone || i < cur;
      final current = !allDone && i == cur;
      return CircleAvatar(
        radius: 15,
        backgroundColor: done ? AdminColors.primary : (current ? AdminColors.orange : AdminColors.chipBg),
        child: Icon(
            done ? Icons.check_rounded : (i == 3 ? Icons.flag_outlined : (current ? Icons.navigation_rounded : Icons.circle_outlined)),
            size: 15,
            color: done || current ? Colors.white : AdminColors.grey),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: [
        Row(children: [
          for (var i = 0; i < 4; i++) ...[
            dot(i),
            if (i < 3)
              Expanded(child: Container(height: 2.5, color: (allDone || i < cur) ? AdminColors.primary : AdminColors.chipBg)),
          ],
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var i = 0; i < 4; i++)
            Text(labels[i],
                style: ts(10, w: (i == cur && !allDone) ? FontWeight.w700 : FontWeight.w500,
                    color: i <= cur || allDone ? AdminColors.dark : AdminColors.grey)),
        ]),
      ]),
    );
  }

  Widget _content(BookingInfo b, ProviderProfile? p) {
    final (label, tone) = bookingChip(b);
    final cancelled = b.status == 'cancelled';
    final cancelText = [
      if ((b.cancelReason ?? '').isNotEmpty) 'Reason: ${b.cancelReason}',
      if ((b.cancelComments ?? '').isNotEmpty) b.cancelComments!,
    ].join('\n');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        AdminCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(b.code, style: ts(12, w: FontWeight.w700, color: AdminColors.grey)),
              const SizedBox(width: 8),
              StatusPill(label, tone: tone, size: 10),
              const Spacer(),
              if (b.isEmergency) const StatusPill('Emergency', tone: Tone.red, size: 10),
            ]),
            const SizedBox(height: 12),
            if (cancelled)
              NoticeBox(
                icon: Icons.cancel_outlined,
                title: 'Booking cancelled',
                text: cancelText.isEmpty ? 'This booking was cancelled.' : cancelText,
                bg: AdminColors.redBg,
                fg: const Color(0xFF7F1D1D),
              )
            else
              _tracker(b),
          ]),
        ),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('ASSIGNED PROFESSIONAL', style: ts(9.5, w: FontWeight.w700, color: AdminColors.grey)),
              const Spacer(),
              if (b.hasProvider) const StatusPill('Verified Pro', tone: Tone.blue, size: 9.5),
            ]),
            const SizedBox(height: 10),
            if (!b.hasProvider)
              Text('A provider has not been assigned yet.', style: ts(12, color: AdminColors.grey))
            else ...[
              Row(children: [
                AdminAvatar(name: b.providerName, photoUrl: p?.photoUrl, radius: 28,
                    badgeColor: AdminColors.primary, badgeIcon: Icons.check),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.providerName, style: ts(16, w: FontWeight.w700)),
                    Text(p == null ? 'Service professional' : '${p.headline} \u2022 ${p.experienceYears}+ yrs exp',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, color: AdminColors.grey)),
                    if (p != null)
                      Text('\u2605 ${p.rating.toStringAsFixed(1)} (${p.reviewCount} reviews)',
                          style: ts(11, w: FontWeight.w700, color: AdminColors.orange)),
                  ]),
                ),
              ]),
              if (!cancelled) ...[
                const SizedBox(height: 10),
                AdminButton('Message', icon: Icons.chat_bubble_outline_rounded, kind: ButtonKind.filled, height: 40,
                    onPressed: () => openBookingChat(context, b)),
              ],
            ],
          ]),
        ),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Service Details', style: ts(15, w: FontWeight.w700)),
              const Spacer(),
              StatusPill(b.category, tone: Tone.blue, size: 9.5),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CircleAvatar(radius: 18, backgroundColor: AdminColors.chipBg,
                  child: Icon(Icons.build_rounded, size: 17, color: AdminColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.title, style: ts(14.5, w: FontWeight.w700)),
                  if (b.notes.isNotEmpty) Text(b.notes, style: ts(11, height: 1.4, color: AdminColors.grey)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: AdminColors.grey),
                    const SizedBox(width: 4),
                    Text(formatDate(b.scheduledAt, 'EEE, MMM d \u2022 h:mm a'),
                        style: ts(10.5, w: FontWeight.w600, color: AdminColors.grey)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 12, color: AdminColors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(b.address, style: ts(10.5, color: AdminColors.grey))),
                  ]),
                ]),
              ),
            ]),
            if (b.requestPhotos.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final ph in b.requestPhotos)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(ph.url, width: 64, height: 64, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: AdminColors.field)),
                      ),
                    ),
                ]),
              ),
            ],
            const SizedBox(height: 10),
            const NoticeBox(
              icon: Icons.verified_user_outlined,
              text: 'HomeFix 30-Day Guarantee: all repair work is insured and guaranteed to your satisfaction.',
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AdminColors.orangeBg, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const CircleAvatar(radius: 20, backgroundColor: AdminColors.orange,
                child: Icon(Icons.payments_outlined, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PAYMENT METHOD', style: ts(9, w: FontWeight.w700, color: const Color(0xFF92400E))),
                Text('${formatMoney(b.amount)} in Cash', style: ts(17, w: FontWeight.w700)),
                Text('Due directly upon job completion', style: ts(10.5, color: const Color(0xFF92400E))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (b.jobDone && !cancelled && !(b.status == 'completed' && b.reviewed))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AdminButton(b.status == 'completed' ? 'Rate Service' : 'Confirm Cash Handover',
                kind: ButtonKind.filled, icon: Icons.payments_outlined, height: 48,
                onPressed: () => openBooking(context, b)),
          ),
        if (b.canReschedule && b.hasProvider)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AdminButton('Reschedule', kind: ButtonKind.tonal, icon: Icons.edit_calendar_outlined, height: 46,
                onPressed: () => showRescheduleSheet(context, b)),
          ),
        if (b.canCancel)
          AdminButton('Cancel Booking', kind: ButtonKind.danger, icon: Icons.cancel_outlined, height: 46,
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => CancelBookingScreen(bookingId: b.id)))),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HelpSupportScreen())),
            icon: const Icon(Icons.help_outline_rounded, size: 16),
            label: const Text('Need Help or Have a Question? Contact Support'),
          ),
        ),
      ],
    );
  }
}
