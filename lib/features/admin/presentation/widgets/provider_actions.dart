import 'package:flutter/material.dart';

import '../../core/admin_feedback.dart';
import '../../core/admin_format.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_widgets.dart';
import '../../data/models/provider_model.dart';
import '../../data/repositories/admin_repository.dart';

(String, Tone) providerStatusChip(String status) {
  switch (status) {
    case 'approved':
      return ('Verified Pro', Tone.blue);
    case 'pending':
      return ('Pending Review', Tone.orange);
    case 'rejected':
      return ('Rejected', Tone.red);
    case 'suspended':
      return ('Suspended', Tone.grey);
    default:
      return (status, Tone.grey);
  }
}

Future<void> approveProviderAction(
    BuildContext context, AdminRepository repo, ProviderModel p) async {
  final ok = await confirmAction(
    context,
    title: 'Approve ${p.name}?',
    message: 'They will be verified as a ${p.trade} and can receive bookings.',
    confirmLabel: 'Approve & Verify',
  );
  if (!ok || !context.mounted) return;
  await runAdminAction(context, () => repo.approveProvider(p.id),
      success: '${p.name} approved');
}

Future<void> rejectProviderAction(
    BuildContext context, AdminRepository repo, ProviderModel p) async {
  final reason = await promptText(
    context,
    title: 'Reject ${p.name}?',
    message: 'The reason is stored in the audit log.',
    hint: 'Reason for rejection',
    confirmLabel: 'Reject',
  );
  if (reason == null || !context.mounted) return;
  await runAdminAction(context, () => repo.rejectProvider(p.id, reason),
      success: '${p.name} rejected');
}

Future<void> suspendProviderAction(
    BuildContext context, AdminRepository repo, ProviderModel p) async {
  final reason = await promptText(
    context,
    title: 'Suspend ${p.name}?',
    hint: 'Reason for suspension',
    confirmLabel: 'Suspend',
  );
  if (reason == null || !context.mounted) return;
  await runAdminAction(context, () => repo.suspendProvider(p.id, reason),
      success: '${p.name} suspended');
}

Future<void> reinstateProviderAction(
    BuildContext context, AdminRepository repo, ProviderModel p) async {
  final ok = await confirmAction(context,
      title: 'Reinstate ${p.name}?',
      message: 'The provider becomes active again.',
      confirmLabel: 'Reinstate');
  if (!ok || !context.mounted) return;
  await runAdminAction(context, () => repo.reinstateProvider(p.id),
      success: '${p.name} reinstated');
}

Future<void> reEvaluateProviderAction(
    BuildContext context, AdminRepository repo, ProviderModel p) async {
  final ok = await confirmAction(context,
      title: 'Re-evaluate ${p.name}?',
      message: 'The application returns to the pending verification queue.',
      confirmLabel: 'Re-evaluate');
  if (!ok || !context.mounted) return;
  await runAdminAction(context, () => repo.reEvaluateProvider(p.id),
      success: '${p.name} moved back to pending');
}

Future<void> requestInfoAction(
    BuildContext context, AdminRepository repo, ProviderModel p) async {
  final message = await promptText(
    context,
    title: 'Request more info',
    hint: 'What should ${p.name} provide?',
    confirmLabel: 'Send request',
  );
  if (message == null || !context.mounted) return;
  await runAdminAction(context, () => repo.requestProviderInfo(p.id, message),
      success: 'Information request sent');
}

void showAuditLogSheet(
    BuildContext context, AdminRepository repo, ProviderModel p) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Theme(
      data: adminTheme,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('Audit log - ${p.name}', icon: Icons.history_rounded),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<AuditEntry>>(
                  stream: repo.watchProviderAudit(p.id),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return const ErrorView(message: 'Could not load the audit log.');
                    }
                    if (!snap.hasData) return const LoadingView();
                    final items = snap.data!;
                    if (items.isEmpty) {
                      return const EmptyView(message: 'No audit entries yet');
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (_, i) {
                        final e = items[i];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.action.replaceAll('_', ' ').toUpperCase(),
                                style: ts(12, w: FontWeight.w700, color: AdminColors.primary)),
                            if ((e.reason ?? '').isNotEmpty)
                              Text(e.reason!, style: ts(13)),
                            Text(
                                '${formatDate(e.at, 'MMM d, yyyy h:mm a')}  by ${e.by == null ? '-' : e.by!.length > 6 ? e.by!.substring(0, 6).toUpperCase() : e.by!}',
                                style: ts(11, color: AdminColors.grey)),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
