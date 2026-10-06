import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/admin_feedback.dart';
import '../../../core/admin_format.dart';
import '../../../core/admin_theme.dart';
import '../../../core/admin_widgets.dart';
import '../../../data/models/provider_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../widgets/provider_actions.dart';

class ProviderDetailScreen extends StatefulWidget {
  const ProviderDetailScreen(
      {super.key, required this.providerId, required this.repository});
  final String providerId;
  final AdminRepository repository;

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  late final Stream<ProviderModel?> _stream =
      widget.repository.watchProvider(widget.providerId);

  Future<void> _openDoc(ProviderDocument d) async {
    final url = d.url;
    if (url == null || url.isEmpty) {
      showAdminSnack(context, 'No file attached to this document.', error: true);
      return;
    }
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) showAdminSnack(context, 'Could not open the document.', error: true);
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Invalid document link.', error: true);
    }
  }

  IconData _docIcon(String type) {
    switch (type) {
      case 'id':
        return Icons.badge_outlined;
      case 'license':
        return Icons.workspace_premium_outlined;
      case 'insurance':
        return Icons.shield_outlined;
      case 'background':
        return Icons.fingerprint_rounded;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(
        children: [
          AdminHeader(
              screenTitle: 'Provider Details',
              onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: StreamBuilder<ProviderModel?>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorView(message: 'Could not load provider.\n${snap.error}');
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                final p = snap.data;
                if (p == null) {
                  return const ErrorView(message: 'This provider no longer exists.');
                }
                return _body(p);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner(ProviderModel p) {
    final (IconData icon, String title, String sub, Color bg, Color fg) = switch (p.status) {
      'pending' => (
          Icons.pending_actions_rounded,
          'Pending Verification',
          'Submitted ${timeAgo(p.submittedAt)}  |  Priority queue',
          AdminColors.orange,
          Colors.white
        ),
      'approved' => (
          Icons.verified_rounded,
          'Verified Provider',
          'Approved and visible to customers',
          AdminColors.primary,
          Colors.white
        ),
      'rejected' => (
          Icons.cancel_rounded,
          'Application Rejected',
          p.statusReason ?? 'No reason recorded',
          AdminColors.red,
          Colors.white
        ),
      _ => (
          Icons.block_rounded,
          'Provider Suspended',
          p.statusReason ?? 'No reason recorded',
          AdminColors.grey,
          Colors.white
        ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: fg, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ts(16, w: FontWeight.w700, color: fg)),
              Text(sub, style: ts(11.5, color: fg)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _tile(IconData icon, String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 13, color: AdminColors.grey),
                const SizedBox(width: 4),
                Text(label, style: ts(10.5, color: AdminColors.grey)),
              ]),
              const SizedBox(height: 3),
              Text(value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ts(12.5, w: FontWeight.w700, color: AdminColors.primary)),
            ],
          ),
        ),
      );

  Widget _body(ProviderModel p) {
    final total = p.documents.length;
    final cleared = p.checksCleared;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        _banner(p),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(children: [
            Row(children: [
              AdminAvatar(name: p.name, photoUrl: p.photoUrl, radius: 32,
                  badgeColor: p.isApproved ? AdminColors.primary : AdminColors.orange),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: ts(18, w: FontWeight.w700)),
                    const SizedBox(height: 2),
                    StatusPill(p.isApproved ? 'Pro Vetted' : 'Applicant',
                        tone: Tone.blue, icon: Icons.verified_outlined, size: 10.5),
                    const SizedBox(height: 4),
                    Text('${p.trade}  |  ${p.experienceYears} yrs exp',
                        style: ts(12, w: FontWeight.w600)),
                    Text('Applied ${formatDate(p.submittedAt)}',
                        style: ts(11, color: AdminColors.grey)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _tile(Icons.phone_outlined, 'Phone', p.phone),
              const SizedBox(width: 8),
              _tile(Icons.place_outlined, 'Coverage Area', p.coverageArea),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Row(children: [
                  Expanded(
                      child: Text('Auto-Validation Health',
                          style: ts(11.5, color: AdminColors.grey))),
                  Text('$cleared / $total Checks Cleared',
                      style: ts(11.5, w: FontWeight.w700, color: AdminColors.primary)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : cleared / total,
                    minHeight: 7,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation(AdminColors.primary),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        if ((p.infoRequest ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          AdminCard(
            color: AdminColors.orangeBg,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mail_outline_rounded, size: 18, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Info requested: ${p.infoRequest}',
                      style: ts(12, color: const Color(0xFF92400E))),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Verification Dossier',
                  icon: Icons.fact_check_outlined),
              Text('Documents submitted for verification',
                  style: ts(11, color: AdminColors.grey)),
              const SizedBox(height: 10),
              if (p.documents.isEmpty)
                Text('No documents uploaded.', style: ts(12.5, color: AdminColors.grey))
              else
                for (final d in p.documents)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AdminColors.field,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(_docIcon(d.type), size: 22, color: AdminColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.title, style: ts(12.5, w: FontWeight.w600)),
                            Row(children: [
                              Icon(
                                  d.verified
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_outlined,
                                  size: 13,
                                  color: d.verified ? AdminColors.green : AdminColors.orange),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                    d.detail.isEmpty
                                        ? (d.verified ? 'Verified' : 'Not yet verified')
                                        : d.detail,
                                    style: ts(10.5, color: AdminColors.grey)),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      AdminButton('View', height: 34, onPressed: () => _openDoc(d)),
                    ]),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('Selected Services',
                  trailing: StatusPill('${p.services.length} Requested',
                      tone: Tone.grey, size: 10)),
              const SizedBox(height: 10),
              if (p.services.isEmpty)
                Text('No services selected.', style: ts(12.5, color: AdminColors.grey))
              else
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in p.services)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: AdminColors.field,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.handyman_outlined,
                            size: 15, color: AdminColors.primary),
                        const SizedBox(width: 6),
                        Text(s, style: ts(12, w: FontWeight.w600)),
                      ]),
                    ),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _decisionPanel(p),
      ],
    );
  }

  Widget _decisionPanel(ProviderModel p) {
    final repo = widget.repository;
    final List<Widget> actions = switch (p.status) {
      'pending' => [
          AdminButton('Approve & Verify Provider',
              kind: ButtonKind.filled,
              icon: Icons.verified_outlined,
              height: 48,
              onPressed: () => approveProviderAction(context, repo, p)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: AdminButton('Request Info',
                    icon: Icons.mail_outline_rounded,
                    height: 46,
                    onPressed: () => requestInfoAction(context, repo, p))),
            const SizedBox(width: 8),
            Expanded(
                child: AdminButton('Reject',
                    kind: ButtonKind.danger,
                    icon: Icons.cancel_outlined,
                    height: 46,
                    onPressed: () => rejectProviderAction(context, repo, p))),
          ]),
        ],
      'approved' => [
          AdminButton('Suspend Provider',
              kind: ButtonKind.danger,
              icon: Icons.block_rounded,
              height: 48,
              onPressed: () => suspendProviderAction(context, repo, p)),
        ],
      'rejected' => [
          AdminButton('Re-evaluate Application',
              kind: ButtonKind.filled,
              icon: Icons.refresh_rounded,
              height: 48,
              onPressed: () => reEvaluateProviderAction(context, repo, p)),
          const SizedBox(height: 8),
          AdminButton('View Audit Log',
              icon: Icons.history_rounded,
              height: 46,
              onPressed: () => showAuditLogSheet(context, repo, p)),
        ],
      _ => [
          AdminButton('Reinstate Provider',
              kind: ButtonKind.filled,
              height: 48,
              onPressed: () => reinstateProviderAction(context, repo, p)),
        ],
    };
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text('ADMIN DECISION',
                    style: ts(10.5, w: FontWeight.w700, color: AdminColors.grey))),
            Text('Admin ID #${repo.currentAdminTag}',
                style: ts(10.5, w: FontWeight.w700, color: AdminColors.primary)),
          ]),
          const SizedBox(height: 10),
          ...actions,
        ],
      ),
    );
  }
}
