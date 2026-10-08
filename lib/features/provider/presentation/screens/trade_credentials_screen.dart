import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/provider_header.dart';
import 'registration_complete_screen.dart';

class _Trade {
  const _Trade(this.name, this.subtitle, this.icon);
  final String name, subtitle;
  final IconData icon;
}

const _trades = [
  _Trade('Plumber', 'Pipes, leaks & drains', Icons.plumbing_rounded),
  _Trade('Electrician', 'Wiring, fixtures & panel', Icons.bolt_rounded),
  _Trade('Cleaner', 'Deep cleaning & turnover', Icons.cleaning_services_rounded),
  _Trade('Carpenter', 'Furniture & woodwork', Icons.carpenter_rounded),
  _Trade('Painter', 'Interior & exterior paint', Icons.format_paint_rounded),
  _Trade('Appliance Repair', 'HVAC, fridge & oven', Icons.home_repair_service_rounded),
];

/// Registration step shown right after provider sign-up.
class TradeCredentialsScreen extends StatefulWidget {
  const TradeCredentialsScreen({super.key});

  @override
  State<TradeCredentialsScreen> createState() => _TradeCredentialsScreenState();
}

class _TradeCredentialsScreenState extends State<TradeCredentialsScreen> {
  final _repo = ProviderRepository.instance;
  final _selected = <String>[];

  void _toggle(String name) => setState(() {
        _selected.contains(name) ? _selected.remove(name) : _selected.add(name);
      });

  Future<void> _continue() async {
    if (_selected.isEmpty) {
      showAdminSnack(context, 'Select at least one service to continue.', error: true);
      return;
    }
    final ok = await runAdminAction(context, () => _repo.saveTradeCredentials(_selected),
        success: 'Credentials saved');
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
          builder: (_) => const RegistrationCompleteScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _selected.isEmpty
        ? 'No service selected yet'
        : 'Selected: ${_selected.length} service${_selected.length == 1 ? '' : 's'} chosen (${_selected.join(', ')})';
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Trade Credentials', showBack: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Text('What service do you provide?', style: ts(24, w: FontWeight.w700, height: 1.2)),
              const SizedBox(height: 6),
              Text('Select the service you offer to customers.',
                  style: ts(13, color: AdminColors.grey)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.info_outline_rounded, size: 15, color: AdminColors.primary),
                const SizedBox(width: 6),
                Text('You can select one or multiple services.',
                    style: ts(11.5, w: FontWeight.w600, color: AdminColors.primary)),
              ]),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  for (final t in _trades) _tile(t),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: StatusPill(label, tone: Tone.orange, size: 11),
              ),
              const SizedBox(height: 14),
              AdminCard(
                color: AdminColors.field,
                child: Row(children: [
                  const Icon(Icons.verified_user_outlined, color: AdminColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Verified Partner Network', style: ts(13, w: FontWeight.w700)),
                      Text('Showcase certifications & insurance in the next step',
                          style: ts(11, color: AdminColors.grey)),
                    ]),
                  ),
                ]),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AdminButton('Continue',
                kind: ButtonKind.filled, icon: Icons.arrow_forward_rounded, height: 50,
                onPressed: _continue),
            const SizedBox(height: 6),
            Text('You can add more specialty services later in your profile.',
                style: ts(10.5, color: AdminColors.grey)),
          ]),
        ),
      ]),
    );
  }

  Widget _tile(_Trade t) {
    final on = _selected.contains(t.name);
    return GestureDetector(
      onTap: () => _toggle(t.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: on ? AdminColors.chipBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? AdminColors.primary : AdminColors.border, width: on ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: on ? AdminColors.primary : AdminColors.field,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(t.icon, size: 18, color: on ? Colors.white : AdminColors.primary),
            ),
            const Spacer(),
            if (on)
              const CircleAvatar(
                  radius: 10, backgroundColor: AdminColors.primary,
                  child: Icon(Icons.check, size: 13, color: Colors.white)),
          ]),
          const Spacer(),
          Text(t.name, style: ts(15, w: FontWeight.w700)),
          Text(t.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: ts(10.5, color: AdminColors.grey)),
        ]),
      ),
    );
  }
}
