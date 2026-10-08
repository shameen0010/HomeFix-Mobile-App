import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/provider_profile.dart';
import '../../data/repositories/provider_repository.dart';
import '../screens/notifications_screen.dart';
import '../screens/provider_profile_screen.dart';

/// Root tabs: logo + "HomeFix" + online chip + bell. Sub-screens: back arrow,
/// logo, title, home shortcut.
class ProviderHeader extends StatelessWidget {
  const ProviderHeader({super.key, this.title, this.subtitle, this.showBack = false});
  final String? title;
  final String? subtitle;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final repo = ProviderRepository.instance;
    final logo = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: AdminColors.primary, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
    );
    final avatar = GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProviderProfileScreen())),
      child: const CircleAvatar(
        radius: 17,
        backgroundColor: AdminColors.primary,
        child: Icon(Icons.person, color: Colors.white, size: 18),
      ),
    );

    if (showBack) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: Row(children: [
          IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded)),
          logo,
          const SizedBox(width: 10),
          Expanded(
            child: Text(title ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(16, w: FontWeight.w700)),
          ),
          IconButton(
            tooltip: 'Dashboard',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            icon: const Icon(Icons.home_outlined),
          ),
          avatar,
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      child: Row(children: [
        logo,
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('HomeFix', style: ts(18, w: FontWeight.w700)),
              const SizedBox(width: 6),
              const StatusPill('PRO', size: 9.5),
            ]),
            if (subtitle != null)
              Text(subtitle!, style: ts(11.5, color: AdminColors.grey)),
          ]),
        ),
        StreamBuilder<ProviderProfile?>(
          stream: repo.watchProfile(),
          builder: (context, snap) {
            final online = snap.data?.isOnline ?? false;
            return GestureDetector(
              onTap: snap.data == null
                  ? null
                  : () => runAdminAction(context, () => repo.setOnline(!online),
                      success: online ? 'You are offline' : 'You are online',
                      showLoader: false),
              child: StatusPill(online ? 'Online' : 'Offline',
                  tone: online ? Tone.green : Tone.grey, icon: Icons.circle, size: 10.5),
            );
          },
        ),
        StreamBuilder<int>(
          stream: repo.watchUnreadCount(),
          builder: (context, snap) {
            final unread = snap.data ?? 0;
            return IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NotificationsScreen())),
              icon: Badge(
                isLabelVisible: unread > 0,
                smallSize: 8,
                child: const Icon(Icons.notifications_none_rounded),
              ),
            );
          },
        ),
        avatar,
      ]),
    );
  }
}
