import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import '../../data/models/customer_chat.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/customer_header.dart';
import 'customer_chat_screen.dart';

class CustomerMessagesScreen extends StatefulWidget {
  const CustomerMessagesScreen({super.key});

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen> {
  late final Stream<List<CustomerThread>> _stream = CustomerRepository.instance.watchThreads();

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Messages'),
        Expanded(
          child: StreamBuilder<List<CustomerThread>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load chats.\n${snap.error}');
              if (!snap.hasData) return const LoadingView();
              final list = snap.data!;
              if (list.isEmpty) {
                return const EmptyView(
                    message: 'No conversations yet.\nChat with a provider from Search or a booking.',
                    icon: Icons.chat_bubble_outline_rounded);
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _tile(list[i]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _tile(CustomerThread t) {
    return FutureBuilder<ProviderProfile?>(
      future: CustomerRepository.instance.getProvider(t.providerId).catchError((Object _) => null),
      builder: (context, snap) {
        final p = snap.data;
        final name = p?.name ?? t.providerName;
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => CustomerChatScreen(
              thread: CustomerThread(
                id: t.id,
                providerId: t.providerId,
                providerName: name,
                providerPhotoUrl: p?.photoUrl ?? t.providerPhotoUrl,
                bookingNo: t.bookingNo,
                bookingId: t.bookingId,
              ),
            ),
          )),
          child: AdminCard(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              AdminAvatar(name: name, photoUrl: p?.photoUrl ?? t.providerPhotoUrl, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: ts(14, w: FontWeight.w700)),
                  Text(t.lastMessage ?? (t.isDirect ? 'Direct enquiry' : 'Booking #HF-${t.bookingNo}'),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(12, color: AdminColors.grey)),
                ]),
              ),
              Text(timeAgo(t.lastAt), style: ts(10.5, color: AdminColors.grey)),
            ]),
          ),
        );
      },
    );
  }
}
