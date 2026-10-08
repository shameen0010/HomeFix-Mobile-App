import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/models/customer_chat.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/customer_header.dart';

/// Customer <-> provider chat (same chats/{id} documents the provider module uses).
class CustomerChatScreen extends StatefulWidget {
  const CustomerChatScreen({super.key, required this.thread});
  final CustomerThread thread;

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final _repo = CustomerRepository.instance;
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late final Stream<List<CustomerMessage>> _messages = _repo.watchMessages(widget.thread.id);
  late final Stream<ProviderProfile?> _provider = _repo.watchProvider(widget.thread.providerId);
  late final Stream<BookingInfo?>? _booking =
      widget.thread.bookingId == null ? null : _repo.watchBooking(widget.thread.bookingId!);
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });

  Future<void> _send({List<int>? imageBytes}) async {
    final text = _controller.text.trim();
    if (text.isEmpty && imageBytes == null) return;
    setState(() => _sending = true);
    final ok = await runAdminAction(
      context,
      () => _repo.sendMessage(widget.thread, text: text,
          image: imageBytes == null ? null : Uint8List.fromList(imageBytes)),
      success: 'Sent',
      showLoader: false,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _controller.clear();
      _toBottom();
    }
  }

  Future<void> _pickImage() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1600);
      if (f == null) return;
      await _send(imageBytes: await f.readAsBytes());
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Could not access your photos.', error: true);
    }
  }

  Future<void> _launch(Uri uri, String error) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
        showAdminSnack(context, error, error: true);
      }
    } catch (_) {
      if (mounted) showAdminSnack(context, error, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread;
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Chat Conversation', showBack: true),
        StreamBuilder<ProviderProfile?>(
          stream: _provider,
          builder: (context, snap) {
            final p = snap.data;
            return Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              child: Row(children: [
                AdminAvatar(name: p?.name ?? t.providerName, photoUrl: p?.photoUrl ?? t.providerPhotoUrl,
                    radius: 22, badgeColor: (p?.isOnline ?? false) ? AdminColors.orange : AdminColors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(p?.name ?? t.providerName, style: ts(15, w: FontWeight.w700))),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, size: 15, color: AdminColors.primary),
                    ]),
                    Row(children: [
                      Text((p?.isOnline ?? false) ? 'ACTIVE NOW' : 'OFFLINE',
                          style: ts(9.5, w: FontWeight.w700,
                              color: (p?.isOnline ?? false) ? const Color(0xFFB45309) : AdminColors.grey)),
                      if (p != null) ...[
                        Text('  |  ', style: ts(10, color: AdminColors.grey)),
                        const Icon(Icons.star_rounded, size: 13, color: AdminColors.orange),
                        Text(p.rating.toStringAsFixed(1), style: ts(10.5, w: FontWeight.w700)),
                      ],
                    ]),
                  ]),
                ),
                IconButton.filledTonal(
                  tooltip: 'Call',
                  onPressed: p == null || p.phone == '-'
                      ? null
                      : () => _launch(Uri(scheme: 'tel', path: p.phone), 'Could not start the call.'),
                  icon: const Icon(Icons.phone_outlined, size: 18),
                ),
                IconButton.filledTonal(
                  tooltip: 'Open in maps',
                  onPressed: p == null
                      ? null
                      : () => _launch(
                          Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': p.coverageArea}),
                          'Could not open maps.'),
                  icon: const Icon(Icons.near_me_outlined, size: 18),
                ),
              ]),
            );
          },
        ),
        if (_booking != null)
          StreamBuilder<BookingInfo?>(
            stream: _booking,
            builder: (context, snap) {
              final b = snap.data;
              if (b == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AdminColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.build_rounded, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.title, style: ts(12.5, w: FontWeight.w700)),
                      Text(formatDate(b.scheduledAt, 'EEE, MMM d, h:mm a'),
                          style: ts(10.5, color: AdminColors.grey)),
                    ]),
                  ),
                  StatusPill(b.status == 'in_progress' ? b.stageLabel : b.status.replaceAll('_', ' ').toUpperCase(),
                      tone: Tone.orange, size: 9.5),
                ]),
              );
            },
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('Direct enquiry - no booking yet', style: ts(11, color: AdminColors.grey)),
          ),
        Expanded(
          child: StreamBuilder<List<CustomerMessage>>(
            stream: _messages,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load messages.\n${snap.error}');
              if (!snap.hasData) return const LoadingView();
              final msgs = snap.data!;
              if (msgs.isEmpty) {
                return const EmptyView(message: 'Say hello to your technician', icon: Icons.chat_bubble_outline_rounded);
              }
              final children = <Widget>[];
              DateTime? lastDay;
              for (final m in msgs) {
                final d = m.createdAt;
                if (d != null && (lastDay == null || !DateUtils.isSameDay(lastDay, d))) {
                  lastDay = d;
                  children.add(Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                          DateUtils.isSameDay(d, DateTime.now())
                              ? 'Today, ${formatDate(d, 'MMMM d')}'
                              : formatDate(d, 'EEEE, MMMM d'),
                          style: ts(10.5, w: FontWeight.w600, color: AdminColors.primary)),
                    ),
                  ));
                }
                children.add(_bubble(m));
              }
              _toBottom();
              return ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), children: children);
            },
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + MediaQuery.of(context).viewPadding.bottom),
          color: Colors.white,
          child: Row(children: [
            IconButton(
                onPressed: _sending ? null : _pickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined, color: AdminColors.primary)),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: ts(12.5, color: AdminColors.grey),
                  filled: true,
                  fillColor: AdminColors.field,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _sending
                ? const SizedBox(width: 40, height: 40,
                    child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton.filled(
                    onPressed: _send,
                    style: IconButton.styleFrom(backgroundColor: AdminColors.primary),
                    icon: const Icon(Icons.send_rounded, size: 18)),
          ]),
        ),
      ]),
    );
  }

  Widget _bubble(CustomerMessage m) {
    final mine = m.senderId == _repo.uid;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
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
            if (m.text.isNotEmpty) Text(m.text, style: ts(13.5, color: mine ? Colors.white : AdminColors.dark)),
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
