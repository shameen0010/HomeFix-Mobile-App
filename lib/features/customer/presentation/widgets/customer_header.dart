import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../../data/repositories/customer_repository.dart';
import '../screens/customer_notifications_screen.dart';

/// Logo header. Root tabs show "HomeFix"; sub-screens pass [title] + [showBack].
class CustomerHeader extends StatelessWidget {
  const CustomerHeader({super.key, this.title, this.showBack = false});
  final String? title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(showBack ? 8 : 16, 8, 12, 8),
      child: Row(children: [
        if (showBack)
          IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded)),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AdminColors.primary, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title ?? 'HomeFix',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: ts(title == null ? 19 : 16, w: FontWeight.w700)),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).popUntil((r) => r.isFirst);
            CustomerNav.goTab(4);
          },
          child: const CircleAvatar(
            radius: 17,
            backgroundColor: AdminColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }
}

class CustomerBell extends StatelessWidget {
  const CustomerBell({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: CustomerRepository.instance.watchUnreadCount(),
      builder: (context, snap) => Container(
        decoration: BoxDecoration(
            color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AdminColors.border)),
        child: IconButton(
          tooltip: 'Notifications',
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CustomerNotificationsScreen())),
          icon: Badge(
            isLabelVisible: (snap.data ?? 0) > 0,
            smallSize: 8,
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ),
    );
  }
}
