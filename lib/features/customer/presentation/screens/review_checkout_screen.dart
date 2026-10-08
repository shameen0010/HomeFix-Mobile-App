import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/customer_header.dart';

/// "Service Completed" + rating and review (Booking Checkout).
class ReviewCheckoutScreen extends StatefulWidget {
  const ReviewCheckoutScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<ReviewCheckoutScreen> createState() => _ReviewCheckoutScreenState();
}

class _ReviewCheckoutScreenState extends State<ReviewCheckoutScreen> {
  final _repo = CustomerRepository.instance;
  late final Stream<BookingInfo?> _stream = _repo.watchBooking(widget.bookingId);
  final _comment = TextEditingController();
  final _tagOptions = const ['Punctual', 'Clean Work', 'Polite', 'Great Value', 'Expert Advice'];
  final _tags = <String>{'Punctual', 'Clean Work', 'Polite', 'Expert Advice'};
  ProviderProfile? _provider;
  bool _providerLoaded = false;
  int _rating = 5;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  String get _ratingLabel => const {
        5: 'Exceptional Service!',
        4: 'Great Service',
        3: 'Good',
        2: 'Could be better',
        1: 'Poor',
      }[_rating]!;

  void _loadProvider(String id) {
    if (_providerLoaded || id.isEmpty) return;
    _providerLoaded = true;
    _repo.getProvider(id).then((p) {
      if (mounted) setState(() => _provider = p);
    }).catchError((Object _) {});
  }

  Future<void> _submit(BookingInfo b) async {
    if (_rating <= 2 && _comment.text.trim().length < 10) {
      showAdminSnack(context, 'Please tell us what went wrong (at least 10 characters).', error: true);
      return;
    }
    final ok = await runAdminAction(
      context,
      () => _repo.submitReview(
          bookingId: b.id, rating: _rating.toDouble(), comment: _comment.text, tags: _tags.toList()),
      success: 'Thanks! Your review was submitted.',
    );
    if (ok && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      CustomerNav.goTab(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Booking Checkout', showBack: true),
        Expanded(
          child: StreamBuilder<BookingInfo?>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load the booking.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final b = snap.data;
              if (b == null) return const ErrorView(message: 'This booking no longer exists.');
              _loadProvider(b.providerId);
              return _body(b);
            },
          ),
        ),
      ]),
    );
  }

  Widget _body(BookingInfo b) {
    final name = b.providerName;
    final first = name.split(' ').first;
    final canReview = b.status == 'completed' && !b.reviewed;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        AdminCard(
          color: AdminColors.chipBg,
          child: Column(children: [
            const CircleAvatar(radius: 32, backgroundColor: AdminColors.primary,
                child: Icon(Icons.check_rounded, color: Colors.white, size: 36)),
            const SizedBox(height: 8),
            Text('JOB COMPLETED', style: ts(10, w: FontWeight.w700, color: AdminColors.primary)),
            Text('Service Completed!', style: ts(22, w: FontWeight.w700)),
            Text('Your technician has finished the assignment and all work is verified.',
                textAlign: TextAlign.center, style: ts(11.5, color: AdminColors.grey)),
          ]),
        ),
        const SizedBox(height: 12),
        AdminCard(
          child: Row(children: [
            AdminAvatar(name: name, photoUrl: _provider?.photoUrl, radius: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.title, style: ts(16, w: FontWeight.w700)),
                Text('by $name', style: ts(12, color: AdminColors.grey)),
                if (_provider != null)
                  Row(children: [
                    const Icon(Icons.verified_outlined, size: 14, color: AdminColors.primary),
                    const SizedBox(width: 4),
                    Flexible(child: Text('Certified Master ${_provider!.trade}',
                        style: ts(11, w: FontWeight.w600, color: AdminColors.primary))),
                  ]),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (b.reviewed)
          AdminCard(
            child: Column(children: [
              const Icon(Icons.favorite_rounded, color: AdminColors.red, size: 32),
              const SizedBox(height: 8),
              Text('You already reviewed this job. Thank you!', style: ts(13, w: FontWeight.w600)),
            ]),
          )
        else if (!canReview)
          AdminCard(
            child: Text('You can leave a review once the technician closes the job.',
                style: ts(12.5, color: AdminColors.grey)),
          )
        else
          AdminCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SHARE YOUR FEEDBACK', style: ts(10, w: FontWeight.w700, color: AdminColors.primary)),
              Text('How was your experience with $first?', style: ts(19, w: FontWeight.w700, height: 1.25)),
              const SizedBox(height: 4),
              Text('Your honest rating helps build neighborhood trust and supports local technicians.',
                  style: ts(11, color: AdminColors.grey)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        onPressed: () => setState(() => _rating = i),
                        icon: Icon(i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 34, color: AdminColors.orange),
                      ),
                  ]),
                  Text('$_rating.0 - $_ratingLabel', style: ts(13, w: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 12),
              Text('What went well?', style: ts(12, w: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in _tagOptions)
                  FilterChip(
                    label: Text(t),
                    selected: _tags.contains(t),
                    onSelected: (v) => setState(() => v ? _tags.add(t) : _tags.remove(t)),
                  ),
              ]),
              const SizedBox(height: 12),
              Text('Detailed Review', style: ts(12, w: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _comment,
                maxLines: 5,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tell others about your experience...',
                  filled: true,
                  fillColor: AdminColors.field,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  helperText: 'Visible to verified residents',
                ),
              ),
            ]),
          ),
        const SizedBox(height: 14),
        if (canReview)
          AdminButton('Submit Review',
              kind: ButtonKind.filled, icon: Icons.send_rounded, height: 50, onPressed: () => _submit(b)),
        const SizedBox(height: 8),
        AdminButton('Back to Home', icon: Icons.home_outlined, height: 48, onPressed: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          CustomerNav.goTab(0);
        }),
      ],
    );
  }
}
