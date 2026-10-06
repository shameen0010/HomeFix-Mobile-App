import 'package:flutter/material.dart';

import '../../core/admin_feedback.dart';
import '../../core/admin_format.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_widgets.dart';
import '../../data/models/dispute_model.dart';
import '../../data/repositories/admin_repository.dart';

enum _Filter { all, complaints, reviews, pending }

(String, Tone) _statusChip(String s) {
  switch (s) {
    case 'pending':
      return ('Pending', Tone.orange);
    case 'under_review':
      return ('Under Review', Tone.blue);
    case 'resolved':
      return ('Resolved', Tone.green);
    case 'archived':
      return ('Archived', Tone.grey);
    default:
      return (s, Tone.grey);
  }
}

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  late final Stream<List<DisputeModel>> _stream = widget.repository.watchDisputes();
  _Filter _filter = _Filter.all;
  String _query = '';

  List<DisputeModel> _apply(List<DisputeModel> all) {
    final q = _query.trim().toLowerCase();
    return all.where((d) {
      final byFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.complaints => !d.isReview,
        _Filter.reviews => d.isReview,
        _Filter.pending => d.status == 'pending',
      };
      final byQuery = q.isEmpty ||
          d.customerName.toLowerCase().contains(q) ||
          d.providerName.toLowerCase().contains(q) ||
          d.bookingNo.toLowerCase().contains(q) ||
          d.service.toLowerCase().contains(q);
      return byFilter && byQuery;
    }).toList();
  }

  void _openDetails(DisputeModel d) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DisputeSheet(dispute: d, repository: widget.repository),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(
        children: [
          AdminHeader(
              screenTitle: 'Job Dispute Resolution',
              onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: StreamBuilder<List<DisputeModel>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorView(message: 'Could not load disputes.\n${snap.error}');
                }
                if (!snap.hasData) return const LoadingView();

                final all = snap.data!;
                final visible = _apply(all);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    AdminSearchBox(
                      hint: 'Search by user, provider, or booking ID...',
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
                            label: 'Complaints',
                            count: all.where((d) => !d.isReview).length,
                            selected: _filter == _Filter.complaints,
                            onTap: () => setState(() => _filter = _Filter.complaints)),
                        AdminChoiceChip(
                            label: 'Reviews',
                            count: all.where((d) => d.isReview).length,
                            selected: _filter == _Filter.reviews,
                            onTap: () => setState(() => _filter = _Filter.reviews)),
                        AdminChoiceChip(
                            label: 'Pending',
                            count: all.where((d) => d.status == 'pending').length,
                            selected: _filter == _Filter.pending,
                            onTap: () => setState(() => _filter = _Filter.pending)),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    if (visible.isEmpty)
                      const EmptyView(message: 'No disputes found', icon: Icons.gavel_rounded)
                    else
                      for (final d in visible)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DisputeCard(dispute: d, onView: () => _openDetails(d)),
                        ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 78, child: Text('$label:', style: ts(11.5, color: AdminColors.grey))),
        Expanded(
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts(12, w: FontWeight.w600)),
        ),
      ]),
    );

Widget _stars(double? rating) {
  if (rating == null) return const SizedBox.shrink();
  return Row(mainAxisSize: MainAxisSize.min, children: [
    for (var i = 1; i <= 5; i++)
      Icon(i <= rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16, color: AdminColors.orange),
    const SizedBox(width: 6),
    Text(rating.toStringAsFixed(1), style: ts(12, w: FontWeight.w700)),
  ]);
}

