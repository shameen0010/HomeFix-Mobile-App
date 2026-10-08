import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/provider_header.dart';
import 'provider_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final Stream<List<ChatThread>> _stream = ProviderRepository.instance.watchThreads();

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(subtitle: 'Messages'),
        Expanded(
          child: StreamBuilder<List<ChatThread>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load chats.\n${snap.error}');
              if (!snap.hasData) return const LoadingView();
              final list = snap.data!;
              if (list.isEmpty) {
                return const EmptyView(
                    message: 'No conversations yet.\nOpen a chat from an accepted booking.',
                    icon: Icons.chat_bubble_outline_rounded);
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final t = list[i];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => ProviderChatScreen(thread: t))),
                    child: AdminCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        AdminAvatar(name: t.customerName, photoUrl: t.customerPhotoUrl, radius: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t.customerName, style: ts(14, w: FontWeight.w700)),
                            Text(t.lastMessage ?? 'Booking #HF-${t.bookingNo}',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: ts(12, color: AdminColors.grey)),
                          ]),
                        ),
                        Text(timeAgo(t.lastAt), style: ts(10.5, color: AdminColors.grey)),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
