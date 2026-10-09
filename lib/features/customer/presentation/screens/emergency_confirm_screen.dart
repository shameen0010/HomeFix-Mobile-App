import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../../provider/data/models/service_item.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_draft.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/customer_header.dart';
import 'emergency_status_screen.dart';

/// Emergency flow, step 4 of 4: review and dispatch (FR-B03, FR-B05).
class EmergencyConfirmScreen extends StatelessWidget {
  EmergencyConfirmScreen({super.key, required this.request, required this.provider, required this.service});
  final EmergencyRequest request;
  final ProviderProfile provider;
  final ServiceItem service;
  final _repo = CustomerRepository.instance;

  Future<void> _confirm(BuildContext context) async {
    String? id;
    final ok = await runAdminAction(
      context,
      () async {
        id = await _repo
            .createBooking(
              provider: provider,
              service: service,
              scheduledAt: DateTime.now().add(const Duration(minutes: 30)),
              address: request.fullAddress,
              notes: request.problem,
              emergency: true,
              photos: request.photos,
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw AdminException(
                'Emergency booking is taking too long. Check your internet connection and try again.',
              ),
            );
      },
      success: 'Emergency request sent',
    );
    final bookingId = id;
    if (!ok || bookingId == null || !context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => EmergencyStatusScreen(bookingId: bookingId)),
      (r) => r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quote = PriceQuote.emergency(service, provider);
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Review & Confirm', showBack: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const EmergencyProgress(step: 4),
              const SizedBox(height: 12),
              Text('Confirm Emergency Booking', style: ts(21, w: FontWeight.w700)),
              Text('Review your dispatch details before our priority line connects you.',
                  style: ts(12, color: AdminColors.grey)),
              const SizedBox(height: 12),
              const NoticeBox(
                icon: Icons.bolt_rounded,
                title: 'Instant Dispatch Notice',
                text: 'The provider will be notified about your emergency request immediately upon confirmation.',
              ),
              const SizedBox(height: 12),
              AdminCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(radius: 16, backgroundColor: AdminColors.chipBg,
                        child: Icon(request.type.icon, size: 17, color: AdminColors.primary)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('EMERGENCY SERVICE', style: ts(9, w: FontWeight.w700, color: AdminColors.grey)),
                        Text(request.type.title, style: ts(15, w: FontWeight.w700)),
                      ]),
                    ),
                    const StatusPill('Urgent', tone: Tone.orange, size: 10),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      AdminAvatar(name: provider.name, photoUrl: provider.photoUrl, radius: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(provider.name, style: ts(14, w: FontWeight.w700)),
                          Text('${provider.headline} \u2022 ${provider.experienceYears} yrs exp',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: ts(10.5, color: AdminColors.grey)),
                        ]),
                      ),
                      StatusPill('\u2605 ${provider.rating.toStringAsFixed(1)}', tone: Tone.orange, size: 10),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AdminColors.grey),
                    const SizedBox(width: 6),
                    Text('Technician Status', style: ts(11.5, color: AdminColors.grey)),
                    const Spacer(),
                    const Icon(Icons.circle, size: 8, color: AdminColors.primary),
                    const SizedBox(width: 4),
                    Text('Available Now (Priority Queue)',
                        style: ts(11, w: FontWeight.w700, color: AdminColors.primary)),
                  ]),
                  const SizedBox(height: 10),
                  _block(Icons.place_outlined, 'Service Destination', request.fullAddress, trailing: 'Manual Entry'),
                  const SizedBox(height: 8),
                  _block(Icons.warning_amber_rounded, 'Problem Description', request.problem.trim()),
                  if (request.photos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: ListView(scrollDirection: Axis.horizontal, children: [
                        for (final b in request.photos)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(b, width: 56, height: 56, fit: BoxFit.cover)),
                          ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Estimated Diagnostic Fee', style: ts(12.5, w: FontWeight.w700)),
                        Text('Cash / Direct settlement on-site', style: ts(10.5, color: AdminColors.grey)),
                      ]),
                    ),
                    Text(formatMoney(quote.total), style: ts(24, w: FontWeight.w700, color: AdminColors.primary)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              const NoticeBox(
                icon: Icons.payments_outlined,
                title: 'No Upfront Online Payment',
                text: 'Pay your technician directly via cash or approved settlement after work is completed.',
              ),
            ],
          ),
        ),
        BottomActionBar(children: [
          AdminButton('Confirm Emergency Booking',
              kind: ButtonKind.filled, icon: Icons.bolt_rounded, height: 50, onPressed: () => _confirm(context)),
          TextButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('Cancel Request')),
        ]),
      ]),
    );
  }

  Widget _block(IconData icon, String label, String value, {String? trailing}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: AdminColors.grey),
            const SizedBox(width: 5),
            Text(label, style: ts(10, color: AdminColors.grey)),
            const Spacer(),
            if (trailing != null) Text(trailing, style: ts(9.5, w: FontWeight.w600, color: AdminColors.orange)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: ts(12.5, w: FontWeight.w600, height: 1.4)),
        ]),
      );
}
