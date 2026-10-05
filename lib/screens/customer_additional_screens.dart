import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/hf_theme.dart';
import '../../core/widgets/hf_widgets.dart';
import '../../data/homefix_store.dart';
import '../../data/models.dart';

class ServiceDetailsScreen extends ConsumerWidget {
  final String serviceId;
  const ServiceDetailsScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homefixStoreProvider);
    final service = state.services.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => state.services.first,
    );
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          HfScreenHeader(title: 'Service Details', onBack: () => context.pop()),
          const SizedBox(height: 16),
          HfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: HfColors.primarySoft,
                  radius: 32,
                  child: Icon(Icons.home_repair_service_outlined, color: HfColors.primary, size: 32),
                ),
                const SizedBox(height: 16),
                Text(service.title, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(service.subtitle, style: const TextStyle(color: HfColors.muted, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.star, color: HfColors.gold, size: 18),
                    const SizedBox(width: 4),
                    const Text('4.8', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    const Text('(245 reviews)', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('\$${service.price.toStringAsFixed(0)}${service.unit}', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: HfColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'Professional ${service.title.toLowerCase()} services provided by vetted experts. Includes inspection, diagnosis, and repair. All work is guaranteed for 30 days.',
                  style: const TextStyle(color: HfColors.muted, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What\'s Included', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                _IncludedItem('Professional inspection'),
                _IncludedItem('Quality materials'),
                _IncludedItem('30-day warranty'),
                _IncludedItem('Safety guarantee'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pricing', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                _PricingRow('Base service', '\$${service.price.toStringAsFixed(0)}'),
                _PricingRow('Emergency fee', '\$20'),
                const Divider(),
                _PricingRow('Total (approx)', '\$${(service.price + 20).toStringAsFixed(0)}', bold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HfPrimaryButton(
            label: 'Book This Service',
            onPressed: () {
              ref.read(draftProvider.notifier).set(DraftBooking(serviceId: service.id, serviceTitle: service.title, amount: service.price));
              context.go('/c/search');
            },
          ),
        ],
      ),
    );
  }

  Widget _IncludedItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: HfColors.success, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _PricingRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const HfScreenHeader(title: 'Notifications'),
          const SizedBox(height: 16),
          _NotificationItem(
            icon: Icons.check_circle,
            color: HfColors.success,
            title: 'Booking Confirmed',
            message: 'Your plumbing service is scheduled for today at 2:00 PM',
            time: '2 hours ago',
            unread: true,
          ),
          _NotificationItem(
            icon: Icons.directions_run,
            color: HfColors.orange,
            title: 'Provider En Route',
            message: 'David Smith is on the way to your location',
            time: '30 min ago',
            unread: true,
          ),
          _NotificationItem(
            icon: Icons.star,
            color: HfColors.gold,
            title: 'New Review',
            message: 'You received a 5-star review from Sarah Jenkins',
            time: 'Yesterday',
            unread: false,
          ),
          _NotificationItem(
            icon: Icons.local_offer,
            color: HfColors.primary,
            title: 'Special Offer',
            message: 'Get 20% off on your next cleaning service',
            time: '2 days ago',
            unread: false,
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String time;
  final bool unread;

  const _NotificationItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.time,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    return HfCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(message, style: const TextStyle(fontSize: 12)),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time, style: const TextStyle(fontSize: 11, color: HfColors.muted)),
            if (unread) const SizedBox(height: 4),
            if (unread) Container(width: 8, height: 8, decoration: BoxDecoration(color: HfColors.primary, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}

class PaymentConfirmationScreen extends ConsumerWidget {
  const PaymentConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homefixStoreProvider);
    final draft = ref.watch(draftProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          HfScreenHeader(title: 'Payment', onBack: () => context.pop()),
          const SizedBox(height: 20),
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: HfColors.primarySoft,
              child: Icon(Icons.payments, color: HfColors.primary, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text('Confirm Payment', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Please confirm that you have paid the service provider in cash', textAlign: TextAlign.center, style: TextStyle(color: HfColors.muted)),
          const SizedBox(height: 24),
          HfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Service Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                _SummaryRow('Service', draft.serviceTitle ?? 'N/A'),
                _SummaryRow('Provider', 'David Smith'),
                _SummaryRow('Date', 'Today, 2:00 PM'),
                const Divider(),
                _SummaryRow('Total Amount', 'Rs. ${draft.amount?.toStringAsFixed(0) ?? '0'}', bold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HfCard(
            color: HfColors.primarySoft,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: HfColors.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('HomeFix uses cash payment. Please ensure you have the exact amount ready.', style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HfPrimaryButton(
            label: 'Confirm Cash Payment',
            onPressed: () {
              context.push('/service-complete');
            },
          ),
          const SizedBox(height: 12),
          HfSoftButton(
            label: 'Report Issue',
            onPressed: () {
              hfSnack(context, 'Issue reported. Our team will contact you shortly.');
            },
          ),
        ],
      ),
    );
  }

  Widget _SummaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: HfColors.muted, fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class ServiceCompleteScreen extends ConsumerWidget {
  const ServiceCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          HfScreenHeader(title: 'Complete', onBack: () => context.pop()),
          const SizedBox(height: 40),
          const Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: HfColors.success,
              child: Icon(Icons.check, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 24),
          Text('Service Completed!', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Thank you for using HomeFix. Your service has been completed successfully.', textAlign: TextAlign.center, style: TextStyle(color: HfColors.muted)),
          const SizedBox(height: 32),
          HfCard(
            child: Column(
              children: [
                const Text('Rate your experience', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.star_border, size: 32, color: HfColors.gold),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const HfField(label: 'Write a review', hint: 'Share your experience with this provider...', icon: Icons.edit_outlined),
                const SizedBox(height: 12),
                HfPrimaryButton(
                  label: 'Submit Review',
                  onPressed: () {
                    context.push('/rate-review');
                  },
                ),
                const SizedBox(height: 12),
                HfSoftButton(
                  label: 'Skip for now',
                  onPressed: () {
                    context.go('/c/home');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RateReviewScreen extends ConsumerStatefulWidget {
  const RateReviewScreen({super.key});

  @override
  ConsumerState<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends ConsumerState<RateReviewScreen> {
  int _rating = 0;
  final _review = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          HfScreenHeader(title: 'Rate & Review', onBack: () => context.pop()),
          const SizedBox(height: 20),
          const Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: HfColors.primarySoft,
              child: Icon(Icons.star, color: HfColors.primary, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text('Rate your experience', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('How was your service with David Smith?', textAlign: TextAlign.center, style: TextStyle(color: HfColors.muted)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: HfColors.gold,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(_rating > 0 ? '$_rating out of 5' : 'Tap to rate', style: const TextStyle(color: HfColors.muted)),
          const SizedBox(height: 24),
          const Text('Write a review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          HfField(
            label: 'Your Review',
            hint: 'Share details about your experience...',
            icon: Icons.edit_outlined,
            controller: _review,
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          HfPrimaryButton(
            label: 'Submit Review',
            onPressed: () {
              if (_rating == 0) {
                hfSnack(context, 'Please select a rating');
                return;
              }
              hfSnack(context, 'Review submitted successfully!');
              context.go('/c/home');
            },
          ),
          const SizedBox(height: 12),
          HfSoftButton(
            label: 'Skip',
            onPressed: () {
              context.go('/c/home');
            },
          ),
        ],
      ),
    );
  }
}
