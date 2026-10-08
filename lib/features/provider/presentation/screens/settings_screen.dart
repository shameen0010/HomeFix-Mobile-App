import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/provider_ui.dart';
import '../../data/models/provider_profile.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/provider_header.dart';
import 'provider_chat_screen.dart' show callCustomer;
import 'provider_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = ProviderRepository.instance;
  late final Stream<ProviderProfile?> _stream = _repo.watchProfile();

  Widget _group(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(title, style: ts(10.5, w: FontWeight.w700, color: AdminColors.grey)),
          ),
          AdminCard(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: children)),
        ]),
      );

  Widget _row({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Widget? badge,
    VoidCallback? onTap,
    Color? iconBg,
  }) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg ?? AdminColors.chipBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: AdminColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(title, style: ts(13, w: FontWeight.w700))),
                  if (badge != null) ...[const SizedBox(width: 6), badge],
                ]),
                if (subtitle != null) Text(subtitle, style: ts(10.5, color: AdminColors.grey)),
              ]),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: AdminColors.grey),
          ]),
        ),
      );

  Future<void> _pickBuffer(ProviderProfile p) async {
    final v = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => Theme(
        data: adminTheme,
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Travel buffer between jobs', style: ts(15, w: FontWeight.w700)),
            ),
            for (final m in const [0, 15, 30, 45, 60])
              ListTile(
                title: Text(m == 0 ? 'No buffer' : '$m mins'),
                trailing: m == p.travelBufferMins ? const Icon(Icons.check, color: AdminColors.primary) : null,
                onTap: () => Navigator.pop(context, m),
              ),
          ]),
        ),
      ),
    );
    if (v == null || !mounted) return;
    await runAdminAction(context, () => _repo.updateDispatchPrefs(travelBufferMins: v),
        success: 'Travel buffer set to $v mins', showLoader: false);
  }

  void _showDocuments(ProviderProfile p) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => Theme(
        data: adminTheme,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionTitle('License & Insurance', icon: Icons.verified_user_outlined),
              const SizedBox(height: 10),
              if (p.documents.isEmpty)
                Text('No documents on file yet. Our team will contact you if anything is needed.',
                    style: ts(12.5, color: AdminColors.grey))
              else
                for (final d in p.documents)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(d.verified ? Icons.check_circle_rounded : Icons.pending_outlined,
                        color: d.verified ? AdminColors.green : AdminColors.orange),
                    title: Text(d.title, style: ts(13, w: FontWeight.w600)),
                    subtitle: Text(d.detail.isEmpty ? (d.verified ? 'Verified' : 'Pending') : d.detail,
                        style: ts(11, color: AdminColors.grey)),
                  ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final ok = await confirmAction(context,
        title: 'Change password?',
        message: 'We will email you a secure link to set a new password.',
        confirmLabel: 'Send link');
    if (!ok || !mounted) return;
    await runAdminAction(context, _repo.sendPasswordReset, success: 'Password reset link sent');
  }

  Future<void> _logout() async {
    final ok = await confirmAction(context,
        title: 'Log out of Pro account?', message: 'You will stop receiving new requests.',
        confirmLabel: 'Log out', destructive: true);
    if (!ok || !mounted) return;
    final done = await runAdminAction(context, _repo.signOut, success: 'Logged out');
    if (done && mounted) context.go('/login');
  }

  void _terms() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Terms & Pro Guarantee', style: ts(17, w: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(
            '1. Customers pay providers directly in cash after the service is completed.\n\n'
            '2. Providers must keep licenses and insurance valid and up to date.\n\n'
            '3. Work completed through HomeFix is covered by a 30-day workmanship guarantee.\n\n'
            '4. Repeated cancellations or unsafe conduct can lead to suspension by an administrator.',
            style: ts(12.5, height: 1.5),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Settings', showBack: true),
        Expanded(
          child: StreamBuilder<ProviderProfile?>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load settings.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final p = snap.data;
              if (p == null) return const ErrorView(message: 'Provider profile not found.');
              final licenseDoc = p.documents.where((d) => d.type == 'license');
              final licenseSub = licenseDoc.isEmpty
                  ? 'No license on file'
                  : (licenseDoc.first.verified
                      ? 'Verified ${licenseDoc.first.detail}'.trim()
                      : 'Pending verification');
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  AdminCard(
                    child: Column(children: [
                      Row(children: [
                        AdminAvatar(name: p.name, photoUrl: p.photoUrl, radius: 26,
                            badgeColor: p.isApproved ? AdminColors.primary : AdminColors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.name, style: ts(16, w: FontWeight.w700)),
                            Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                              StatusPill(p.isApproved ? 'Pro Active' : 'Pending', tone: p.isApproved ? Tone.blue : Tone.orange, size: 9.5),
                              Text('#${p.appId}', style: ts(10.5, color: AdminColors.grey)),
                            ]),
                            Text(p.headline, style: ts(11, color: AdminColors.grey)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ProviderProfileScreen())),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AdminColors.chipBg, borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Icon(Icons.badge_outlined, size: 18, color: AdminColors.primary),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Manage Public Profile',
                                style: ts(12.5, w: FontWeight.w600, color: AdminColors.primary))),
                            const Icon(Icons.chevron_right_rounded, color: AdminColors.primary),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  _group('WORK & DISPATCH PREFERENCES', [
                    _row(
                      icon: Icons.bolt_rounded,
                      iconBg: AdminColors.orangeBg,
                      title: 'Emergency Same-Day Jobs',
                      subtitle: 'Instant alerts for priority urgent dispatch',
                      badge: StatusPill('+${p.surgePct}% Surge', tone: Tone.orange, size: 9),
                      trailing: Switch(
                        value: p.emergencyEnabled,
                        onChanged: (v) => runAdminAction(context, () => _repo.updateDispatchPrefs(emergency: v),
                            success: v ? 'Emergency jobs enabled' : 'Emergency jobs disabled', showLoader: false),
                      ),
                    ),
                    const Divider(height: 1),
                    _row(
                      icon: Icons.timer_outlined,
                      title: 'Travel Buffer Between Jobs',
                      subtitle: 'Prevents overlapping commute delays',
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        StatusPill('${p.travelBufferMins} mins', size: 10.5),
                        const Icon(Icons.chevron_right_rounded, color: AdminColors.grey),
                      ]),
                      onTap: () => _pickBuffer(p),
                    ),
                  ]),
                  _group('ACCOUNT & SECURITY', [
                    _row(
                      icon: Icons.shield_outlined,
                      title: 'License & Insurance',
                      subtitle: licenseSub,
                      onTap: () => _showDocuments(p),
                    ),
                    const Divider(height: 1),
                    _row(
                      icon: Icons.password_rounded,
                      title: 'Change Password & Security PIN',
                      subtitle: 'Send a secure reset link to your email',
                      onTap: _changePassword,
                    ),
                  ]),
                  _group('SUPPORT & LEGAL', [
                    _row(
                      icon: Icons.support_agent_rounded,
                      iconBg: AdminColors.orangeBg,
                      title: 'Pro Help & Emergency Hotline',
                      subtitle: 'Priority phone line for technicians',
                      badge: const StatusPill('24/7', tone: Tone.orange, size: 9),
                      trailing: const Icon(Icons.phone_outlined, color: AdminColors.grey),
                      onTap: () => callCustomer(context, ProviderConfig.hotline),
                    ),
                    const Divider(height: 1),
                    _row(
                      icon: Icons.gavel_rounded,
                      title: 'Terms of Service & Pro Guarantee',
                      subtitle: 'Review policy standards and covenants',
                      onTap: _terms,
                    ),
                    const Divider(height: 1),
                    _row(
                      icon: Icons.info_outline_rounded,
                      title: 'App Version',
                      subtitle: 'HomeFix Pro v${ProviderConfig.appVersion}',
                      trailing: const StatusPill('Latest', tone: Tone.grey, size: 10),
                    ),
                  ]),
                  AdminButton('Log Out of Pro Account',
                      kind: ButtonKind.danger, icon: Icons.logout_rounded, height: 50, onPressed: _logout),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}
