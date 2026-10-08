import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../../provider/data/models/service_item.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_draft.dart';
import '../../data/models/customer_profile.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/availability.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/customer_header.dart';
import 'booking_summary_screen.dart';

/// Scheduled booking, step 1: schedule + location + problem + cash payment + breakdown
/// (FR-B01, FR-B02, FR-B03).
class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({super.key, required this.provider, required this.service});
  final ProviderProfile provider;
  final ServiceItem service;

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  final _repo = CustomerRepository.instance;
  late final BookingDraft _draft = BookingDraft(provider: widget.provider, service: widget.service);
  late final Stream<List<SavedAddress>> _saved = _repo.watchAddresses();
  final _address = TextEditingController();
  final _problem = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _address.dispose();
    _problem.dispose();
    super.dispose();
  }

  int get _step => _draft.scheduledAt == null ? 1 : (_address.text.trim().length < 5 ? 2 : 3);

  void _next() {
    final at = _draft.scheduledAt;
    if (at == null) {
      showAdminSnack(context, 'Choose a date and an arrival window.', error: true);
      return;
    }
    final err = validateSlot(widget.provider, at);
    if (err != null) {
      showAdminSnack(context, err, error: true);
      return;
    }
    if (_address.text.trim().length < 5) {
      showAdminSnack(context, 'Enter the full service address.', error: true);
      return;
    }
    _draft
      ..address = _address.text.trim()
      ..problem = _problem.text.trim();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BookingSummaryScreen(draft: _draft)));
  }

  @override
  Widget build(BuildContext context) {
    final q = _draft.quote;
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Booking Checkout', showBack: true),
        BookingStepper(step: _step),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              _section(Icons.calendar_today_outlined, 'Select Schedule', widget.provider.name, 'Step 1',
                  SlotPicker(
                      provider: widget.provider,
                      initial: _draft.scheduledAt,
                      onChanged: (t) => setState(() => _draft.scheduledAt = t))),
              const SizedBox(height: 12),
              _section(Icons.place_outlined, 'Service Location', 'Confirmed arrival destination', 'Step 2',
                  _location()),
              const SizedBox(height: 12),
              _section(Icons.edit_note_rounded, 'Describe the Problem', 'Optional, helps the pro prepare', 'Details',
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    TextField(
                        controller: _problem,
                        maxLines: 3,
                        maxLength: 300,
                        decoration: fieldDeco('e.g. Under-sink leak near valve, water pooling in cabinet')),
                    const SizedBox(height: 6),
                    PhotoStrip(photos: _draft.photos),
                  ])),
              const SizedBox(height: 12),
              _section(Icons.payments_outlined, 'Payment Method', 'Zero prepayment needed', 'Step 3', Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.primary)),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const CircleAvatar(radius: 18, backgroundColor: AdminColors.orangeBg,
                        child: Icon(Icons.attach_money_rounded, color: AdminColors.orange, size: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Cash on Service Completion', style: ts(13, w: FontWeight.w700)),
                        Text('Pay the technician directly in cash once work is inspected and finished. No online payment required.',
                            style: ts(10.5, height: 1.4, color: AdminColors.grey)),
                      ]),
                    ),
                    const Icon(Icons.radio_button_checked_rounded, color: AdminColors.primary),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.shield_outlined, size: 15, color: AdminColors.primary),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Protected by HomeFix Complete Satisfaction Promise',
                          style: ts(10.5, w: FontWeight.w600, color: AdminColors.dark))),
                    ]),
                  ),
                ]),
              )),
              const SizedBox(height: 12),
              AdminCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Booking Breakdown', style: ts(15, w: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _line(q.label, formatMoney(q.service)),
                  const SizedBox(height: 6),
                  _line('HomeFix Guarantee Fee', formatMoney(q.fee)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Total Payable in Cash', style: ts(13, w: FontWeight.w700)),
                          Text('Due after task inspection', style: ts(10, color: AdminColors.primary)),
                        ]),
                      ),
                      Text(formatMoney(q.total), style: ts(26, w: FontWeight.w700, color: AdminColors.primary)),
                    ]),
                  ),
                  if (widget.service.priceType == 'hourly')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Hourly service: the final amount depends on the time worked.',
                          style: ts(10.5, color: AdminColors.grey)),
                    ),
                ]),
              ),
            ],
          ),
        ),
        BottomActionBar(children: [
          AdminButton('Next', kind: ButtonKind.filled, icon: Icons.arrow_forward_rounded, height: 50, onPressed: _next),
        ]),
      ]),
    );
  }

  Widget _line(String a, String b) => Row(children: [
        Expanded(child: Text(a, style: ts(12.5, color: AdminColors.grey))),
        Text(b, style: ts(13, w: FontWeight.w700)),
      ]);

  Widget _location() => StreamBuilder<List<SavedAddress>>(
        stream: _saved,
        builder: (context, snap) {
          final list = snap.data ?? const <SavedAddress>[];
          if (!_prefilled && snap.hasData) {
            _prefilled = true;
            final def = list.where((a) => a.isDefault).toList();
            if (def.isNotEmpty && _address.text.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _address.text = def.first.address);
              });
            }
          }
          final already = list.any((a) => a.address.trim().toLowerCase() == _address.text.trim().toLowerCase());
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Apartment / Street Address', style: ts(11.5, color: AdminColors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: _address,
              maxLines: 2,
              minLines: 1,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: fieldDeco('742 Evergreen Terrace, Apt 4B', icon: Icons.home_outlined),
            ),
            if (list.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final a in list)
                  ActionChip(
                    avatar: Icon(a.isDefault ? Icons.star_rounded : Icons.bookmark_border_rounded, size: 15),
                    label: Text(a.label),
                    onPressed: () => setState(() => _address.text = a.address),
                  ),
              ]),
            ],
            if (_address.text.trim().length >= 5 && !already)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: _draft.saveAddress,
                onChanged: (v) => setState(() => _draft.saveAddress = v ?? false),
                title: Text('Save this address to my account', style: ts(11.5)),
              ),
          ]);
        },
      );

  Widget _section(IconData icon, String title, String sub, String badge, Widget child) => AdminCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 16, backgroundColor: AdminColors.chipBg,
                child: Icon(icon, size: 17, color: AdminColors.primary)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: ts(15, w: FontWeight.w700)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(10.5, color: AdminColors.grey)),
              ]),
            ),
            StatusPill(badge, tone: Tone.blue, size: 9.5),
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      );
}
