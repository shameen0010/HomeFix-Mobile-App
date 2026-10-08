import 'package:flutter/material.dart';

import '../../../provider/data/models/notification_model.dart';
import '../../core/customer_ui.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/customer_header.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  final _repo = CustomerRepository.instance;
  late final Stream<List<NotificationModel>> _stream = _repo.watchNotifications();

  IconData _icon(String t) {
    switch (t) {
      case 'payment':
        return Icons.payments_outlined;
      case 'review':
        return Icons.star_border_rounded;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'booking':
      case 'urgent':
        return Icons.calendar_month_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Notifications', showBack: true),
        Expanded(
          child: StreamBuilder<List<NotificationModel>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load notifications.\n${snap.error}');
              if (!snap.hasData) return const LoadingView();
              final list = snap.data!;
              final unread = list.where((n) => !n.read).map((n) => n.id).toList();
              return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
                Row(children: [
                  Text('Inbox', style: ts(21, w: FontWeight.w700)),
                  const SizedBox(width: 8),
                  if (unread.isNotEmpty) StatusPill('${unread.length} New', tone: Tone.orange, size: 10),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: unread.isEmpty
                        ? null
                        : () => runAdminAction(context, () => _repo.markAllRead(unread),
                            success: 'All notifications marked as read'),
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark all read'),
                  ),
                ]),
                if (list.isEmpty)
                  const EmptyView(message: 'You are all caught up', icon: Icons.notifications_none_rounded)
                else
                  for (final n in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: n.read ? null : () => _repo.markAllRead([n.id]).catchError((Object _) {}),
                        child: AdminCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            CircleAvatar(radius: 18, backgroundColor: AdminColors.field,
                                child: Icon(_icon(n.type), size: 18, color: AdminColors.primary)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  if (!n.read) ...[
                                    const Icon(Icons.circle, size: 8, color: AdminColors.primary),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(child: Text(n.title, style: ts(13, w: FontWeight.w700))),
                                  Text(timeAgo(n.createdAt), style: ts(10, color: AdminColors.grey)),
                                ]),
                                Text(n.body, style: ts(12, color: AdminColors.grey)),
                              ]),
                            ),
                            InkWell(
                              onTap: () => runAdminAction(context, () => _repo.dismissNotification(n.id),
                                  success: 'Notification dismissed', showLoader: false),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.close_rounded, size: 18, color: AdminColors.grey),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}
