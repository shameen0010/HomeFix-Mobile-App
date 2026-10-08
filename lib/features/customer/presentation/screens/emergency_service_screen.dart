import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../../data/models/booking_draft.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/customer_header.dart';
import 'emergency_details_screen.dart';

/// Emergency flow, step 1 of 4: choose the emergency type (FR-B04).
class EmergencyServiceScreen extends StatefulWidget {
  const EmergencyServiceScreen({super.key, this.presetProviderId});

  /// When set (provider opened from Search in emergency mode) the provider list step is skipped.
  final String? presetProviderId;

  @override
  State<EmergencyServiceScreen> createState() => _EmergencyServiceScreenState();
}

class _EmergencyServiceScreenState extends State<EmergencyServiceScreen> {
  EmergencyType _selected = EmergencyType.all.first;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Emergency Booking', showBack: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const EmergencyProgress(step: 1),
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFB45309)),
                const SizedBox(width: 4),
                Text('FAST-TRACK REQUEST', style: ts(10.5, w: FontWeight.w700, color: const Color(0xFFB45309))),
              ]),
              const SizedBox(height: 4),
              Text('Emergency Booking', style: ts(24, w: FontWeight.w700)),
              Text('What help do you need right now?', style: ts(12.5, color: AdminColors.grey)),
              const SizedBox(height: 14),
              for (final t in EmergencyType.all)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = t),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _selected.id == t.id ? AdminColors.primary : AdminColors.border,
                            width: _selected.id == t.id ? 1.5 : 1),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        CircleAvatar(
                            radius: 22, backgroundColor: AdminColors.chipBg,
                            child: Icon(t.icon, color: AdminColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t.title, style: ts(15, w: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(t.description, style: ts(11, height: 1.4, color: AdminColors.grey)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 6, runSpacing: 4, children: [
                              for (var i = 0; i < t.tags.length; i++)
                                StatusPill(t.tags[i], tone: i == 0 ? Tone.orange : Tone.blue, size: 9.5),
                            ]),
                          ]),
                        ),
                        Icon(_selected.id == t.id ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                            color: _selected.id == t.id ? AdminColors.primary : AdminColors.border),
                      ]),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  for (final (icon, label) in const [
                    (Icons.verified_outlined, 'Vetted Pros'),
                    (Icons.lock_outline_rounded, 'Fixed Pricing'),
                    (Icons.shield_outlined, 'Covered'),
                  ])
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 15, color: AdminColors.primary),
                      const SizedBox(width: 4),
                      Text(label, style: ts(10, w: FontWeight.w600, color: AdminColors.dark)),
                    ]),
                ]),
              ),
            ],
          ),
        ),
        BottomActionBar(children: [
          AdminButton('Continue', kind: ButtonKind.filled, icon: Icons.arrow_forward_rounded, height: 50,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => EmergencyDetailsScreen(type: _selected, presetProviderId: widget.presetProviderId)))),
          const SizedBox(height: 6),
          Text('No prepayment required to place urgent request', style: ts(10.5, color: AdminColors.grey)),
        ]),
      ]),
    );
  }
}
