import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/provider_ui.dart';
import '../../data/models/provider_profile.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/provider_header.dart';
import 'booking_history_screen.dart';
import 'manage_availability_screen.dart';
import 'manage_services_screen.dart';
import 'notifications_screen.dart';
import 'provider_profile_screen.dart';
import 'reviews_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Log out of Pro account?',
      message: 'You will stop receiving new requests.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final done = await runAdminAction(
      context,
      ProviderRepository.instance.signOut,
      success: 'Logged out',
    );
    if (done && context.mounted) context.go('/login');
  }

  Widget _tile(BuildContext context, IconData icon, String title, String sub, Widget target) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => target)),
          child: AdminCard(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              CircleAvatar(
                  radius: 20,
                  backgroundColor: AdminColors.chipBg,
                  child: Icon(icon, color: AdminColors.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: ts(13.5, w: FontWeight.w700)),
                  Text(sub, style: ts(11, color: AdminColors.grey)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AdminColors.grey),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(subtitle: 'More'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              StreamBuilder<ProviderProfile?>(
                stream: ProviderRepository.instance.watchProfile(),
                builder: (context, snap) {
                  final p = snap.data;
                  if (p == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AdminCard(
                      child: Row(children: [
                        AdminAvatar(name: p.name, photoUrl: p.photoUrl, radius: 26,
                            badgeColor: p.isApproved ? AdminColors.primary : AdminColors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.name, style: ts(16, w: FontWeight.w700)),
                            Text(p.headline, style: ts(11.5, color: AdminColors.primary)),
                            const SizedBox(height: 4),
                            StatusPill(p.isApproved ? 'Verified Pro' : 'Pending verification',
                                tone: p.isApproved ? Tone.blue : Tone.orange, size: 10),
                          ]),
                        ),
                      ]),
                    ),
                  );
                },
              ),
              _tile(context, Icons.person_outline_rounded, 'My Profile', 'Credentials, bio and pricing', const ProviderProfileScreen()),
              _tile(context, Icons.history_rounded, 'Booking History', 'Completed jobs, receipts and notes', const BookingHistoryScreen()),
              _tile(context, Icons.work_outline_rounded, 'Manage Services', 'Catalog, rates and durations', const ManageServicesScreen()),
              _tile(context, Icons.event_repeat_rounded, 'Manage Availability', 'Working days, hours and time off', const ManageAvailabilityScreen()),
              _tile(context, Icons.star_border_rounded, 'Ratings & Reviews', 'Customer feedback and replies', const ReviewsScreen()),
              _tile(context, Icons.notifications_none_rounded, 'Notifications', 'Requests, payments and reviews', const NotificationsScreen()),
              _tile(context, Icons.settings_outlined, 'Settings', 'Dispatch, security and support', const SettingsScreen()),
              const SizedBox(height: 8),
              AdminButton(
                'Log Out of Pro Account',
                kind: ButtonKind.danger,
                icon: Icons.logout_rounded,
                height: 50,
                onPressed: () => _logout(context),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
