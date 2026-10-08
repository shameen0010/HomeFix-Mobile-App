import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/provider_profile.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/provider_header.dart';

/// FR-P09: ratings, reviews and provider replies.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _repo = ProviderRepository.instance;
  late final Stream<List<ReviewModel>> _reviews = _repo.watchReviews();
  late final Stream<ProviderProfile?> _profile = _repo.watchProfile();

  Future<void> _reply(ReviewModel r) async {
    final text = await promptText(
      context,
      title: r.replyText == null ? 'Reply to ${r.customerName}' : 'Edit your reply',
      hint: 'Write a short, polite reply',
      initial: r.replyText,
      confirmLabel: 'Post reply',
    );
    if (text == null || !mounted) return;
    await runAdminAction(context, () => _repo.replyToReview(r.id, text), success: 'Reply posted');
  }

  Future<void> _deleteReply(ReviewModel r) async {
    final ok = await confirmAction(context,
        title: 'Delete reply?', message: 'Your reply will be removed from this review.',
        confirmLabel: 'Delete', destructive: true);
    if (!ok || !mounted) return;
    await runAdminAction(context, () => _repo.deleteReply(r.id), success: 'Reply deleted');
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Reviews', showBack: true),
        Expanded(
          child: StreamBuilder<ProviderProfile?>(
            stream: _profile,
            builder: (context, ps) {
              final p = ps.data;
              return StreamBuilder<List<ReviewModel>>(
                stream: _reviews,
                builder: (context, rs) {
                  if (rs.hasError) return ErrorView(message: 'Could not load reviews.\n${rs.error}');
                  if (!rs.hasData) return const LoadingView();
                  final list = rs.data!;
                  final total = list.length;
                  final avg = p != null && p.reviewCount > 0
                      ? p.rating
                      : (total == 0 ? 0.0 : list.fold<double>(0, (s, r) => s + r.rating) / total);
                  final count = p != null && p.reviewCount > 0 ? p.reviewCount : total;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      Text('Ratings & Reviews', style: ts(22, w: FontWeight.w700)),
                      Text('Customer feedback and satisfaction ratings for ${p?.name ?? 'you'}',
                          style: ts(12, color: AdminColors.grey)),
                      const SizedBox(height: 12),
                      AdminCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(avg.toStringAsFixed(1), style: ts(34, w: FontWeight.w700)),
                            Text(' / 5.0', style: ts(14, color: AdminColors.grey)),
                          ]),
                          Row(children: [
                            for (var i = 1; i <= 5; i++)
                              Icon(i <= avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 18, color: AdminColors.orange),
                          ]),
                          const SizedBox(height: 4),
                          Text('Based on $count verified customer reviews',
                              style: ts(11, color: AdminColors.grey)),
                          const SizedBox(height: 10),
                          for (var star = 5; star >= 1; star--) _bar(star, list),
                          if (p != null && p.tags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                              child: Wrap(spacing: 8, runSpacing: 8, children: [
                                for (final t in p.tags)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: Colors.white, borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AdminColors.border)),
                                    child: Text(t, style: ts(11, w: FontWeight.w600)),
                                  ),
                              ]),
                            ),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 12),
                      if (list.isEmpty)
                        const EmptyView(message: 'No reviews yet', icon: Icons.star_border_rounded)
                      else
                        for (final r in list)
                          Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(r, p)),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _bar(int star, List<ReviewModel> list) {
    final n = list.where((r) => r.rating.round() == star).length;
    final pct = list.isEmpty ? 0.0 : n / list.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 26, child: Text('$star \u2605', style: ts(11, color: AdminColors.grey))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct, minHeight: 7, backgroundColor: AdminColors.chipBg,
              valueColor: const AlwaysStoppedAnimation(AdminColors.primary),
            ),
          ),
        ),
        SizedBox(
            width: 38,
            child: Text('${(pct * 100).round()}%',
                textAlign: TextAlign.right, style: ts(10.5, color: AdminColors.grey))),
      ]),
    );
  }

  Widget _card(ReviewModel r, ProviderProfile? p) {
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AdminAvatar(name: r.customerName, photoUrl: r.photoUrl, radius: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(r.customerName, style: ts(14, w: FontWeight.w700))),
                if (r.verified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded, size: 14, color: AdminColors.primary),
                ],
              ]),
              Text('Verified Customer  |  ${timeAgo(r.createdAt)}',
                  style: ts(10.5, color: AdminColors.grey)),
            ]),
          ),
          StatusPill('${r.rating.toStringAsFixed(1)} \u2605', tone: Tone.orange, size: 11),
        ]),
        if (r.service.isNotEmpty) ...[
          const SizedBox(height: 8),
          StatusPill(r.service, icon: Icons.build_rounded, size: 10.5),
        ],
        if (r.comment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('"${r.comment}"', style: ts(12.5, height: 1.5).copyWith(fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 10),
        if (r.replyText != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AdminColors.field, borderRadius: BorderRadius.circular(12),
                border: const Border(left: BorderSide(color: AdminColors.primary, width: 3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(p?.name ?? 'You', style: ts(12, w: FontWeight.w700)),
                const SizedBox(width: 6),
                const StatusPill('Pro Provider', size: 9),
                const Spacer(),
                InkWell(onTap: () => _reply(r), child: const Icon(Icons.edit_outlined, size: 16, color: AdminColors.grey)),
                const SizedBox(width: 10),
                InkWell(onTap: () => _deleteReply(r), child: const Icon(Icons.delete_outline_rounded, size: 16, color: AdminColors.red)),
              ]),
              const SizedBox(height: 4),
              Text(r.replyText!, style: ts(12, color: AdminColors.grey)),
            ]),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: AdminButton('Reply', icon: Icons.reply_rounded, height: 36, onPressed: () => _reply(r)),
          ),
      ]),
    );
  }
}
