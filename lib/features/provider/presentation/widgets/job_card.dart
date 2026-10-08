import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/job_model.dart';
import 'job_actions.dart';

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, this.tag});
  final JobModel job;

  /// Optional label such as "NEXT UP".
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final j = job;
    final (label, tone) = jobStatusChip(j);
    final when = j.scheduledAt;
    return AdminCard(
      borderColor: j.isEmergency && j.status == 'pending' ? AdminColors.orange : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (tag != null) ...[
              StatusPill(tag!, size: 9.5),
              const SizedBox(width: 6),
            ],
            Text(j.code, style: ts(11.5, w: FontWeight.w700, color: AdminColors.grey)),
            const SizedBox(width: 8),
            StatusPill(label, tone: tone, size: 10),
            const Spacer(),
            if (when != null)
              Text(formatDate(when, 'MMM d, h:mm a'), style: ts(11, w: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            AdminAvatar(name: j.customerName, photoUrl: j.customerPhotoUrl, radius: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(j.customerName, style: ts(14.5, w: FontWeight.w700)),
                Text(j.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: ts(12, color: AdminColors.primary, w: FontWeight.w600)),
              ]),
            ),
            Text(formatMoney(j.amount), style: ts(15, w: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.place_outlined, size: 14, color: AdminColors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                  j.distanceKm == null ? j.address : '${j.address}  |  ${j.distanceKm!.toStringAsFixed(1)} km away',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: ts(11.5, color: AdminColors.grey)),
            ),
          ]),
          const SizedBox(height: 10),
          _buttons(context),
        ],
      ),
    );
  }

  Widget _buttons(BuildContext context) {
    final view = AdminButton('View Details',
        height: 40,
        kind: job.status == 'pending' ? ButtonKind.tonal : ButtonKind.filled,
        icon: Icons.arrow_forward_rounded,
        onPressed: () => openJob(context, job));
    if (job.status == 'pending') {
      return Row(children: [
        Expanded(flex: 3, child: view),
        const SizedBox(width: 8),
        Expanded(
            flex: 2,
            child: AdminButton('Decline', kind: ButtonKind.danger, height: 40,
                onPressed: () => declineJobAction(context, job))),
        const SizedBox(width: 8),
        Expanded(
            flex: 2,
            child: AdminButton('Accept', kind: ButtonKind.filled, height: 40,
                onPressed: () => acceptJobAction(context, job))),
      ]);
    }
    return Row(children: [
      Expanded(child: view),
      if (job.isUpcoming) ...[
        const SizedBox(width: 8),
        AdminButton('', icon: Icons.chat_bubble_outline_rounded, height: 40,
            onPressed: () => openChat(context, job)),
      ],
    ]);
  }
}
