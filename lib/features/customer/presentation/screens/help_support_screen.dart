import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/customer_ui.dart';
import '../widgets/customer_header.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    ('How do I pay?', 'You pay the technician in cash after the job is finished and inspected. Confirm the handover in the app so the job can be closed.'),
    ('How fast can a provider arrive?', 'Use Emergency Booking on the Home screen for the fastest dispatch (usually 15-30 minutes). Normal bookings follow the provider\'s working hours.'),
    ('Can I cancel a booking?', 'Yes. Open Bookings and tap Cancel while the booking is pending or confirmed.'),
    ('What is the 30-day guarantee?', 'Workmanship on completed HomeFix jobs is covered for 30 days once both you and the technician confirm the cash handover.'),
    ('A technician did not show up. What now?', 'Message the provider first, then call our customer care line so we can reassign your booking.'),
  ];

  Future<void> _call(BuildContext context) async {
    try {
      final ok = await launchUrl(Uri(scheme: 'tel', path: ProviderConfig.hotline));
      if (!ok && context.mounted) showAdminSnack(context, 'Could not start the call.', error: true);
    } catch (_) {
      if (context.mounted) showAdminSnack(context, 'Could not start the call.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Help & Support', showBack: true),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            AdminCard(
              child: Row(children: [
                const CircleAvatar(radius: 20, backgroundColor: AdminColors.orangeBg,
                    child: Icon(Icons.support_agent_rounded, color: AdminColors.orange)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Customer care', style: ts(14, w: FontWeight.w700)),
                      const SizedBox(width: 6),
                      const StatusPill('24/7', tone: Tone.orange, size: 9),
                    ]),
                    Text(ProviderConfig.hotline, style: ts(11.5, color: AdminColors.grey)),
                  ]),
                ),
                AdminButton('Call', icon: Icons.phone_outlined, kind: ButtonKind.filled, height: 38,
                    onPressed: () => _call(context)),
              ]),
            ),
            const SizedBox(height: 14),
            Text('Frequently asked questions', style: ts(15, w: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final f in _faqs)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.border)),
                child: Theme(
                  data: adminTheme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(f.$1, style: ts(13, w: FontWeight.w600)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(f.$2, style: ts(12, color: AdminColors.grey, height: 1.5))],
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}
