import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../../data/models/customer_profile.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/customer_header.dart';

class EmergencyInfoScreen extends StatefulWidget {
  const EmergencyInfoScreen({super.key, required this.profile});
  final CustomerProfile profile;

  @override
  State<EmergencyInfoScreen> createState() => _EmergencyInfoScreenState();
}

class _EmergencyInfoScreenState extends State<EmergencyInfoScreen> {
  final _key = GlobalKey<FormState>();
  late final _gate = TextEditingController(text: widget.profile.gateCode);
  late final _pets = TextEditingController(text: widget.profile.petSafety);
  late final _phone = TextEditingController(text: widget.profile.secondaryPhone);
  late final _notes = TextEditingController(text: widget.profile.extraNotes);

  @override
  void dispose() {
    for (final c in [_gate, _pets, _phone, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String l, {String? hint}) => InputDecoration(
      labelText: l, hintText: hint, border: const OutlineInputBorder(), filled: true, fillColor: Colors.white);

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final ok = await runAdminAction(
      context,
      () => CustomerRepository.instance.saveEmergencyInfo(
          gateCode: _gate.text, petSafety: _pets.text, secondaryPhone: _phone.text, notes: _notes.text),
      success: 'Emergency info saved',
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Emergency Contacts & Notes', showBack: true),
        Expanded(
          child: Form(
            key: _key,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Text('Helps technicians reach you and enter safely. Shared only with providers on your active bookings.',
                  style: ts(11.5, color: AdminColors.grey)),
              const SizedBox(height: 12),
              TextFormField(controller: _gate, decoration: _dec('Gate / buzzer code', hint: 'e.g. #4B left of entrance')),
              const SizedBox(height: 12),
              TextFormField(controller: _pets, decoration: _dec('Pet safety notes', hint: 'e.g. Dog in backyard')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _dec('Secondary phone'),
                validator: (v) => (v == null || v.trim().isEmpty || RegExp(r'^[+0-9 ()\-]{7,20}$').hasMatch(v.trim()))
                    ? null
                    : 'Enter a valid phone number',
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _notes, maxLines: 4, maxLength: 300, decoration: _dec('Other notes')),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AdminButton('Save', kind: ButtonKind.filled, icon: Icons.save_outlined, height: 50, onPressed: _save),
        ),
      ]),
    );
  }
}
