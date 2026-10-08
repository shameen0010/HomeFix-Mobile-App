import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../../provider/data/models/review_model.dart';
import '../../../provider/data/models/service_item.dart';
import '../../core/customer_ui.dart';
import '../../data/models/customer_profile.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/availability.dart';
import '../widgets/customer_actions.dart';
import '../widgets/customer_header.dart';

/// Provider profile + service selection + slot reservation.
class ProviderDetailScreen extends StatefulWidget {
  const ProviderDetailScreen({super.key, required this.providerId, this.emergency = false});
  final String providerId;
  final bool emergency;

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  final _repo = CustomerRepository.instance;
  late final Stream<ProviderProfile?> _profile = _repo.watchProvider(widget.providerId);
  late final Stream<List<ServiceItem>> _services = _repo.watchServices(widget.providerId);
  late final Stream<List<ReviewModel>> _reviews = _repo.watchReviews(widget.providerId);
  late final Stream<Set<String>> _favorites = _repo.watchFavorites();
  ServiceItem? _selected;
  bool _reserved = false;

  Future<void> _reserve(ProviderProfile p) async {
    final s = _selected;
    if (s == null) {
      showAdminSnack(context, 'Select a service first.', error: true);
      return;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReserveSheet(provider: p, service: s, emergency: widget.emergency),
    );
    if (ok == true && mounted) setState(() => _reserved = true);
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Service Detail', showBack: true),
        Expanded(
          child: StreamBuilder<ProviderProfile?>(
            stream: _profile,
            builder: (context, ps) {
              if (ps.hasError) return ErrorView(message: 'Could not load this provider.\n${ps.error}');
              if (ps.connectionState == ConnectionState.waiting) return const LoadingView();
              final p = ps.data;
              if (p == null) return const ErrorView(message: 'This provider is no longer available.');
              return Column(children: [
                Expanded(child: _body(p)),
                _bottomBar(p),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  Widget _body(ProviderProfile p) {
    final a = availabilityOf(p);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        AdminCard(
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AdminAvatar(name: p.name, photoUrl: p.photoUrl, radius: 34,
                  badgeColor: AdminColors.primary, badgeIcon: Icons.check),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(p.name, style: ts(19, w: FontWeight.w700))),
                    StatusPill('${p.experienceYears} Yrs Exp', tone: Tone.orange, size: 10),
                  ]),
                  Text(p.headline, style: ts(12.5, color: AdminColors.grey)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 14, color: AdminColors.primary),
                    const SizedBox(width: 3),
                    Flexible(child: Text('${p.coverageArea}  |  ${a.label}',
                        style: ts(11.5, w: FontWeight.w600, color: AdminColors.primary))),
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.star_rounded, color: AdminColors.orange),
                const SizedBox(width: 4),
                Text(p.rating.toStringAsFixed(1), style: ts(17, w: FontWeight.w700)),
                const SizedBox(width: 6),
                Expanded(child: Text('(${p.reviewCount} verified reviews)', style: ts(11, color: AdminColors.grey))),
                if (p.rating >= 4.5)
                  Text('Top Rated Pro', style: ts(11, w: FontWeight.w700, color: AdminColors.primary)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Text('Select Service', style: ts(18, w: FontWeight.w700))),
          StreamBuilder<Set<String>>(
            stream: _favorites,
            builder: (context, fav) {
              final isFav = fav.data?.contains(p.id) ?? false;
              return IconButton(
                tooltip: isFav ? 'Remove favourite' : 'Add favourite',
                onPressed: () => runAdminAction(context, () => _repo.toggleFavorite(p.id, !isFav),
                    success: isFav ? 'Removed from favourites' : 'Saved to favourites', showLoader: false),
                icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? AdminColors.red : AdminColors.grey),
              );
            },
          ),
        ]),
        StreamBuilder<List<ServiceItem>>(
          stream: _services,
          builder: (context, snap) {
            if (snap.hasError) return Text('Could not load services.', style: ts(12, color: AdminColors.red));
            if (!snap.hasData) return const Padding(padding: EdgeInsets.all(16), child: LoadingView());
            final list = snap.data!;
            if (list.isEmpty) {
              return const EmptyView(message: 'This provider has no bookable services yet', icon: Icons.work_off_outlined);
            }
            return Column(children: [
              for (final s in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: _reserved ? null : () => setState(() => _selected = s),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selected?.id == s.id ? AdminColors.chipBg : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _selected?.id == s.id ? AdminColors.primary : AdminColors.border,
                            width: _selected?.id == s.id ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                            radius: 18, backgroundColor: AdminColors.field,
                            child: const Icon(Icons.handyman_outlined, size: 18, color: AdminColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.name, style: ts(14.5, w: FontWeight.w700)),
                            Text(s.durationLabel, style: ts(11, color: AdminColors.grey)),
                          ]),
                        ),
                        Text(formatMoney(s.price), style: ts(16, w: FontWeight.w700)),
                        Text(s.priceType == 'hourly' ? '/hr' : ' fixed', style: ts(10.5, color: AdminColors.grey)),
                      ]),
                    ),
                  ),
                ),
            ]);
          },
        ),
        const SizedBox(height: 12),
        Row(children: [
          _stat(Icons.build_circle_outlined, '${p.completedCount}${p.completedCount >= 100 ? '+' : ''}', 'Jobs Done', AdminColors.chipBg),
          const SizedBox(width: 8),
          _stat(Icons.schedule_rounded, '${p.onTimePct.round()}%', 'On-time', AdminColors.orangeBg),
          const SizedBox(width: 8),
          _stat(Icons.star_border_rounded, p.rating.toStringAsFixed(1), 'Avg Rating', AdminColors.chipBg),
        ]),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('About ${p.name.split(' ').first}', style: ts(16, w: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(p.bio.isEmpty ? 'This provider has not added a bio yet.' : p.bio,
                style: ts(12.5, height: 1.5, color: AdminColors.grey)),
          ]),
        ),
        const SizedBox(height: 12),
        _reviewsCard(p),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label, Color bg) => Expanded(
        child: AdminCard(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(children: [
            CircleAvatar(radius: 16, backgroundColor: bg, child: Icon(icon, size: 17, color: AdminColors.primary)),
            const SizedBox(height: 6),
            Text(value, style: ts(16, w: FontWeight.w700)),
            Text(label, style: ts(10.5, color: AdminColors.grey)),
          ]),
        ),
      );

  Widget _reviewsCard(ProviderProfile p) => StreamBuilder<List<ReviewModel>>(
        stream: _reviews,
        builder: (context, snap) {
          final list = snap.data ?? const <ReviewModel>[];
          return AdminCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Customer Reviews', style: ts(16, w: FontWeight.w700)),
                    Text('100% verified homeowners', style: ts(10.5, color: AdminColors.grey)),
                  ]),
                ),
                StatusPill('\u2605 ${p.rating.toStringAsFixed(1)}', tone: Tone.blue, size: 13),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  for (var star = 5; star >= 1; star--)
                    Builder(builder: (_) {
                      final n = list.where((r) => r.rating.round() == star).length;
                      final pct = list.isEmpty ? 0.0 : n / list.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          SizedBox(width: 26, child: Text('$star\u2605', style: ts(11))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                  value: pct, minHeight: 6, backgroundColor: AdminColors.chipBg,
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFF92400E))),
                            ),
                          ),
                          SizedBox(width: 38, child: Text('${(pct * 100).round()}%',
                              textAlign: TextAlign.right, style: ts(10.5, color: AdminColors.grey))),
                        ]),
                      );
                    }),
                ]),
              ),
              const SizedBox(height: 10),
              if (list.isEmpty)
                Text('No reviews yet.', style: ts(12, color: AdminColors.grey))
              else
                for (final r in list.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        AdminAvatar(name: r.customerName, photoUrl: r.photoUrl, radius: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(r.customerName, style: ts(13, w: FontWeight.w700)),
                            Text(timeAgo(r.createdAt), style: ts(10.5, color: AdminColors.grey)),
                          ]),
                        ),
                        Row(children: [
                          for (var i = 1; i <= 5; i++)
                            Icon(i <= r.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 14, color: AdminColors.orange),
                        ]),
                      ]),
                      if (r.comment.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(r.comment, style: ts(12, height: 1.45)),
                        ),
                      if (r.replyText != null)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: AdminColors.field, borderRadius: BorderRadius.circular(10),
                              border: const Border(left: BorderSide(color: AdminColors.primary, width: 3))),
                          child: Text('${p.name.split(' ').first}: ${r.replyText}',
                              style: ts(11.5, color: AdminColors.grey)),
                        ),
                    ]),
                  ),
            ]),
          );
        },
      );

  Widget _bottomBar(ProviderProfile p) {
    final label = _reserved
        ? 'Slot Reserved'
        : _selected == null
            ? 'Select a service'
            : widget.emergency
                ? 'Request Emergency Booking'
                : 'Reserve Slot';
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.of(context).viewPadding.bottom),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -2)),
      ]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AdminButton(label,
            kind: ButtonKind.filled,
            icon: _reserved ? Icons.check_circle_outline_rounded : null,
            height: 50,
            onPressed: _reserved || _selected == null ? null : () => _reserve(p)),
        if (_reserved)
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              CustomerNav.goTab(2);
            },
            child: const Text('View my bookings'),
          ),
      ]),
    );
  }
}

