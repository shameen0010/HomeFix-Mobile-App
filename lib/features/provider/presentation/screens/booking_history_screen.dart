import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/provider_ui.dart';
import '../../data/models/job_model.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/provider_repository.dart';
import '../../data/services/provider_receipt.dart';
import '../widgets/job_format.dart';
import '../widgets/provider_header.dart';

/// Completed jobs with cash receipt, customer review and re-usable job notes.
class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final _repo = ProviderRepository.instance;
  late final Stream<List<JobModel>> _jobs = _repo.watchJobs();
  late final Stream<List<ReviewModel>> _reviews = _repo.watchReviews();
  String _filter = 'all'; // all | month | category name

  void _jobNote(JobModel j) {
    final lines = <String>[
      '${j.title} (${j.code}) at ${j.address}',
      if ((j.customerNotes ?? '').isNotEmpty) 'Customer notes: ${j.customerNotes}',
      if ((j.accessInstructions ?? '').isNotEmpty) 'Access: ${j.accessInstructions}',
      for (final n in j.notes) 'Inspection note: $n',
      for (final c in j.checklist) '${c.done ? '[x]' : '[ ]'} ${c.title}',
    ];
    final text = lines.join('\n');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Theme(
        data: adminTheme,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionTitle('Repeat Job Note', icon: Icons.edit_note_rounded),
              const SizedBox(height: 4),
              Text('Reuse what you did last time for ${j.customerName}.', style: ts(11.5, color: AdminColors.grey)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                child: Text(text, style: ts(12, height: 1.5)),
              ),
              const SizedBox(height: 12),
              AdminButton('Copy to clipboard', kind: ButtonKind.filled, icon: Icons.copy_rounded, height: 46,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                      showAdminSnack(context, 'Job note copied');
                    }
                  }),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Booking History', showBack: true),
        Expanded(
          child: StreamBuilder<List<JobModel>>(
            stream: _jobs,
            builder: (context, js) {
              if (js.hasError) return ErrorView(message: 'Could not load history.\n${js.error}');
              if (!js.hasData) return const LoadingView();
              return StreamBuilder<List<ReviewModel>>(
                stream: _reviews,
                builder: (context, rs) {
                  final reviews = {for (final r in rs.data ?? const <ReviewModel>[]) r.id: r};
                  final done = js.data!.where((j) => j.status == 'completed').toList()
                    ..sort((a, b) => (b.earnedAt ?? DateTime(2000)).compareTo(a.earnedAt ?? DateTime(2000)));
                  final now = DateTime.now();
                  bool thisMonth(JobModel j) =>
                      j.earnedAt != null && j.earnedAt!.year == now.year && j.earnedAt!.month == now.month;
                  final cats = done.map((j) => j.category).toSet().toList()..sort();
                  final shown = done.where((j) {
                    if (_filter == 'all') return true;
                    if (_filter == 'month') return thisMonth(j);
                    return j.category == _filter;
                  }).toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          AdminChoiceChip(label: 'All', count: done.length, selected: _filter == 'all',
                              onTap: () => setState(() => _filter = 'all')),
                          AdminChoiceChip(label: 'This Month', count: done.where(thisMonth).length,
                              selected: _filter == 'month', onTap: () => setState(() => _filter = 'month')),
                          for (final c in cats)
                            AdminChoiceChip(label: c, count: done.where((j) => j.category == c).length,
                                selected: _filter == c, onTap: () => setState(() => _filter = c)),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: Text('Recent Services', style: ts(17, w: FontWeight.w700))),
                        Text('SORTED BY DATE', style: ts(10, w: FontWeight.w700, color: AdminColors.grey)),
                      ]),
                      const SizedBox(height: 10),
                      if (shown.isEmpty)
                        const EmptyView(message: 'No completed jobs yet', icon: Icons.history_rounded)
                      else
                        for (final j in shown)
                          Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(j, reviews[j.id])),
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

  Widget _card(JobModel j, ReviewModel? r) {
    final when = j.earnedAt;
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdminAvatar(name: j.customerName, photoUrl: j.customerPhotoUrl, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(j.customerName, style: ts(16, w: FontWeight.w700)),
                Text(j.code, style: ts(10.5, w: FontWeight.w700, color: AdminColors.primary)),
              ]),
              Text(j.address, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: ts(11, color: AdminColors.grey)),
            ]),
          ),
          StatusPill(j.customerAttested ? 'Settled & Closed' : 'Settled', size: 9.5),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Row(children: [
              Expanded(child: Text(j.title, style: ts(13, w: FontWeight.w700))),
              Text(formatMoney(j.amount), style: ts(14.5, w: FontWeight.w700, color: AdminColors.primary)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 14, color: AdminColors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                    when == null ? '-' : '${dayWord(when)}, ${formatDate(when, 'MMM d')}  \u2022  ${formatDate(when, 'h:mm a')}',
                    style: ts(11, color: AdminColors.grey)),
              ),
              const StatusPill('Cash Collected', tone: Tone.orange, icon: Icons.payments_outlined, size: 9.5),
            ]),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AdminColors.bg, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.border)),
          child: Row(children: [
            StatusPill(r == null ? 'No review' : '${r.rating.toStringAsFixed(1)} \u2605',
                tone: r == null ? Tone.grey : Tone.orange, size: 10),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  r == null || r.comment.isEmpty ? 'The customer has not left a comment.' : '"${r.comment}"',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: ts(11.5, color: AdminColors.grey).copyWith(fontStyle: FontStyle.italic)),
            ),
            const Icon(Icons.shield_outlined, size: 17, color: AdminColors.grey),
          ]),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          AdminButton('View Cash Receipt', icon: Icons.receipt_long_outlined, height: 38,
              onPressed: () => runAdminAction(context, () => ProviderReceipt.share(j), success: 'Receipt ready')),
          const SizedBox(width: 8),
          AdminButton('Repeat Job Note', icon: Icons.edit_note_rounded, height: 38, onPressed: () => _jobNote(j)),
        ]),
      ]),
    );
  }
}
