import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/models/customer_profile.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/services/receipt_pdf.dart';
import '../widgets/customer_actions.dart';
import '../widgets/customer_header.dart';

/// Dual-handshake cash confirmation (customer + provider attestations).
class CashConfirmationScreen extends StatefulWidget {
  const CashConfirmationScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<CashConfirmationScreen> createState() => _CashConfirmationScreenState();
}

class _CashConfirmationScreenState extends State<CashConfirmationScreen> {
  final _repo = CustomerRepository.instance;
  late final Stream<BookingInfo?> _stream = _repo.watchBooking(widget.bookingId);
  CustomerProfile? _me;
  ProviderProfile? _provider;
  bool _providerLoaded = false;
  bool _providerView = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _repo.getMe().then((m) {
      if (mounted) setState(() => _me = m);
    }).catchError((Object _) {});
  }

  void _loadProvider(String id) {
    if (_providerLoaded || id.isEmpty) return;
    _providerLoaded = true;
    _repo.getProvider(id).then((p) {
      if (mounted) setState(() => _provider = p);
    }).catchError((Object _) {});
  }

  Future<void> _confirm(BookingInfo b) async {
    final ok = await runAdminAction(context, () => _repo.attestCash(b.id),
        success: 'Cash handover confirmed');
    if (ok && mounted && b.providerConfirmed && !b.reviewed) openReview(context, b.id);
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Cash Confirmation', showBack: true),
        Expanded(
          child: StreamBuilder<BookingInfo?>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load the booking.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final b = snap.data;
              if (b == null) return const ErrorView(message: 'This booking no longer exists.');
              _loadProvider(b.providerId);
              return _body(b);
            },
          ),
        ),
      ]),
    );
  }

  Widget _body(BookingInfo b) {
    final me = _me?.name ?? b.customerName;
    final attestations = (b.customerAttested ? 1 : 0) + (b.providerConfirmed ? 1 : 0);
    final closed = b.completedAt ?? b.finishedAt;
    final guaranteeOn = b.status == 'completed' && b.customerAttested;
    final money = formatMoney(b.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            _segment('Customer View', Icons.person_outline_rounded, !_providerView, () => setState(() => _providerView = false)),
            _segment('Provider View', Icons.build_outlined, _providerView, () => setState(() => _providerView = true)),
          ]),
        ),
        const SizedBox(height: 12),
        AdminCard(
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.build_rounded, color: AdminColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  StatusPill(b.status == 'completed' ? 'JOB COMPLETED' : b.jobDone ? 'JOB FINISHED' : b.status.toUpperCase(),
                      size: 9.5),
                  const SizedBox(width: 6),
                  Text(b.code, style: ts(10.5, color: AdminColors.grey)),
                ]),
                const SizedBox(height: 2),
                Text(b.title, style: ts(16, w: FontWeight.w700)),
              ]),
            ),
            Icon(b.status == 'completed' ? Icons.check_circle_rounded : Icons.pending_outlined,
                color: b.status == 'completed' ? AdminColors.orange : AdminColors.grey),
          ]),
        ),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(children: [
            const StatusPill('Direct Cash Payment', tone: Tone.orange, icon: Icons.payments_outlined, size: 10.5),
            const SizedBox(height: 8),
            Text(money, style: ts(34, w: FontWeight.w700)),
            Text('Exact Cash Handover', style: ts(11.5, color: AdminColors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AdminColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('No online payment or credit cards. Paid hand-to-hand upon physical inspection of completed repair.',
                      style: ts(11, color: AdminColors.grey)),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.handshake_outlined, size: 18, color: AdminColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Dual Handshake Protocol', style: ts(12, w: FontWeight.w700, color: AdminColors.primary))),
            Text('$attestations of 2 Attestations', style: ts(11, w: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 12),
        _customerBlock(b, me, money),
        const SizedBox(height: 12),
        _providerBlock(b, me, money),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionTitle('Job Inspection Record', trailing: Text('${b.photos.length} Inspection Photos',
                style: ts(10.5, color: AdminColors.primary))),
            const SizedBox(height: 8),
            if (b.photos.isEmpty)
              Text('The provider has not attached photos.', style: ts(11.5, color: AdminColors.grey))
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.45,
                children: [
                  for (final p in b.photos)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(fit: StackFit.expand, children: [
                        Image.network(p.url, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                color: AdminColors.field,
                                child: const Icon(Icons.broken_image_outlined, color: AdminColors.grey))),
                        Positioned(
                          left: 6, bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                            child: Text(p.label, style: ts(10, w: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ]),
                    ),
                ],
              ),
          ]),
        ),
        const SizedBox(height: 12),
        AdminCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CircleAvatar(
                radius: 18, backgroundColor: AdminColors.orangeBg,
                child: Icon(Icons.shield_outlined, color: AdminColors.orange, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(guaranteeOn ? 'HomeFix 30-Day Guarantee Activated' : 'HomeFix 30-Day Guarantee',
                    style: ts(13, w: FontWeight.w700)),
                Text(
                    guaranteeOn
                        ? 'Workmanship is protected until ${formatDate((closed ?? DateTime.now()).add(const Duration(days: 30)))}.'
                        : 'Activates automatically once both parties confirm the cash handover.',
                    style: ts(11, color: AdminColors.grey)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
          child: Text('Viewing as $me (Customer). Both parties must verify the physical cash exchange.',
              textAlign: TextAlign.center, style: ts(10.5, color: AdminColors.grey)),
        ),
        const SizedBox(height: 14),
        AdminButton(
          b.customerAttested ? 'Cash handover confirmed' : 'Confirm & Close Job',
          kind: ButtonKind.filled,
          icon: Icons.check_circle_outline_rounded,
          height: 50,
          onPressed: (!b.customerAttested && _checked && b.jobDone && !_providerView) ? () => _confirm(b) : null,
        ),
        if (b.status == 'completed' && !b.reviewed) ...[
          const SizedBox(height: 8),
          AdminButton('Rate your technician',
              icon: Icons.star_border_rounded, height: 46, onPressed: () => openReview(context, b.id)),
        ],
        const SizedBox(height: 8),
        AdminButton('Download Cash Receipt (PDF)',
            icon: Icons.download_rounded, height: 46,
            onPressed: b.providerConfirmed || b.customerAttested
                ? () => runAdminAction(context, () => ReceiptPdf.share(b, customerName: me),
                    success: 'Receipt ready')
                : null),
      ],
    );
  }

  Widget _segment(String label, IconData icon, bool selected, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 16, color: selected ? AdminColors.primary : AdminColors.grey),
              const SizedBox(width: 6),
              Text(label, style: ts(12.5, w: FontWeight.w600, color: selected ? AdminColors.primary : AdminColors.grey)),
            ]),
          ),
        ),
      );

  Widget _customerBlock(BookingInfo b, String me, String money) {
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(radius: 15, backgroundColor: AdminColors.field,
              child: Icon(Icons.person_outline_rounded, size: 16, color: AdminColors.primary)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Customer Verification', style: ts(13, w: FontWeight.w700)),
              Text('$me  |  Homeowner', style: ts(10.5, color: AdminColors.grey)),
            ]),
          ),
          StatusPill(b.customerAttested ? 'Attested' : 'Pending',
              tone: b.customerAttested ? Tone.blue : Tone.orange,
              icon: b.customerAttested ? Icons.check_circle_outline_rounded : Icons.hourglass_empty_rounded,
              size: 10),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CheckboxListTile(
              value: b.customerAttested || _checked,
              onChanged: (b.customerAttested || !b.jobDone) ? null : (v) => setState(() => _checked = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: Text('I, $me, have handed $money in cash to technician ${b.providerName}.',
                  style: ts(12.5, w: FontWeight.w600)),
              subtitle: Text('Exact cash given ($money). Work inspected and confirmed in full working condition.',
                  style: ts(10.5, color: AdminColors.grey)),
            ),
            if (!b.jobDone)
              Text('Available once the provider marks the job as finished.',
                  style: ts(10.5, color: AdminColors.orange)),
            if (b.customerAttested)
              Row(children: [
                const Icon(Icons.schedule_rounded, size: 13, color: AdminColors.grey),
                const SizedBox(width: 4),
                Text('Today, ${formatDate(b.customerAttestedAt, 'h:mm a')}', style: ts(10.5, color: AdminColors.grey)),
                const Spacer(),
                Text('Digital Token Verified', style: ts(10.5, w: FontWeight.w600, color: AdminColors.primary)),
              ]),
          ]),
        ),
      ]),
    );
  }

  Widget _providerBlock(BookingInfo b, String me, String money) {
    final p = _provider;
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AdminAvatar(name: b.providerName, photoUrl: p?.photoUrl, radius: 18,
              badgeColor: AdminColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(b.providerName, style: ts(13.5, w: FontWeight.w700))),
                const SizedBox(width: 6),
                if (p != null) StatusPill('Master ${p.trade}', tone: Tone.orange, size: 9),
              ]),
              Text(p == null ? 'Technician' : 'Badge #${p.appId}  |  HomeFix Pro',
                  style: ts(10.5, color: AdminColors.grey)),
            ]),
          ),
          StatusPill(b.providerConfirmed ? 'Received' : 'Awaiting',
              tone: b.providerConfirmed ? Tone.blue : Tone.grey, size: 10),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(b.providerConfirmed ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 20, color: b.providerConfirmed ? AdminColors.primary : AdminColors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text('I, ${b.providerName}, confirm physical receipt of $money cash from $me.',
                    style: ts(12.5, w: FontWeight.w600)),
              ),
            ]),
            if (b.providerConfirmed) ...[
              const SizedBox(height: 8),
              Row(children: [
                const StatusPill('Payment Received & Closed', size: 9.5, icon: Icons.shield_outlined),
                const SizedBox(width: 8),
                Flexible(child: Text('Auth #CASH-${b.bookingNo}-OK', style: ts(10, color: AdminColors.grey))),
              ]),
            ],
          ]),
        ),
        if (_providerView && !b.providerConfirmed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Only the technician can confirm receipt from their own app.',
                style: ts(10.5, color: AdminColors.grey)),
          ),
      ]),
    );
  }
}
