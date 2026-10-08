import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/provider_ui.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/provider_header.dart';

/// FR-P08: provider <-> customer chat, one thread per booking.
class ProviderChatScreen extends StatefulWidget {
  const ProviderChatScreen({super.key, required this.thread});
  final ChatThread thread;

  @override
  State<ProviderChatScreen> createState() => _ProviderChatScreenState();
}

class _ProviderChatScreenState extends State<ProviderChatScreen> {
  final _repo = ProviderRepository.instance;
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late final Stream<List<ChatMessage>> _stream = _repo.watchMessages(widget.thread.id);
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await runAdminAction(context, () => _repo.sendMessage(widget.thread, text),
        success: 'Sent', showLoader: false);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread;
    final when = t.scheduledAt == null ? '' : ' confirmed for ${formatDate(t.scheduledAt, 'MMM d, h:mm a')}';
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Provider Chat', showBack: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AdminCard(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Row(children: [
                AdminAvatar(name: t.customerName, photoUrl: t.customerPhotoUrl, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.customerName, style: ts(14.5, w: FontWeight.w700)),
                    Text('Customer', style: ts(11, color: AdminColors.grey)),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AdminColors.chipBg, borderRadius: BorderRadius.circular(20)),
                child: Text(t.bookingNo == 'direct' ? 'Direct enquiry from customer' : 'Booking #HF-${t.bookingNo}$when',
                    textAlign: TextAlign.center,
                    style: ts(10.5, w: FontWeight.w600, color: AdminColors.primary)),
              ),
            ]),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load messages.\n${snap.error}');
              if (!snap.hasData) return const LoadingView();
              final msgs = snap.data!;
              if (msgs.isEmpty) {
                return const EmptyView(
                    message: 'Say hello to your customer', icon: Icons.chat_bubble_outline_rounded);
              }
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: msgs.length,
                itemBuilder: (_, i) => _bubble(msgs[i]),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).viewPadding.bottom),
          color: Colors.white,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Type a message to ${t.customerName.split(' ').first}...',
                  hintStyle: ts(12.5, color: AdminColors.grey),
                  filled: true,
                  fillColor: AdminColors.field,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _sending
                ? const SizedBox(
                    width: 40, height: 40,
                    child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton.filled(
                    onPressed: _send,
                    style: IconButton.styleFrom(backgroundColor: AdminColors.primary),
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
          ]),
        ),
      ]),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.senderId == _repo.uid;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AdminColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          border: mine ? null : Border.all(color: AdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (m.text.isNotEmpty)
              Text(m.text, style: ts(13, color: mine ? Colors.white : AdminColors.dark)),
            if (m.imageUrl != null) ...[
              if (m.text.isNotEmpty) const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(m.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)),
              ),
            ],
            const SizedBox(height: 3),
            Text(m.createdAt == null ? 'sending...' : formatDate(m.createdAt, 'h:mm a'),
                style: ts(9.5, color: mine ? Colors.white70 : AdminColors.grey)),
          ],
        ),
      ),
    );
  }
}

/// Opens the dialer for a customer phone number.
Future<void> callCustomer(BuildContext context, String phone) async {
  if (phone.isEmpty || phone == '-') {
    showAdminSnack(context, 'No phone number on file for this customer.', error: true);
    return;
  }
  try {
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok && context.mounted) showAdminSnack(context, 'Could not start the call.', error: true);
  } catch (_) {
    if (context.mounted) showAdminSnack(context, 'Could not start the call.', error: true);
  }
}
