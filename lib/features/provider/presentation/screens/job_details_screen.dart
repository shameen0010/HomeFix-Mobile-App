import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/job_actions.dart';
import '../widgets/provider_header.dart';
import 'active_service_screen.dart';

/// Request details (pending), job summary (confirmed) and the
/// cash-settlement / close-job screen (after the job is done).
class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key, required this.jobId});
  final String jobId;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final _repo = ProviderRepository.instance;
  late final Stream<JobModel?> _stream = _repo.watchJob(widget.jobId);
  bool _confirmed = false;
  String _providerName = 'Provider';

  @override
  void initState() {
    super.initState();
    _repo.getProfile().then((p) {
      if (p != null && mounted) setState(() => _providerName = p.name);
    }).catchError((Object _) {});
  }

  Future<void> _accept(JobModel j) async {
    await acceptJobAction(context, j);
  }

  Future<void> _decline(JobModel j) async {
    final nav = Navigator.of(context);
    await declineJobAction(context, j);
    if (mounted && nav.canPop()) nav.pop();
  }

  Future<void> _start(JobModel j) async {
    final ok = await runAdminAction(context, () => _repo.startJob(j.id), success: 'Job started');
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => ActiveServiceScreen(jobId: j.id)));
    }
  }

  Future<void> _close(JobModel j) async {
    final ok = await runAdminAction(context, () => _repo.confirmReceipt(j.id),
        success: 'Cash receipt confirmed. Job closed.');
    if (ok && mounted) setState(() => _confirmed = false);
  }

  Widget _party(JobModel j) => AdminCard(
        child: Column(children: [
          Row(children: [
            AdminAvatar(name: j.customerName, photoUrl: j.customerPhotoUrl, radius: 24,
                badgeColor: AdminColors.primary, badgeIcon: Icons.check),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(j.customerName, style: ts(16, w: FontWeight.w700)),
                Text('Verified Homeowner  |  ${j.address}',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: ts(11, color: AdminColors.grey)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(j.title, style: ts(13.5, w: FontWeight.w700))),
                Text(j.code, style: ts(11, w: FontWeight.w600, color: AdminColors.grey)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.schedule_rounded, size: 14, color: AdminColors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    j.isDone || j.status == 'completed'
                        ? 'Completed ${formatDate(j.completedAt ?? j.finishedAt, 'MMM d, h:mm a')}'
                            '${j.durationMin == null ? '' : ' (${j.durationMin}m)'}'
                        : 'Scheduled ${formatDate(j.scheduledAt, 'EEE, MMM d, h:mm a')}',
                    style: ts(11.5, color: AdminColors.grey),
                  ),
                ),
              ]),
              if ((j.customerNotes ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Customer notes: ${j.customerNotes}', style: ts(11.5)),
              ],
            ]),
          ),
        ]),
      );

  Widget _settlement(JobModel j) => AdminCard(
        child: Column(children: [
          const CircleAvatar(
              radius: 26, backgroundColor: AdminColors.chipBg,
              child: Icon(Icons.payments_outlined, color: AdminColors.primary, size: 26)),
          const SizedBox(height: 8),
          Text(j.status == 'pending' ? 'Estimated Payout' : 'Total Direct Settlement',
              style: ts(12, color: AdminColors.grey)),
          Text(formatMoney(j.amount), style: ts(32, w: FontWeight.w700)),
          const StatusPill('Cash Payment on Site', size: 10.5, icon: Icons.payments_outlined),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Job Details', showBack: true),
        Expanded(
          child: StreamBuilder<JobModel?>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load the job.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final j = snap.data;
              if (j == null) return const ErrorView(message: 'This job no longer exists.');
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _settlement(j),
                  const SizedBox(height: 12),
                  _party(j),
                  if (j.isDone || j.status == 'completed') ..._proof(j),
                  const SizedBox(height: 14),
                  ..._actions(j),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  List<Widget> _proof(JobModel j) => [
        const SizedBox(height: 12),
        AdminCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionTitle('Inspection Proof',
                icon: Icons.verified_user_outlined,
                trailing: Text('${j.photos.length} Photos Attached',
                    style: ts(10.5, color: AdminColors.grey))),
            const SizedBox(height: 10),
            if (j.photos.isEmpty)
              Text('No photos were attached to this job.', style: ts(11.5, color: AdminColors.grey))
            else
              PhotoGrid(photos: j.photos),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.workspace_premium_outlined, color: AdminColors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('HomeFix 30-Day Guarantee', style: ts(12.5, w: FontWeight.w700)),
                    Text('Full workmanship warranty is automatically issued to the customer upon receipt submission.',
                        style: ts(10.5, color: AdminColors.grey)),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ];

  List<Widget> _actions(JobModel j) {
    final back = AdminButton('Back to Dashboard',
        height: 44, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst));

    switch (j.status) {
      case 'pending':
        return [
          AdminButton('Accept Job',
              kind: ButtonKind.filled, icon: Icons.check_circle_outline_rounded, height: 50,
              onPressed: () => _accept(j)),
          const SizedBox(height: 8),
          AdminButton('Decline', kind: ButtonKind.danger, height: 46, onPressed: () => _decline(j)),
        ];
      case 'confirmed':
        return [
          AdminButton('Start Job (En Route)',
              kind: ButtonKind.filled, icon: Icons.directions_car_rounded, height: 50,
              onPressed: () => _start(j)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: AdminButton('Chat', icon: Icons.chat_bubble_outline_rounded, height: 46,
                onPressed: () => openChat(context, j))),
          ]),
        ];
      case 'in_progress':
        if (!j.isDone) {
          return [
            AdminButton('Resume Live Job',
                kind: ButtonKind.filled, icon: Icons.play_arrow_rounded, height: 50,
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                    builder: (_) => ActiveServiceScreen(jobId: j.id)))),
          ];
        }
        return [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border)),
            child: CheckboxListTile(
              value: _confirmed,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              title: Text(
                'I, $_providerName, confirm that I have physically received ${formatMoney(j.amount)} from ${j.customerName} for completed repair work.',
                style: ts(12),
              ),
              subtitle: Text('This entry will reconcile your daily cash register and close the service ticket.',
                  style: ts(10.5, color: AdminColors.grey)),
            ),
          ),
          const SizedBox(height: 12),
          AdminButton('Confirm Receipt & Close Job',
              kind: ButtonKind.filled, icon: Icons.check_circle_outline_rounded, height: 50,
              onPressed: _confirmed ? () => _close(j) : null),
          const SizedBox(height: 8),
          _receiptButton(j),
          const SizedBox(height: 8),
          back,
        ];
      case 'completed':
        return [
          const Center(child: StatusPill('Closed - cash receipt confirmed', tone: Tone.green, icon: Icons.check_circle_outline_rounded)),
          const SizedBox(height: 12),
          _receiptButton(j),
          const SizedBox(height: 8),
          back,
        ];
      default:
        return [
          Center(child: StatusPill('This booking was ${j.status}', tone: Tone.red)),
          const SizedBox(height: 12),
          back,
        ];
    }
  }

  Widget _receiptButton(JobModel j) => AdminButton('Send Digital Receipt to Customer',
      icon: Icons.receipt_long_outlined, height: 46,
      onPressed: () => runAdminAction(context, () => _repo.sendReceipt(j),
          success: 'Receipt sent to ${j.customerName}'));
}
