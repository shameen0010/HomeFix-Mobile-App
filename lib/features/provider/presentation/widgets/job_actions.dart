import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/chat_models.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/provider_repository.dart';
import '../screens/active_service_screen.dart';
import '../screens/job_entry_screen.dart';
import '../screens/provider_chat_screen.dart';

(String, Tone) jobStatusChip(JobModel j) {
  switch (j.status) {
    case 'pending':
      return (j.isEmergency ? 'Urgent' : 'New Request', Tone.orange);
    case 'confirmed':
      return ('Confirmed', Tone.blue);
    case 'in_progress':
      switch (j.stage) {
        case 'arrived':
          return ('Arrived', Tone.blue);
        case 'working':
          return ('Working', Tone.orange);
        case 'done':
          return ('Awaiting Receipt', Tone.orange);
        default:
          return ('En Route', Tone.blue);
      }
    case 'completed':
      return ('Completed', Tone.green);
    case 'cancelled':
      return ('Cancelled', Tone.red);
    default:
      return (j.status, Tone.grey);
  }
}

Future<void> acceptJobAction(BuildContext context, JobModel j) async {
  final ok = await confirmAction(context,
      title: 'Accept ${j.code}?',
      message: '${j.title} for ${j.customerName}\nEstimated payout ${formatMoney(j.amount)} (cash).',
      confirmLabel: 'Accept');
  if (!ok || !context.mounted) return;
  await runAdminAction(context, () => ProviderRepository.instance.acceptJob(j.id),
      success: '${j.code} accepted');
}

Future<void> declineJobAction(BuildContext context, JobModel j) async {
  final ok = await confirmAction(context,
      title: 'Decline ${j.code}?',
      message: 'The request goes back to dispatch for another provider.',
      confirmLabel: 'Decline',
      destructive: true);
  if (!ok || !context.mounted) return;
  await runAdminAction(context, () => ProviderRepository.instance.declineJob(j.id),
      success: '${j.code} declined');
}

/// Opens the right screen for the job's current state (request, customer
/// details, live job or settlement) and keeps it in sync when the status changes.
void openJob(BuildContext context, JobModel j) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => JobEntryScreen(jobId: j.id)));
}

/// Confirmed -> in progress (en route), then opens the live job screen.
Future<void> startJobAction(BuildContext context, JobModel j) async {
  final ok = await runAdminAction(context, () => ProviderRepository.instance.startJob(j.id),
      success: 'Job started. Safe travels!');
  if (ok && context.mounted) {
    Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ActiveServiceScreen(jobId: j.id)));
  }
}

void openChat(BuildContext context, JobModel j) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ProviderChatScreen(thread: ChatThread.fromJob(j)),
  ));
}
