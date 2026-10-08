import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/provider_header.dart';
import 'job_entry_screen.dart';

enum _Filter { all, bookings, messages, system }

/// FR-P10: booking and status notifications.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = ProviderRepository.instance;
  late final Stream<List<NotificationModel>> _stream = _repo.watchNotifications();
  _Filter _filter = _Filter.all;

  bool _match(NotificationModel n) => switch (_filter) {
        _Filter.all => true,
        _Filter.bookings => n.isBooking || n.type == 'review',
        _Filter.messages => n.type == 'message',
        _Filter.system => n.type == 'system',
      };

  IconData _icon(String t) {
    switch (t) {
      case 'urgent':
        return Icons.bolt_rounded;
      case 'payment':
        return Icons.payments_outlined;
      case 'review':
        return Icons.star_border_rounded;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'booking':
        return Icons.calendar_month_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _bucket(DateTime? d) {
    if (d == null) return 'EARLIER';
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    return diff == 0 ? 'TODAY' : diff == 1 ? 'YESTERDAY' : 'EARLIER';
  }

  void _open(NotificationModel n) {
    if (!n.read) {
      _repo.markAllRead([n.id]).catchError((Object _) {});
    }
    if (n.jobId != null) {
      Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => JobEntryScreen(jobId: n.jobId!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Notifications', showBack: true),
        Expanded(
          child: StreamBuilder<List<NotificationModel>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load notifications.\n${snap.error}');
              if (!snap.hasData) return const LoadingView();
              final all = snap.data!;
              final unread = all.where((n) => !n.read).toList();
              final shown = all.where(_match).toList();
              final children = <Widget>[];
              String? last;
              for (final n in shown) {
                final b = _bucket(n.createdAt);
                if (b != last) {
                  children.add(Padding(
                    padding: const EdgeInsets.fromLTRB(2, 10, 0, 8),
                    child: Text(b, style: ts(10.5, w: FontWeight.w700, color: AdminColors.grey)),
                  ));
                  last = b;
                }
                children.add(Padding(padding: const EdgeInsets.only(bottom: 10), child: _card(n)));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Row(children: [
                    Text('Inbox', style: ts(22, w: FontWeight.w700)),
                    const SizedBox(width: 8),
                    if (unread.isNotEmpty) StatusPill('${unread.length} New', tone: Tone.orange, size: 10),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: unread.isEmpty
                          ? null
                          : () => runAdminAction(context, () => _repo.markAllRead(unread.map((n) => n.id).toList()),
                              success: 'All notifications marked as read'),
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: const Text('Mark all read'),
                    ),
                  ]),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      AdminChoiceChip(label: 'All', selected: _filter == _Filter.all, onTap: () => setState(() => _filter = _Filter.all)),
                      AdminChoiceChip(label: 'Bookings', selected: _filter == _Filter.bookings, onTap: () => setState(() => _filter = _Filter.bookings)),
                      AdminChoiceChip(label: 'Messages', selected: _filter == _Filter.messages, onTap: () => setState(() => _filter = _Filter.messages)),
                      AdminChoiceChip(label: 'System', selected: _filter == _Filter.system, onTap: () => setState(() => _filter = _Filter.system)),
                    ]),
                  ),
                  if (shown.isEmpty)
                    const EmptyView(message: 'You are all caught up', icon: Icons.notifications_none_rounded)
                  else
                    ...children,
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _card(NotificationModel n) {
    final urgent = n.type == 'urgent';
    return GestureDetector(
      onTap: () => _open(n),
      child: AdminCard(
        borderColor: urgent && !n.read ? AdminColors.primary : null,
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
                radius: 18,
                backgroundColor: urgent ? AdminColors.chipBg : AdminColors.field,
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
                const SizedBox(height: 2),
                Text(n.body, style: ts(12, color: AdminColors.grey)),
              ]),
            ),
          ]),
          if (urgent && n.jobId != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              AdminButton('Review Request',
                  kind: ButtonKind.filled, icon: Icons.arrow_forward_rounded, height: 38,
                  onPressed: () => _open(n)),
              const SizedBox(width: 8),
              AdminButton('Dismiss', height: 38,
                  onPressed: () => runAdminAction(context, () => _repo.dismissNotification(n.id),
                      success: 'Notification dismissed', showLoader: false)),
            ]),
          ],
        ]),
      ),
    );
  }
}
