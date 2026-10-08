import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../../data/models/booking_draft.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/customer_header.dart';
import 'emergency_confirm_screen.dart';
import 'emergency_providers_screen.dart';

/// Emergency flow, step 2 of 4: address, problem description, photos (FR-B02, FR-B04).
class EmergencyDetailsScreen extends StatefulWidget {
  const EmergencyDetailsScreen({super.key, required this.type, this.presetProviderId});
  final EmergencyType type;
  final String? presetProviderId;

  @override
  State<EmergencyDetailsScreen> createState() => _EmergencyDetailsScreenState();
}

class _EmergencyDetailsScreenState extends State<EmergencyDetailsScreen> {
  final _repo = CustomerRepository.instance;
  late final EmergencyRequest _req = EmergencyRequest(type: widget.type);
  final _address = TextEditingController();
  final _area = TextEditingController();
  final _unit = TextEditingController();
  final _problem = TextEditingController();
  String? _addressErr, _areaErr, _problemErr;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _repo.getAddresses().then((l) {
      if (!mounted || _address.text.isNotEmpty) return;
      final def = l.where((a) => a.isDefault).toList();
      if (def.isNotEmpty) setState(() => _address.text = def.first.address);
    }).catchError((Object _) {});
    _repo.getMe().then((m) {
      if (!mounted || _area.text.isNotEmpty || m == null) return;
      setState(() => _area.text = m.location);
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _address.dispose();
    _area.dispose();
    _unit.dispose();
    _problem.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _addressErr = _address.text.trim().length < 5 ? 'Enter the street address' : null;
      _areaErr = _area.text.trim().length < 2 ? 'Enter your area or city' : null;
      _problemErr = _problem.text.trim().length < 10 ? 'Describe the problem (at least 10 characters)' : null;
    });
    return _addressErr == null && _areaErr == null && _problemErr == null;
  }

  Future<void> _next() async {
    if (!_validate()) return;
    _req
      ..address = _address.text
      ..area = _area.text
      ..unit = _unit.text
      ..problem = _problem.text;
    final preset = widget.presetProviderId;
    if (preset == null) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EmergencyProvidersScreen(request: _req)));
      return;
    }
    setState(() => _busy = true);
    try {
      final p = await _repo.getProvider(preset);
      if (p == null) throw AdminException('This provider is no longer available.');
      final s = _req.type.pick(await _repo.getServices(preset));
      if (s == null) throw AdminException('This provider has no bookable services yet.');
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => EmergencyConfirmScreen(request: _req, provider: p, service: s)));
    } on AdminException catch (e) {
      if (mounted) showAdminSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Emergency Details', showBack: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const EmergencyProgress(step: 2),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: AdminColors.primary,
                      child: Icon(widget.type.icon, size: 17, color: Colors.white)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Active Emergency', style: ts(10, color: AdminColors.grey)),
                      Text(widget.type.title, style: ts(13.5, w: FontWeight.w700)),
                    ]),
                  ),
                  AdminButton('Change', height: 32, onPressed: () => Navigator.of(context).maybePop()),
                ]),
              ),
              const SizedBox(height: 14),
              Text('Tell Us About the Emergency', style: ts(20, w: FontWeight.w700)),
              Text('Provide your address and describe the problem.', style: ts(12, color: AdminColors.grey)),
              const SizedBox(height: 12),
              const NoticeBox(
                icon: Icons.bolt_rounded,
                title: 'Rapid Dispatch Alert',
                text: 'A local technician will review your address and respond immediately upon submission.',
                bg: Color(0xFFF59E0B),
                fg: Colors.white,
              ),
              const FieldLabel('Service Address', required: true, hint: 'Street & Number'),
              TextField(
                  controller: _address,
                  textCapitalization: TextCapitalization.words,
                  decoration: fieldDeco('Enter your service address', icon: Icons.place_outlined)
                      .copyWith(errorText: _addressErr)),
              const FieldLabel('Area / City', required: true, hint: 'Neighborhood or Zip'),
              TextField(
                  controller: _area,
                  textCapitalization: TextCapitalization.words,
                  decoration: fieldDeco('e.g. Nugegoda, Colombo', icon: Icons.location_city_outlined)
                      .copyWith(errorText: _areaErr)),
              const FieldLabel('Apartment / Unit / Floor', hint: 'Optional'),
              TextField(
                  controller: _unit,
                  decoration: fieldDeco('Suite, floor, or entry access code', icon: Icons.apartment_outlined)),
              const FieldLabel('Describe the Problem', required: true, hint: 'Be specific'),
              TextField(
                  controller: _problem,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: fieldDeco('Briefly describe what happened (e.g. kitchen pipe burst under the sink)...')
                      .copyWith(errorText: _problemErr)),
              const FieldLabel('Add Photo', hint: 'Optional'),
              PhotoStrip(photos: _req.photos),
              const SizedBox(height: 12),
              const NoticeBox(
                icon: Icons.verified_user_outlined,
                text: 'Your address is securely transmitted only to licensed emergency technicians assigned to this call.',
              ),
            ],
          ),
        ),
        BottomActionBar(children: [
          AdminButton(widget.presetProviderId == null ? 'Find Available Providers' : 'Review Request',
              kind: ButtonKind.filled, icon: Icons.arrow_forward_rounded, height: 50, onPressed: _busy ? null : _next),
        ]),
      ]),
    );
  }
}
