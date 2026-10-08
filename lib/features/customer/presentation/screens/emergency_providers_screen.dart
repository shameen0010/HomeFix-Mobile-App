import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../../provider/data/models/service_item.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_draft.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/customer_header.dart';
import 'emergency_confirm_screen.dart';

/// Emergency flow, step 3 of 4: providers that are online and take emergency calls (FR-B01/B04).
class EmergencyProvidersScreen extends StatefulWidget {
  const EmergencyProvidersScreen({super.key, required this.request});
  final EmergencyRequest request;

  @override
  State<EmergencyProvidersScreen> createState() => _EmergencyProvidersScreenState();
}

class _EmergencyProvidersScreenState extends State<EmergencyProvidersScreen> {
  late final Stream<List<ProviderProfile>> _stream = CustomerRepository.instance.watchProviders();

  List<ProviderProfile> _eligible(List<ProviderProfile> all) => all
      .where((p) => p.isApproved && p.catalogActive && p.emergencyEnabled && p.isOnline && widget.request.type.matches(p))
      .toList()
    ..sort((a, b) => b.rating.compareTo(a.rating));

  void _request(ProviderProfile p, ServiceItem s) => Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EmergencyConfirmScreen(request: widget.request, provider: p, service: s)));

  @override
  Widget build(BuildContext context) {
    final t = widget.request.type;
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Select Dispatch Tier', showBack: true),
        Expanded(
          child: StreamBuilder<List<ProviderProfile>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load providers.\n${snap.error}');
              if (!snap.hasData) return const LoadingView();
              final list = _eligible(snap.data!);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  Text('Available Providers', style: ts(22, w: FontWeight.w700)),
                  Text('Choose a provider who is available for your emergency.',
                      style: ts(12, color: AdminColors.grey)),
                  const SizedBox(height: 12),
                  AdminCard(
                    child: Row(children: [
                      CircleAvatar(radius: 20, backgroundColor: AdminColors.orangeBg,
                          child: Icon(t.icon, color: AdminColors.orange, size: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.title, style: ts(13, w: FontWeight.w700)),
                          Text('${list.length} certified ${list.length == 1 ? 'pro' : 'pros'} on standby'
                              '${widget.request.area.trim().isEmpty ? '' : ' in ${widget.request.area.trim()}'}',
                              style: ts(11, color: AdminColors.grey)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  if (list.isEmpty)
                    const EmptyView(
                        message: 'No provider is available for this emergency right now.\nTry another category or book a scheduled slot.',
                        icon: Icons.engineering_outlined)
                  else
                    for (var i = 0; i < list.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProviderTierCard(
                            key: ValueKey(list[i].id),
                            provider: list[i],
                            type: t,
                            recommended: i == 0,
                            onRequest: _request),
                      ),
                  const SizedBox(height: 4),
                  const NoticeBox(
                    icon: Icons.shield_outlined,
                    title: 'HomeFix Emergency Guarantee',
                    text: 'Licensed, insured & background-checked professionals.',
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

class _ProviderTierCard extends StatefulWidget {
  const _ProviderTierCard({super.key, required this.provider, required this.type, required this.recommended, required this.onRequest});
  final ProviderProfile provider;
  final EmergencyType type;
  final bool recommended;
  final void Function(ProviderProfile, ServiceItem) onRequest;

  @override
  State<_ProviderTierCard> createState() => _ProviderTierCardState();
}

class _ProviderTierCardState extends State<_ProviderTierCard> {
  late final Future<List<ServiceItem>> _services = CustomerRepository.instance.getServices(widget.provider.id);

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    return FutureBuilder<List<ServiceItem>>(
      future: _services,
      builder: (context, snap) {
        final s = snap.hasData ? widget.type.pick(snap.data!) : null;
        final fee = s == null ? null : PriceQuote.emergency(s, p).total;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.recommended ? AdminColors.primary : AdminColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.recommended)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(
                      color: AdminColors.primary,
                      borderRadius: BorderRadius.only(topRight: Radius.circular(17), bottomLeft: Radius.circular(12))),
                  child: Text('Recommended', style: ts(10, w: FontWeight.w700, color: Colors.white)),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, widget.recommended ? 0 : 14, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  AdminAvatar(name: p.name, photoUrl: p.photoUrl, radius: 26,
                      badgeColor: AdminColors.primary, badgeIcon: Icons.check),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: ts(16, w: FontWeight.w700)),
                      Text(p.headline, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: ts(11.5, color: AdminColors.grey)),
                      const SizedBox(height: 4),
                      Row(children: [
                        StatusPill('\u2605 ${p.rating.toStringAsFixed(1)} (${p.reviewCount})', tone: Tone.orange, size: 10),
                        const SizedBox(width: 8),
                        Text('${p.experienceYears} Yrs Exp', style: ts(10.5, color: AdminColors.grey)),
                      ]),
                    ]),
                  ),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.circle, size: 8, color: AdminColors.primary),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Available Now \u2022 Fast Dispatch',
                          style: ts(11.5, w: FontWeight.w700, color: AdminColors.primary))),
                      Text(fee == null ? 'Diagnostic: ...' : 'Diagnostic: ${formatMoney(fee)}',
                          style: ts(11, w: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.place_outlined, size: 14, color: AdminColors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(p.coverageArea, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: ts(11, color: AdminColors.grey))),
                    ]),
                  ]),
                ),
                const SizedBox(height: 10),
                if (snap.hasError)
                  Text('Could not load this provider\'s services.', style: ts(11.5, color: AdminColors.red))
                else if (snap.hasData && s == null)
                  Text('No bookable services listed.', style: ts(11.5, color: AdminColors.grey))
                else
                  AdminButton('Request Service',
                      kind: widget.recommended ? ButtonKind.filled : ButtonKind.tonal,
                      icon: Icons.arrow_forward_rounded,
                      height: 46,
                      onPressed: s == null ? null : () => widget.onRequest(p, s)),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
