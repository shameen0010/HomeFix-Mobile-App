import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/job_actions.dart';
import '../widgets/job_format.dart';
import '../widgets/provider_header.dart';
import 'provider_chat_screen.dart' show callCustomer;

/// Customer Details for a confirmed booking (before the trip starts).
class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key, required this.jobId});
  final String jobId;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  late final Stream<JobModel?> _stream = ProviderRepository.instance.watchJob(widget.jobId);

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Customer Details', showBack: true),
        Expanded(
          child: StreamBuilder<JobModel?>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load the booking.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final j = snap.data;
              if (j == null) return const ErrorView(message: 'This booking no longer exists.');
              return _body(j);
            },
          ),
        ),
      ]),
    );
  }

  Widget _body(JobModel j) {
    final first = j.customerName.split(' ').first;
    final parts = j.address.split(',');
    final line1 = parts.first.trim();
    final line2 = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
    final nearby = j.distanceMi != null || j.distanceKm != null
        ? '${(j.distanceMi ?? j.distanceKm! * 0.621371).toStringAsFixed(1)} mi${j.driveMins == null ? '' : '  \u2022  ~${j.driveMins} min'}'
        : null;
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            AdminCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  AdminAvatar(name: j.customerName, photoUrl: j.customerPhotoUrl, radius: 32,
                      badgeColor: AdminColors.primary, badgeIcon: Icons.check),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: Text(j.customerName, style: ts(19, w: FontWeight.w700))),
                        const SizedBox(width: 8),
                        const StatusPill('Homeowner', size: 10),
                      ]),
                      Row(children: [
                        const Icon(Icons.verified_user_outlined, size: 13, color: AdminColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                              j.customerSince == null
                                  ? 'Verified Homeowner'
                                  : 'Verified Homeowner since ${j.customerSince!.year}',
                              style: ts(11, color: AdminColors.grey)),
                        ),
                      ]),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  AdminButton('Message $first', kind: ButtonKind.filled, icon: Icons.chat_bubble_outline_rounded,
                      height: 44, onPressed: () => openChat(context, j)),
                  const SizedBox(width: 8),
                  AdminButton('Call', icon: Icons.phone_outlined, height: 44,
                      onPressed: () => callCustomer(context, j.customerPhone)),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            AdminCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('BOOKING ID', style: ts(10, w: FontWeight.w700, color: AdminColors.grey)),
                  const SizedBox(width: 6),
                  Text(j.code, style: ts(14, w: FontWeight.w700)),
                  const Spacer(),
                  const StatusPill('CONFIRMED', icon: Icons.circle, size: 9.5),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.build_rounded, color: AdminColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(j.title, style: ts(15.5, w: FontWeight.w700)),
                        Row(children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AdminColors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                                '${dayWord(j.scheduledAt)}, ${formatDate(j.scheduledAt, 'MMM d')}  \u2022  ${formatDate(j.scheduledAt, 'h:mm a')}'
                                '${j.durationLabel.isEmpty ? '' : ' (${j.durationLabel})'}',
                                style: ts(10.5, color: AdminColors.grey)),
                          ),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            AdminCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.place_outlined, size: 18, color: AdminColors.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Service Location', style: ts(14.5, w: FontWeight.w700))),
                  if (nearby != null) StatusPill(nearby, tone: Tone.grey, size: 10),
                ]),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(line1, style: ts(13.5, w: FontWeight.w700)),
                    if (line2.isNotEmpty) Text(line2, style: ts(11.5, color: AdminColors.grey)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            AdminCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.vpn_key_outlined, size: 18, color: Color(0xFF92400E)),
                  const SizedBox(width: 6),
                  Text('ACCESS & ENTRY INSTRUCTIONS',
                      style: ts(12, w: FontWeight.w700, color: const Color(0xFF92400E))),
                ]),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AdminColors.orangeBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                      (j.accessInstructions ?? '').isNotEmpty
                          ? '"${j.accessInstructions}"'
                          : (j.customerNotes ?? '').isNotEmpty
                              ? '"${j.customerNotes}"'
                              : 'The customer did not leave any access instructions.',
                      style: ts(12.5, w: FontWeight.w600, height: 1.45)),
                ),
                if ((j.accessNote ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AdminColors.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(j.accessNote!, style: ts(11, color: AdminColors.grey))),
                  ]),
                ],
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
        child: AdminButton('Start Trip to Customer',
            kind: ButtonKind.filled, icon: Icons.directions_run_rounded, height: 52,
            onPressed: () => startJobAction(context, j)),
      ),
    ]);
  }
}