class _ReserveSheet extends StatefulWidget {
  const _ReserveSheet({required this.provider, required this.service, required this.emergency});
  final ProviderProfile provider;
  final ServiceItem service;
  final bool emergency;

  @override
  State<_ReserveSheet> createState() => _ReserveSheetState();
}

class _ReserveSheetState extends State<_ReserveSheet> {
  final _repo = CustomerRepository.instance;
  final _key = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  List<SavedAddress> _saved = const [];

  @override
  void initState() {
    super.initState();
    _repo.getAddresses().then((l) {
      if (!mounted) return;
      setState(() {
        _saved = l;
        final def = l.where((a) => a.isDefault).toList();
        if (def.isNotEmpty) _address.text = def.first.address;
      });
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime get _when => widget.emergency
      ? DateTime.now().add(const Duration(minutes: 30))
      : DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    if (!widget.emergency) {
      final err = validateSlot(widget.provider, _when);
      if (err != null) {
        showAdminSnack(context, err, error: true);
        return;
      }
    }
    final ok = await runAdminAction(
      context,
      () => _repo.createBooking(
        provider: widget.provider,
        service: widget.service,
        scheduledAt: _when,
        address: _address.text,
        notes: _notes.text,
        emergency: widget.emergency,
      ),
      success: widget.emergency ? 'Emergency request sent' : 'Slot reserved. Waiting for confirmation.',
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.emergency ? 'Emergency booking' : 'Reserve a slot', style: ts(18, w: FontWeight.w700)),
            Text('${widget.service.name} with ${widget.provider.name}  |  ${formatMoney(widget.service.price)}${widget.service.priceType == 'hourly' ? '/hr' : ''} cash',
                style: ts(11.5, color: AdminColors.grey)),
            const SizedBox(height: 14),
            if (widget.emergency)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AdminColors.redBg, borderRadius: BorderRadius.circular(12)),
                child: Text('The provider is alerted immediately and has 15 minutes to accept. Target arrival: about 30 minutes.',
                    style: ts(11.5, color: const Color(0xFF7F1D1D))),
              )
            else
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)));
                      if (d != null) setState(() => _date = d);
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(formatDate(_date, 'EEE, MMM d')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: _time);
                      if (t != null) setState(() => _time = t);
                    },
                    icon: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text(_time.format(context)),
                  ),
                ),
              ]),
            const SizedBox(height: 12),
            if (_saved.isNotEmpty)
              Wrap(spacing: 8, children: [
                for (final a in _saved)
                  ActionChip(label: Text(a.label), onPressed: () => setState(() => _address.text = a.address)),
              ]),
            const SizedBox(height: 8),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Service address', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().length < 5) ? 'Enter the full address' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Notes for the provider (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            AdminButton(widget.emergency ? 'Send emergency request' : 'Confirm reservation',
                kind: ButtonKind.filled, height: 50, onPressed: _submit),
          ]),
        ),
      ),
    );
  }
}