class _DisputeCard extends StatelessWidget {
  const _DisputeCard({required this.dispute, required this.onView});
  final DisputeModel dispute;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final d = dispute;
    final (label, tone) = _statusChip(d.status);
    final archived = d.status == 'archived';
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(d.isReview ? Icons.rate_review_outlined : Icons.report_gmailerrorred_rounded,
                size: 18, color: AdminColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(d.title, style: ts(14, w: FontWeight.w700)),
            ),
            StatusPill(label, tone: tone, size: 10),
          ]),
          const SizedBox(height: 4),
          Text('${d.bookingNo}  |  ${timeAgo(d.createdAt)}',
              style: ts(10.5, color: AdminColors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _row('Customer', d.customerName),
              _row('Provider', d.providerName),
              _row('Service', d.service),
            ]),
          ),
          if (d.rating != null) ...[
            const SizedBox(height: 8),
            _stars(d.rating),
          ],
          if (d.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('"${d.comment}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ts(12, color: AdminColors.grey).copyWith(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            if (archived)
              Expanded(
                child: Row(children: [
                  const Icon(Icons.inventory_2_outlined, size: 14, color: AdminColors.grey),
                  const SizedBox(width: 4),
                  Text('Archived record', style: ts(11, color: AdminColors.grey)),
                ]),
              )
            else
              const Spacer(),
            AdminButton(archived ? 'View Summary' : 'View Details',
                height: 36,
                icon: archived ? null : Icons.arrow_forward_rounded,
                onPressed: onView),
          ]),
        ],
      ),
    );
  }
}

class _DisputeSheet extends StatelessWidget {
  const _DisputeSheet({required this.dispute, required this.repository});
  final DisputeModel dispute;
  final AdminRepository repository;

  Future<void> _setStatus(BuildContext context, String status, String success) async {
    final ok = await runAdminAction(
      context,
      () => repository.updateDispute(dispute.id, status: status),
      success: success,
    );
    if (ok && context.mounted) Navigator.pop(context);
  }

  Future<void> _resolve(BuildContext context) async {
    final note = await promptText(
      context,
      title: 'Resolve ${dispute.bookingNo}',
      message: 'Describe the outcome. Both parties can see the resolution.',
      hint: 'Resolution note (e.g. partial refund issued)',
      confirmLabel: 'Resolve',
    );
    if (note == null || !context.mounted) return;
    final ok = await runAdminAction(
      context,
      () => repository.updateDispute(dispute.id, status: 'resolved', resolution: note),
      success: 'Dispute resolved',
    );
    if (ok && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = dispute;
    final (label, tone) = _statusChip(d.status);
    final closed = d.status == 'resolved' || d.status == 'archived';
    return Theme(
      data: adminTheme,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(d.title, style: ts(17, w: FontWeight.w700))),
                StatusPill(label, tone: tone),
              ]),
              const SizedBox(height: 10),
              // Key facts first, long testimonial collapsed (Milestone 02 finding).
              InfoField(label: 'Booking', value: d.bookingNo, icon: Icons.confirmation_number_outlined),
              const SizedBox(height: 8),
              InfoField(label: 'Customer', value: d.customerName, icon: Icons.person_outline),
              const SizedBox(height: 8),
              InfoField(label: 'Provider', value: d.providerName, icon: Icons.engineering_outlined),
              const SizedBox(height: 8),
              InfoField(label: 'Service', value: d.service, icon: Icons.build_outlined),
              if (d.rating != null) ...[
                const SizedBox(height: 8),
                _stars(d.rating),
              ],
              if (d.comment.isNotEmpty)
                Theme(
                  data: adminTheme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text('Customer testimonial', style: ts(13, w: FontWeight.w700)),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(d.comment, style: ts(12.5, color: AdminColors.grey)),
                      ),
                    ],
                  ),
                ),
              if ((d.resolution ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                InfoField(label: 'Resolution', value: d.resolution!, icon: Icons.task_alt_rounded),
              ],
              if (!closed) ...[
                const SizedBox(height: 14),
                AdminButton('Resolve Issue',
                    kind: ButtonKind.filled,
                    icon: Icons.check_circle_outline_rounded,
                    height: 46,
                    onPressed: () => _resolve(context)),
                const SizedBox(height: 8),
                Row(children: [
                  if (d.status == 'pending') ...[
                    Expanded(
                      child: AdminButton('Mark Under Review',
                          height: 42,
                          onPressed: () => _setStatus(context, 'under_review', 'Marked under review')),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: AdminButton('Archive',
                        kind: ButtonKind.danger,
                        height: 42,
                        onPressed: () => _setStatus(context, 'archived', 'Record archived')),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
