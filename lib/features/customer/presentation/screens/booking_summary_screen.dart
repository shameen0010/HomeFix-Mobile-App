import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../../data/models/booking_draft.dart';
import '../../data/models/customer_profile.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/customer_header.dart';
import 'booking_success_screen.dart';

/// Scheduled booking, step 2: review and confirm (FR-B03, FR-B05).
class BookingSummaryScreen extends StatefulWidget {
  const BookingSummaryScreen({super.key, required this.draft});
  final BookingDraft draft;

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final _repo = CustomerRepository.instance;
  late final Stream<CustomerProfile?> _me = _repo.watchMe();

  Future<void> _confirm() async {
    final d = widget.draft;
    final at = d.scheduledAt;
    if (at == null) return;
    String? id;
    final ok = await runAdminAction(
      context,
      () async {
        id = await _repo.createBooking(
          provider: d.provider,
          service: d.service,
          scheduledAt: at,
          address: d.address,
          notes: d.problem,
          photos: d.photos,
        );
        if (d.saveAddress) {
          try {
            final existing = await _repo.getAddresses();
            if (!existing.any((a) => a.address.trim().toLowerCase() == d.address.trim().toLowerCase())) {
              await _repo.saveAddress(
                  label: existing.isEmpty ? 'Home' : 'Address ${existing.length + 1}',
                  address: d.address,
                  isDefault: existing.isEmpty);
            }
          } catch (_) {
            // The booking is already created; a failed address save must not undo it.
          }
        }
      },
      success: 'Booking submitted',
    );
    final bookingId = id;
    if (!ok || bookingId == null || !mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => BookingSuccessScreen(bookingId: bookingId)),
      (r) => r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final at = d.scheduledAt;
    final q = d.quote;
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Service Booking Flow', showBack: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              StreamBuilder<CustomerProfile?>(
                stream: _me,
                builder: (context, snap) {
                  final me = snap.data;
                  return AdminCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('BOOKED FOR', style: ts(9.5, w: FontWeight.w700, color: AdminColors.grey)),
                        const Spacer(),
                        const StatusPill('Verified Customer', tone: Tone.green, size: 9.5),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        AdminAvatar(name: me?.name ?? 'Customer', photoUrl: me?.photoUrl, radius: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(me?.name ?? 'Customer', style: ts(14.5, w: FontWeight.w700)),
                            Text(me?.phone ?? '-', style: ts(11, color: AdminColors.grey)),
                          ]),
                        ),
                      ]),
                    ]),
                  );
                },
              ),
              const SizedBox(height: 12),
              AdminCard(
                child: Column(children: [
                  Row(children: [
                    AdminAvatar(name: d.provider.name, photoUrl: d.provider.photoUrl, radius: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('SELECTED PRO', style: ts(9.5, w: FontWeight.w700, color: AdminColors.primary)),
                        Text(d.provider.name, style: ts(16, w: FontWeight.w700)),
                        Text(d.provider.headline, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: ts(11, color: AdminColors.grey)),
                        Text('\u2605 ${d.provider.rating.toStringAsFixed(1)}',
                            style: ts(11, w: FontWeight.w700, color: AdminColors.orange)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.build_rounded, size: 16, color: AdminColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d.service.name, style: ts(12.5, w: FontWeight.w700)),
                          Text(d.service.category, style: ts(10.5, color: AdminColors.grey)),
                        ]),
                      ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              AdminCard(
                child: Column(children: [
                  _editRow(Icons.calendar_today_outlined, 'SCHEDULED ARRIVAL',
                      at == null ? '-' : formatDate(at, 'EEE, MMM d \u2022 h:mm a'),
                      sub: at == null ? null : 'Arrival window: ${windowLabel(at)}'),
                  const Divider(height: 22),
                  _editRow(Icons.place_outlined, 'SERVICE ADDRESS', d.address),
                ]),
              ),
              const SizedBox(height: 12),
              AdminCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('PROBLEM DESCRIPTION', style: ts(9.5, w: FontWeight.w700, color: AdminColors.grey)),
                    const Spacer(),
                    TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Edit')),
                  ]),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                    child: Text(d.problem.isEmpty ? 'No description added.' : '"${d.problem}"',
                        style: ts(12, height: 1.45, color: d.problem.isEmpty ? AdminColors.grey : AdminColors.dark)),
                  ),
                  if (d.photos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: ListView(scrollDirection: Axis.horizontal, children: [
                        for (final b in d.photos)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(b, width: 56, height: 56, fit: BoxFit.cover)),
                          ),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text('${d.photos.length} attachment${d.photos.length == 1 ? '' : 's'} shared with ${d.provider.name.split(' ').first}',
                        style: ts(10.5, color: AdminColors.grey)),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AdminColors.orangeBg, borderRadius: BorderRadius.circular(16)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.payments_outlined, color: AdminColors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Direct Cash on Completion', style: ts(14, w: FontWeight.w700, color: const Color(0xFF92400E))),
                      const SizedBox(height: 2),
                      Text('No advance online payment needed. Hand cash directly to the technician once work is thoroughly inspected and completed to your satisfaction.',
                          style: ts(10.5, height: 1.4, color: const Color(0xFF92400E))),
                      const SizedBox(height: 4),
                      Text('HomeFix Satisfaction Pledge Active',
                          style: ts(10, w: FontWeight.w700, color: AdminColors.primary)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              AdminCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Estimated Cost Breakdown', style: ts(13.5, w: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _line(q.label, formatMoney(q.service)),
                  const SizedBox(height: 6),
                  _line('HomeFix Guarantee Fee', formatMoney(q.fee)),
                  const Divider(height: 22),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Total Estimated', style: ts(14, w: FontWeight.w700)),
                        Text('Payable in Cash', style: ts(10, w: FontWeight.w600, color: const Color(0xFF92400E))),
                      ]),
                    ),
                    Text(formatMoney(q.total), style: ts(24, w: FontWeight.w700, color: AdminColors.primary)),
                  ]),
                ]),
              ),
            ],
          ),
        ),
        BottomActionBar(children: [
          AdminButton('Confirm Booking',
              kind: ButtonKind.filled, icon: Icons.check_circle_outline_rounded, height: 50, onPressed: _confirm),
          const SizedBox(height: 8),
          AdminButton('Edit Booking Details', kind: ButtonKind.tonal, height: 44,
              onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(height: 6),
          Text('Free cancellation while your booking is pending or confirmed. Cash only, no card data.',
              textAlign: TextAlign.center, style: ts(10, color: AdminColors.grey)),
        ]),
      ]),
    );
  }

  Widget _line(String a, String b) => Row(children: [
        Expanded(child: Text(a, style: ts(12, color: AdminColors.grey))),
        Text(b, style: ts(12.5, w: FontWeight.w700)),
      ]);

  Widget _editRow(IconData icon, String label, String value, {String? sub}) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 15, backgroundColor: AdminColors.chipBg,
            child: Icon(icon, size: 15, color: AdminColors.primary)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: ts(9.5, w: FontWeight.w700, color: AdminColors.grey)),
            Text(value, style: ts(13.5, w: FontWeight.w700)),
            if (sub != null) Text(sub, style: ts(10.5, color: AdminColors.grey)),
          ]),
        ),
        TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Edit')),
      ]);
}
