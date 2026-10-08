import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/provider_profile.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/provider_header.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

/// FR-P02: provider profile. `preview` shows the public customer view.
class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key, this.preview = false});
  final bool preview;

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  late final Stream<ProviderProfile?> _stream = ProviderRepository.instance.watchProfile();

  Widget _stat(Widget value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.border)),
          child: Column(children: [
            value,
            const SizedBox(height: 2),
            Text(label, style: ts(10, color: AdminColors.grey)),
          ]),
        ),
      );

  Widget _num(String t, {Color color = AdminColors.dark}) =>
      Text(t, style: ts(17, w: FontWeight.w700, color: color));

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        ProviderHeader(
            title: widget.preview ? 'Public Customer View' : 'Provider Profile', showBack: true),
        Expanded(
          child: StreamBuilder<ProviderProfile?>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load profile.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final p = snap.data;
              if (p == null) return const ErrorView(message: 'Provider profile not found.');
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  AdminCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        AdminAvatar(name: p.name, photoUrl: p.photoUrl, radius: 36,
                            badgeColor: p.isApproved ? AdminColors.primary : AdminColors.orange,
                            badgeIcon: Icons.check),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.name, style: ts(20, w: FontWeight.w700)),
                            Text(p.headline, style: ts(12.5, w: FontWeight.w600, color: AdminColors.primary)),
                            const SizedBox(height: 6),
                            StatusPill(p.licenseNo == '-' ? 'Licensed ${p.trade}' : 'Licensed ${p.trade} #${p.licenseNo}',
                                tone: Tone.grey, icon: Icons.circle, size: 10),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        if (p.isApproved)
                          const StatusPill('Verified Pro', icon: Icons.shield_outlined, size: 10.5),
                        for (final b in p.badges)
                          StatusPill(b, tone: Tone.orange, icon: Icons.workspace_premium_outlined, size: 10.5),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    _stat(Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _num(p.rating.toStringAsFixed(1), color: const Color(0xFFB45309)),
                      const Icon(Icons.star_rounded, size: 15, color: AdminColors.orange),
                    ]), '${p.reviewCount} reviews'),
                    const SizedBox(width: 8),
                    _stat(_num('${p.completedCount}'), 'Completed'),
                    const SizedBox(width: 8),
                    _stat(_num('${p.onTimePct.round()}%'), 'On-Time'),
                    const SizedBox(width: 8),
                    _stat(_num('${p.experienceYears} Yrs'), 'Experience'),
                  ]),
                  const SizedBox(height: 12),
                  AdminCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SectionTitle('About Me', icon: Icons.badge_outlined),
                      const SizedBox(height: 8),
                      Text(p.bio.isEmpty ? 'No bio added yet.' : p.bio, style: ts(12.5, height: 1.5)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.place_outlined, color: AdminColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('SERVICE COVERAGE',
                                  style: ts(9.5, w: FontWeight.w700, color: AdminColors.grey)),
                              Text('${p.coverageArea} (${p.radiusMiles} mi radius)',
                                  style: ts(12.5, w: FontWeight.w700)),
                            ]),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  AdminCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SectionTitle('Pricing Overview', icon: Icons.payments_outlined),
                      const SizedBox(height: 8),
                      if (p.pricing.isEmpty)
                        Text('No pricing published yet.', style: ts(12, color: AdminColors.grey))
                      else
                        for (final item in p.pricing)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Flexible(child: Text(item.title, style: ts(12.5, w: FontWeight.w700))),
                                    if (item.badge != null) ...[
                                      const SizedBox(width: 6),
                                      StatusPill(item.badge!, tone: Tone.orange, size: 9),
                                    ],
                                  ]),
                                  Text(item.subtitle, style: ts(10.5, color: AdminColors.grey)),
                                ]),
                              ),
                              Text(formatMoney(item.price),
                                  style: ts(16, w: FontWeight.w700, color: AdminColors.primary)),
                              Text('/hr', style: ts(10, color: AdminColors.grey)),
                            ]),
                          ),
                    ]),
                  ),
                  if (!widget.preview) ...[
                    const SizedBox(height: 12),
                    AdminButton('Edit Profile Information',
                        kind: ButtonKind.filled, icon: Icons.manage_accounts_outlined, height: 50,
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => EditProfileScreen(profile: p)))),
                    const SizedBox(height: 8),
                    AdminButton('Preview Public Customer View',
                        icon: Icons.visibility_outlined, height: 50,
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => const ProviderProfileScreen(preview: true)))),
                    const SizedBox(height: 8),
                    AdminButton('Settings',
                        icon: Icons.settings_outlined, height: 46,
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()))),
                  ],
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}
