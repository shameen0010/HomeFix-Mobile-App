import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/job_model.dart';
import '../screens/provider_chat_screen.dart' show callCustomer;
import 'job_actions.dart';

/// Confirmed / in-progress booking card (Schedule, Requests > Accepted).
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.job, this.nextUp = false});
  final JobModel job;
  final bool nextUp;

  @override
  Widget build(BuildContext context) {
    final j = job;
    final when = j.scheduledAt;
    final live = j.status == 'in_progress';
    final starts = startsIn(when);
    final chip = live
        ? 'In Progress  \u2022  ${j.status == 'in_progress' ? jobStatusChip(j).$1 : ''}'
        : nextUp && when != null && when.isAfter(DateTime.now())
            ? 'Confirmed  \u2022  $starts'
            : 'Confirmed';
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(when == null ? '--' : formatDate(when, 'h:mm a'), style: ts(21, w: FontWeight.w700)),
          if (nextUp) ...[
            const SizedBox(width: 8),
            const StatusPill('Next Up', size: 10),
          ],
          const Spacer(),
          Flexible(
            child: StatusPill(chip,
                tone: nextUp || live ? Tone.orange : Tone.blue,
                icon: nextUp ? Icons.alarm_rounded : Icons.check_circle_outline_rounded, size: 10),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            AdminAvatar(name: j.customerName, photoUrl: j.customerPhotoUrl, radius: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(j.customerName, style: ts(15.5, w: FontWeight.w700))),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded, size: 15, color: AdminColors.primary),
                ]),
                Text('Homeowner  \u2022  Verified', style: ts(10.5, color: AdminColors.grey)),
              ]),
            ),
            IconButton.filledTonal(
              tooltip: 'Call',
              onPressed: () => callCustomer(context, j.customerPhone),
              icon: const Icon(Icons.phone_outlined, size: 18),
            ),
            IconButton.filledTonal(
              tooltip: 'Message',
              onPressed: () => openChat(context, j),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.build_rounded, size: 16, color: AdminColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(j.title, style: ts(14, w: FontWeight.w700)),
              if ((j.description ?? j.customerNotes ?? '').isNotEmpty)
                Text(j.description ?? j.customerNotes!, style: ts(11, color: AdminColors.grey)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.place_outlined, size: 16, color: AdminColors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(j.address, style: ts(12.5, w: FontWeight.w600)),
              if (j.distanceLabel.isNotEmpty)
                Text(j.distanceLabel.replaceAll('miles away', 'mi away'), style: ts(10.5, color: AdminColors.grey)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.payments_outlined, size: 17, color: AdminColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Cash on completion', style: ts(11.5, color: AdminColors.grey))),
            Text(formatMoney(j.amount), style: ts(18, w: FontWeight.w700, color: AdminColors.primary)),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          if (nextUp && !live) ...[
            Expanded(
              flex: 3,
              child: AdminButton('Start Job', kind: ButtonKind.filled, height: 48,
                  onPressed: () => startJobAction(context, j)),
            ),
            const SizedBox(width: 8),
          ] else if (live) ...[
            Expanded(
              flex: 3,
              child: AdminButton('Resume Job', kind: ButtonKind.filled, icon: Icons.play_arrow_rounded, height: 48,
                  onPressed: () => openJob(context, j)),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: AdminButton(nextUp || live ? 'Job Details' : 'View Details',
                icon: nextUp || live ? null : Icons.chevron_right_rounded, height: 48,
                onPressed: () => openJob(context, j)),
          ),
        ]),
      ]),
    );
  }
}
