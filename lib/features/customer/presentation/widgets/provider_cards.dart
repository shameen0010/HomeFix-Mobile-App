import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import 'availability.dart';
import 'customer_actions.dart';

Widget _ratingChip(ProviderProfile p, {bool withReviews = true}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AdminColors.orangeBg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, size: 14, color: AdminColors.orange),
        const SizedBox(width: 2),
        Text(p.rating.toStringAsFixed(1), style: ts(11.5, w: FontWeight.w700, color: const Color(0xFF92400E))),
        if (withReviews)
          Text(' (${p.reviewCount} reviews)', style: ts(10.5, color: const Color(0xFF92400E))),
      ]),
    );

String rateText(ProviderProfile p) {
  final r = startingRate(p);
  return r == null ? 'Rates on profile' : 'from ${formatMoney(r)} /hr';
}

/// Search result card.
class ProviderListCard extends StatelessWidget {
  const ProviderListCard({
    super.key,
    required this.provider,
    required this.isFavorite,
    required this.onFavorite,
    this.emergency = false,
  });
  final ProviderProfile provider;
  final bool isFavorite, emergency;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final p = provider;
    final a = availabilityOf(p);
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdminAvatar(name: p.name, photoUrl: p.photoUrl, radius: 30,
              badgeColor: AdminColors.primary, badgeIcon: Icons.check),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: ts(17, w: FontWeight.w700)),
              Text(p.headline, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: ts(12, color: AdminColors.grey)),
              const SizedBox(height: 4),
              _ratingChip(p),
            ]),
          ),
          IconButton(
            tooltip: isFavorite ? 'Remove favourite' : 'Add favourite',
            onPressed: onFavorite,
            icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? AdminColors.red : AdminColors.grey),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.near_me_outlined, size: 14, color: AdminColors.grey),
            const SizedBox(width: 3),
            Text(p.coverageArea, style: ts(11.5, color: AdminColors.grey)),
          ]),
          Text(rateText(p), style: ts(12, w: FontWeight.w700)),
          StatusPill(a.label,
              tone: a.today ? Tone.blue : Tone.grey,
              icon: a.today ? Icons.check_circle_outline_rounded : Icons.event_outlined, size: 10.5),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: AdminButton('View Profile',
                kind: ButtonKind.filled, icon: Icons.arrow_forward_rounded, height: 46,
                onPressed: () => openProvider(context, p.id, emergency: emergency)),
          ),
          const SizedBox(width: 8),
          AdminButton('', icon: Icons.chat_bubble_outline_rounded, height: 46,
              onPressed: () => openDirectChat(context, p)),
        ]),
      ]),
    );
  }
}

/// Compact card for the Home "Top Service Provider" list.
class TopProviderCard extends StatelessWidget {
  const TopProviderCard({super.key, required this.provider});
  final ProviderProfile provider;

  @override
  Widget build(BuildContext context) {
    final p = provider;
    return AdminCard(
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdminAvatar(name: p.name, photoUrl: p.photoUrl, radius: 26, badgeColor: AdminColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: ts(15.5, w: FontWeight.w700)),
              Text(p.headline, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: ts(11.5, w: FontWeight.w600, color: AdminColors.primary)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.near_me_outlined, size: 13, color: AdminColors.grey),
                const SizedBox(width: 3),
                Flexible(child: Text(p.coverageArea, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: ts(11, color: AdminColors.grey))),
                Text('  |  ${rateText(p)}', style: ts(11, w: FontWeight.w700)),
              ]),
            ]),
          ),
          _ratingChip(p, withReviews: false),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AdminButton('View Profile', height: 42,
                onPressed: () => openProvider(context, p.id)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AdminButton('Book Now', kind: ButtonKind.filled, height: 42,
                onPressed: () => openProvider(context, p.id)),
          ),
        ]),
      ]),
    );
  }
}
