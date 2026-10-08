import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/job_model.dart';
import 'job_actions.dart';
import 'job_format.dart';

/// Incoming request card (Requests > Pending / Declined).
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.job, this.pastBookings = 0, this.declined = false});
  final JobModel job;
  final int pastBookings;
  final bool declined;

  @override
  Widget build(BuildContext context) {
    final j = job;
    final soon = inLabel(j.scheduledAt);
    return GestureDetector(
      onTap: () => openJob(context, j),
      child: AdminCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Wrap(spacing: 6, runSpacing: 4, children: [
                if (declined)
                  const StatusPill('DECLINED', tone: Tone.red, size: 10)
                else if (j.isEmergency)
                  const StatusPill('URGENT JOB', tone: Tone.red, icon: Icons.error_outline_rounded, size: 10)
                else
                  StatusPill(dayWord(j.scheduledAt).toUpperCase(),
                      tone: Tone.grey, icon: Icons.calendar_today_outlined, size: 10),
                if (!declined && soon != null) StatusPill(soon, tone: Tone.grey, size: 10),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatMoney(j.amount), style: ts(21, w: FontWeight.w700, color: AdminColors.primary)),
              Text('Cash on completion', style: ts(9.5, w: FontWeight.w600, color: AdminColors.grey)),
            ]),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            AdminAvatar(name: j.customerName, photoUrl: j.customerPhotoUrl, radius: 24,
                badgeColor: AdminColors.primary, badgeIcon: Icons.check),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(j.customerName, style: ts(17, w: FontWeight.w700))),
                  if (j.customerRating != null) ...[
                    const SizedBox(width: 6),
                    StatusPill('\u2605 ${j.customerRating!.toStringAsFixed(1)}', tone: Tone.orange, size: 10),
                  ],
                ]),
                Text('Verified Homeowner  |  $pastBookings past booking${pastBookings == 1 ? '' : 's'}',
                    style: ts(11, color: AdminColors.grey)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.build_rounded, size: 16, color: AdminColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      (j.description ?? '').isEmpty ? j.title : '${j.title}  \u2022  ${j.description}',
                      style: ts(13.5, w: FontWeight.w700, color: AdminColors.primary)),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.schedule_rounded, size: 15, color: AdminColors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(whenLabel(j.scheduledAt), style: ts(12))),
              ]),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.place_outlined, size: 15, color: AdminColors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(j.address, style: ts(12.5, w: FontWeight.w700)),
                    if (j.distanceLabel.isNotEmpty)
                      Text(j.distanceLabel, style: ts(10.5, color: AdminColors.grey)),
                  ]),
                ),
              ]),
            ]),
          ),
          if ((j.customerNotes ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded, size: 15, color: AdminColors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text('"${j.customerNotes}"',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: ts(11.5, color: const Color(0xFF92400E)).copyWith(fontStyle: FontStyle.italic)),
              ),
            ]),
          ],
          const SizedBox(height: 12),
          if (declined)
            AdminButton('View Details', icon: Icons.arrow_forward_rounded, height: 44,
                onPressed: () => openJob(context, j))
          else
            Row(children: [
              Expanded(
                child: AdminButton('Decline', kind: ButtonKind.danger, icon: Icons.close_rounded, height: 48,
                    onPressed: () => declineJobAction(context, j)),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: AdminButton('Accept Job', kind: ButtonKind.filled, icon: Icons.check_rounded, height: 48,
                    onPressed: () => acceptJobAction(context, j)),
              ),
            ]),
        ]),
      ),
    );
  }
}
