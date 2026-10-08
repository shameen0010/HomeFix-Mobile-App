import 'package:flutter/material.dart';

import '../../../core/admin_format.dart';
import '../../../core/admin_theme.dart';
import '../../../core/admin_widgets.dart';
import '../../../data/models/provider_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../widgets/provider_actions.dart';
import 'provider_detail_screen.dart';

enum _Filter { all, pending, verified, rejected }

class ProvidersTab extends StatefulWidget {
  const ProvidersTab({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<ProvidersTab> createState() => _ProvidersTabState();
}

class _ProvidersTabState extends State<ProvidersTab> {
  late final Stream<List<ProviderModel>> _stream =
      widget.repository.watchProviders();
  _Filter _filter = _Filter.all;
  String _query = '';

  List<ProviderModel> _apply(List<ProviderModel> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      final byFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.pending => p.status == 'pending',
        _Filter.verified => p.status == 'approved',
        _Filter.rejected => p.status == 'rejected',
      };
      final byQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.trade.toLowerCase().contains(q) ||
          p.licenseNo.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q);
      return byFilter && byQuery;
    }).toList();
  }

  Widget _metric(Widget lead, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          lead,
          const SizedBox(width: 5),
          Text(text, style: ts(11.5, w: FontWeight.w600)),
        ],
      );

  Widget _dot(Color c) => Container(
      width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProviderModel>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return ErrorView(message: 'Could not load providers.\n${snap.error}');
        }
        if (!snap.hasData) return const LoadingView();

        final all = snap.data!;
        final visible = _apply(all);
        final verified = all.where((p) => p.status == 'approved').length;
        final pending = all.where((p) => p.status == 'pending').length;
        final rejected = all.where((p) => p.status == 'rejected').length;
        final decided = verified + rejected;
        final rate = decided == 0 ? 100.0 : verified * 100 / decided;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            AdminCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _metric(_dot(AdminColors.primary), '${formatCount(verified)} Verified'),
                  _metric(_dot(AdminColors.orange), '${formatCount(pending)} Pending'),
                  _metric(
                      const Icon(Icons.shield_outlined, size: 14, color: AdminColors.primary),
                      '${rate.toStringAsFixed(1)}% Approved'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AdminSearchBox(
              hint: 'Search pro by name, trade, license...',
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                AdminChoiceChip(
                    label: 'All',
                    count: all.length,
                    selected: _filter == _Filter.all,
                    onTap: () => setState(() => _filter = _Filter.all)),
                AdminChoiceChip(
                    label: 'Pending Verification',
                    count: pending,
                    selected: _filter == _Filter.pending,
                    onTap: () => setState(() => _filter = _Filter.pending)),
                AdminChoiceChip(
                    label: 'Verified',
                    count: verified,
                    selected: _filter == _Filter.verified,
                    onTap: () => setState(() => _filter = _Filter.verified)),
                AdminChoiceChip(
                    label: 'Rejected',
                    count: rejected,
                    selected: _filter == _Filter.rejected,
                    onTap: () => setState(() => _filter = _Filter.rejected)),
              ]),
            ),
            const SizedBox(height: 14),
            if (visible.isEmpty)
              const EmptyView(message: 'No providers match your filters')
            else
              for (final p in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProviderCard(provider: p, repository: widget.repository),
                ),
          ],
        );
      },
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.repository});
  final ProviderModel provider;
  final AdminRepository repository;

  void _open(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          ProviderDetailScreen(providerId: provider.id, repository: repository),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = provider;
    final (chipLabel, chipTone) = providerStatusChip(p.status);
    final badge = switch (p.status) {
      'approved' => AdminColors.primary,
      'pending' => AdminColors.orange,
      'rejected' => AdminColors.red,
      _ => AdminColors.grey,
    };

    final (statusText, statusColor) = switch (p.status) {
      'approved' => (p.isOnline ? 'Active & Online' : 'Active', AdminColors.primary),
      'pending' => ('Pending Vetting', AdminColors.orange),
      'rejected' => ('Inactive', AdminColors.grey),
      _ => ('Suspended', AdminColors.grey),
    };

    final List<Widget> buttons = switch (p.status) {
      'approved' => [
          AdminButton('View Details', onPressed: () => _open(context)),
          AdminButton('Suspend',
              kind: ButtonKind.danger,
              icon: Icons.block_rounded,
              onPressed: () => suspendProviderAction(context, repository, p)),
        ],
      'pending' => [
          AdminButton('Review Docs', onPressed: () => _open(context)),
          AdminButton('Verify Now',
              kind: ButtonKind.filled,
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => approveProviderAction(context, repository, p)),
        ],
      'rejected' => [
          AdminButton('View Audit Log',
              onPressed: () => showAuditLogSheet(context, repository, p)),
          AdminButton('Re-evaluate',
              icon: Icons.refresh_rounded,
              onPressed: () => reEvaluateProviderAction(context, repository, p)),
        ],
      _ => [
          AdminButton('View Details', onPressed: () => _open(context)),
          AdminButton('Reinstate',
              kind: ButtonKind.filled,
              onPressed: () => reinstateProviderAction(context, repository, p)),
        ],
    };

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminAvatar(name: p.name, photoUrl: p.photoUrl, badgeColor: badge),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ts(16, w: FontWeight.w600)),
                      ),
                      if (p.isApproved) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded,
                            size: 16, color: AdminColors.primary),
                      ],
                    ]),
                    Text(
                      p.isPending
                          ? '${p.trade}  |  App ID #${p.appId}'
                          : '${p.trade}  |  Lic #${p.licenseNo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ts(12, color: AdminColors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(chipLabel, tone: chipTone),
            ],
          ),
          if (p.isPending) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AdminColors.orangeBg,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.assignment_late_outlined,
                    size: 18, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Action Needed: License Verification',
                          style: ts(12, w: FontWeight.w700, color: const Color(0xFF92400E))),
                      Text('Submitted ${timeAgo(p.submittedAt)}',
                          style: ts(11, color: const Color(0xFF92400E))),
                    ],
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.place_outlined, size: 15, color: AdminColors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(p.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(12, color: AdminColors.grey)),
            ),
            if (p.isApproved) ...[
              const Icon(Icons.star_rounded, size: 16, color: AdminColors.orange),
              const SizedBox(width: 2),
              Text(p.rating.toStringAsFixed(1), style: ts(12, w: FontWeight.w700)),
              Text(' (${p.reviewCount} reviews)',
                  style: ts(11, color: AdminColors.grey)),
            ] else if (p.status == 'rejected' && (p.statusReason ?? '').isNotEmpty)
              Flexible(
                child: Text(p.statusReason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(11, color: AdminColors.grey)),
              ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(11.5, w: FontWeight.w600, color: statusColor)),
            ),
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              buttons[i],
            ],
          ]),
        ],
      ),
    );
  }
}
