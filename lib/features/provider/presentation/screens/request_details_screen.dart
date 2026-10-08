import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/provider_ui.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/job_actions.dart';
import '../widgets/job_format.dart';
import '../widgets/provider_header.dart';

/// Job Details for a pending request (countdown, client, task, photos).
class RequestDetailsScreen extends StatefulWidget {
  const RequestDetailsScreen({super.key, required this.jobId});
  final String jobId;

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final _repo = ProviderRepository.instance;
  late final Stream<JobModel?> _stream = _repo.watchJob(widget.jobId);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _countdown(DateTime? exp) {
    if (exp == null) return 'Awaiting your response';
    final left = exp.difference(DateTime.now());
    if (left.isNegative) return 'Expired';
    final m = left.inMinutes.toString().padLeft(2, '0');
    final s = (left.inSeconds % 60).toString().padLeft(2, '0');
    return 'Expires in $m:$s';
  }

  Future<void> _map(JobModel j) async {
    try {
      final ok = await launchUrl(
          Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': j.address}),
          mode: LaunchMode.externalApplication);
      if (!ok && mounted) showAdminSnack(context, 'Could not open maps.', error: true);
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Could not open maps.', error: true);
    }
  }

  void _inspect(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(40), child: Icon(Icons.broken_image_outlined, size: 48))),
        ),
      ),
    );
  }

  Future<void> _decline(JobModel j) async {
    final nav = Navigator.of(context);
    await declineJobAction(context, j);
    if (mounted && nav.canPop() && j.id.isNotEmpty) {
      // After a successful decline the booking no longer belongs to us.
      final still = await _repo.getJob(j.id);
      if (still == null || still.providerId != _repo.uid) {
        if (mounted && nav.canPop()) nav.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Job Details', showBack: true),
        Expanded(
          child: StreamBuilder<JobModel?>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load the request.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final j = snap.data;
              if (j == null) return const ErrorView(message: 'This request is no longer available.');
              return _body(j);
            },
          ),
        ),
      ]),
    );
  }

  Widget _body(JobModel j) {
    final expired = j.expiresAt != null && j.expiresAt!.isBefore(DateTime.now());
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Row(children: [
              Text('Request ID ', style: ts(12, color: AdminColors.grey)),
              Text(j.code, style: ts(17, w: FontWeight.w700, color: AdminColors.primary)),
              const Spacer(),
              const StatusPill('Pending', tone: Tone.orange, icon: Icons.circle, size: 10.5),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AdminColors.orangeBg, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.hourglass_top_rounded, color: Color(0xFFB45309)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pending Acceptance', style: ts(14.5, w: FontWeight.w700, color: const Color(0xFF92400E))),
                    Text(_countdown(j.expiresAt), style: ts(11.5, color: const Color(0xFFB45309))),
                  ]),
                ),
                const CircleAvatar(radius: 18, backgroundColor: Colors.white,
                    child: Icon(Icons.bolt_rounded, size: 20, color: AdminColors.orange)),
              ]),
            ),
            const SizedBox(height: 12),
            AdminCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('CLIENT PROFILE', style: ts(10, w: FontWeight.w700, color: AdminColors.grey)),
                  const Spacer(),
                  const Icon(Icons.verified_user_outlined, size: 13, color: AdminColors.primary),
                  const SizedBox(width: 3),
                  Text('Verified Resident', style: ts(10, w: FontWeight.w600, color: AdminColors.primary)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  AdminAvatar(name: j.customerName, photoUrl: j.customerPhotoUrl, radius: 28,
                      badgeColor: AdminColors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(j.customerName, style: ts(18, w: FontWeight.w700)),
                      Row(children: [
                        Flexible(
                          child: Text(
                              j.customerSince == null ? 'Verified customer' : 'Member since ${j.customerSince!.year}',
                              style: ts(11, color: AdminColors.grey)),
                        ),
                        if (j.customerRating != null) ...[
                          Text('  \u2022  ', style: ts(11, color: AdminColors.grey)),
                          const Icon(Icons.star_rounded, size: 14, color: AdminColors.orange),
                          Text(
                              '${j.customerRating!.toStringAsFixed(1)}${j.customerRepairs == null ? '' : ' (${j.customerRepairs} repairs)'}',
                              style: ts(11, w: FontWeight.w700, color: const Color(0xFF92400E))),
                        ],
                      ]),
                    ]),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Message',
                    onPressed: () => openChat(context, j),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            AdminCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.build_rounded, color: AdminColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(j.title, style: ts(17, w: FontWeight.w700)),
                      if ((j.description ?? '').isNotEmpty)
                        Text(j.description!, style: ts(11.5, color: AdminColors.grey)),
                    ]),
                  ),
                  StatusPill(j.isEmergency ? 'Urgent Task' : 'Standard Task',
                      tone: j.isEmergency ? Tone.red : Tone.blue, size: 10),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AdminColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                            j.scheduledAt == null
                                ? 'Time not set'
                                : '${formatDate(j.scheduledAt, 'EEEE, MMM d')}  \u2022  ${formatDate(j.scheduledAt, 'h:mm a')}',
                            style: ts(12.5, w: FontWeight.w700)),
                        if (j.durationLabel.isNotEmpty)
                          Text('Estimated duration: ${j.durationLabel}', style: ts(10.5, color: AdminColors.grey)),
                      ]),
                    ),
                    const Icon(Icons.schedule_rounded, size: 18, color: AdminColors.grey),
                  ]),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const CircleAvatar(radius: 16, backgroundColor: AdminColors.chipBg,
                        child: Icon(Icons.place_outlined, size: 17, color: AdminColors.primary)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(j.address, style: ts(12.5, w: FontWeight.w700)),
                        if (j.distanceLabel.isNotEmpty)
                          Text(j.distanceLabel, style: ts(10.5, color: AdminColors.primary)),
                      ]),
                    ),
                    AdminButton('Map', kind: ButtonKind.tonal, icon: Icons.near_me_outlined, height: 36,
                        onPressed: () => _map(j)),
                  ]),
                ),
                if ((j.accessInstructions ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.vpn_key_outlined, size: 15, color: AdminColors.primary),
                        const SizedBox(width: 6),
                        Text('ACCESS INSTRUCTIONS', style: ts(9.5, w: FontWeight.w700, color: AdminColors.grey)),
                      ]),
                      const SizedBox(height: 4),
                      Text('"${j.accessInstructions}"', style: ts(12, w: FontWeight.w600, height: 1.4)),
                    ]),
                  ),
                ],
                if ((j.customerNotes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Customer notes: "${j.customerNotes}"',
                      style: ts(11.5, color: AdminColors.grey).copyWith(fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Text('Customer Photos (${j.customerPhotos.length})', style: ts(13.5, w: FontWeight.w700))),
                  if (j.customerPhotos.isNotEmpty)
                    Text('Tap to inspect', style: ts(10.5, color: AdminColors.grey)),
                ]),
                const SizedBox(height: 8),
                if (j.customerPhotos.isEmpty)
                  Text('The customer did not attach photos.', style: ts(11.5, color: AdminColors.grey))
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.3,
                    children: [
                      for (final url in j.customerPhotos)
                        GestureDetector(
                          onTap: () => _inspect(url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(url, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: AdminColors.field,
                                    child: const Icon(Icons.broken_image_outlined, color: AdminColors.grey))),
                          ),
                        ),
                    ],
                  ),
              ]),
            ),
          ],
        ),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.of(context).viewPadding.bottom),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -2)),
        ]),
        child: Row(children: [
          Expanded(
            child: AdminButton('Decline', kind: ButtonKind.danger, icon: Icons.close_rounded, height: 52,
                onPressed: () => _decline(j)),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: AdminButton(expired ? 'Request expired' : 'Accept Job',
                kind: ButtonKind.filled, icon: Icons.check_circle_outline_rounded, height: 52,
                onPressed: expired ? null : () => acceptJobAction(context, j)),
          ),
        ]),
      ),
    ]);
  }
}
