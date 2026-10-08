import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/provider_profile.dart';
import '../../data/repositories/provider_repository.dart';
import 'provider_shell.dart';

class RegistrationCompleteScreen extends StatelessWidget {
  const RegistrationCompleteScreen({super.key});

  Widget _next(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: AdminColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: ts(12.5))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: StreamBuilder<ProviderProfile?>(
        stream: ProviderRepository.instance.watchProfile(),
        builder: (context, snap) {
          if (snap.hasError) return ErrorView(message: 'Could not load your account.\n${snap.error}');
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          final p = snap.data;
          if (p == null) return const ErrorView(message: 'Provider account not found.');
          final (statusText, statusTone) = p.status == 'approved'
              ? ('Active & Ready', Tone.green)
              : p.status == 'rejected'
                  ? ('Rejected', Tone.red)
                  : ('Pending Verification', Tone.orange);
          return Column(children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: const BoxDecoration(color: AdminColors.chipBg, shape: BoxShape.circle),
                      child: const Icon(Icons.verified_rounded, size: 52, color: AdminColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(child: Text('Registration Complete!', style: ts(24, w: FontWeight.w700))),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('Your service provider account has been\ncreated successfully.',
                        textAlign: TextAlign.center, style: ts(12.5, color: AdminColors.grey)),
                  ),
                  const SizedBox(height: 18),
                  AdminCard(
                    child: Column(children: [
                      Row(children: [
                        AdminAvatar(name: p.name, photoUrl: p.photoUrl, radius: 28,
                            badgeColor: AdminColors.primary, badgeIcon: Icons.check),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Flexible(child: Text(p.name, style: ts(16, w: FontWeight.w700))),
                              const SizedBox(width: 6),
                              const StatusPill('Pro', size: 9.5),
                            ]),
                            Text(p.email, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: ts(11.5, color: AdminColors.grey)),
                            Text(p.phone, style: ts(11.5, color: AdminColors.grey)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AdminColors.orangeBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.workspace_premium_outlined, color: Color(0xFFB45309)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Primary Specialty', style: ts(10, color: const Color(0xFF92400E))),
                              Text(p.trades.length > 1 ? p.trades.join(', ') : 'Master ${p.trade}',
                                  style: ts(13.5, w: FontWeight.w700)),
                            ]),
                          ),
                          StatusPill(statusText, tone: statusTone, icon: Icons.circle, size: 10),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  AdminCard(
                    color: AdminColors.field,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('WHAT YOU GET NEXT',
                          style: ts(10.5, w: FontWeight.w700, color: AdminColors.grey)),
                      const SizedBox(height: 6),
                      _next('Instant access to local customer booking leads'),
                      _next('Set your own rates and weekly working hours'),
                      _next('Collect direct cash settlements per completed job'),
                      if (p.status != 'approved')
                        _next('Our team is verifying your credentials. You will be notified once approved.'),
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: AdminButton('Go to Dashboard',
                  kind: ButtonKind.filled, icon: Icons.arrow_forward_rounded, height: 50,
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(builder: (_) => const ProviderShell()),
                      (r) => false)),
            ),
          ]);
        },
      ),
    );
  }
}
