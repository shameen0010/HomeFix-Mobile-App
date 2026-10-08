import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/provider_profile.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/provider_header.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});
  final ProviderProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _key = GlobalKey<FormState>();
  late final ProviderProfile _p = widget.profile;
  late final _name = TextEditingController(text: _p.name);
  late final _headline = TextEditingController(text: _p.headline);
  late final _phone = TextEditingController(text: _p.phone == '-' ? '' : _p.phone);
  late final _years = TextEditingController(text: '${_p.experienceYears}');
  late final _area = TextEditingController(text: _p.coverageArea == '-' ? '' : _p.coverageArea);
  late final _radius = TextEditingController(text: '${_p.radiusMiles}');
  late final _bio = TextEditingController(text: _p.bio);
  late final _standard = TextEditingController(
      text: _p.pricing.isNotEmpty ? _p.pricing.first.price.toStringAsFixed(2) : '');
  late final _emergency = TextEditingController(
      text: _p.pricing.length > 1 ? _p.pricing[1].price.toStringAsFixed(2) : '');

  @override
  void dispose() {
    for (final c in [_name, _headline, _phone, _years, _area, _radius, _bio, _standard, _emergency]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String label, {String? prefix}) => InputDecoration(
      labelText: label, prefixText: prefix, border: const OutlineInputBorder(), filled: true, fillColor: Colors.white);

  String? _required(String? v, {int min = 2}) =>
      (v == null || v.trim().length < min) ? 'This field is required' : null;

  String? _int(String? v, {required int max}) {
    final n = int.tryParse(v?.trim() ?? '');
    return (n == null || n < 0 || n > max) ? 'Enter 0 - $max' : null;
  }

  String? _money(String? v) {
    final n = double.tryParse(v?.trim() ?? '');
    return (n == null || n <= 0) ? 'Enter a rate above 0' : null;
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final ok = await runAdminAction(
      context,
      () => ProviderRepository.instance.updateProfile(
        name: _name.text,
        headline: _headline.text,
        phone: _phone.text,
        experienceYears: int.parse(_years.text.trim()),
        coverageArea: _area.text,
        radiusMiles: int.parse(_radius.text.trim()),
        bio: _bio.text,
        standardRate: double.parse(_standard.text.trim()),
        emergencyRate: double.parse(_emergency.text.trim()),
      ),
      success: 'Profile updated',
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    Widget gap() => const SizedBox(height: 12);
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Edit Profile', showBack: true),
        Expanded(
          child: Form(
            key: _key,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                TextFormField(controller: _name, decoration: _dec('Full name'),
                    textCapitalization: TextCapitalization.words, validator: _required),
                gap(),
                TextFormField(controller: _headline, decoration: _dec('Headline (e.g. Master Plumber & Pipe Specialist)'),
                    validator: (v) => _required(v, min: 3)),
                gap(),
                TextFormField(
                  controller: _phone,
                  decoration: _dec('Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => RegExp(r'^[+0-9 ()\-]{7,20}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Enter a valid phone number',
                ),
                gap(),
                Row(children: [
                  Expanded(
                    child: TextFormField(controller: _years, decoration: _dec('Years of experience'),
                        keyboardType: TextInputType.number, validator: (v) => _int(v, max: 60)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(controller: _radius, decoration: _dec('Radius (miles)'),
                        keyboardType: TextInputType.number, validator: (v) => _int(v, max: 100)),
                  ),
                ]),
                gap(),
                TextFormField(controller: _area, decoration: _dec('Service coverage area'), validator: _required),
                gap(),
                TextFormField(
                  controller: _bio,
                  decoration: _dec('About me'),
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 600,
                  validator: (v) => _required(v, min: 20),
                ),
                gap(),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                        controller: _standard,
                        decoration: _dec('Standard rate /hr', prefix: AdminConfig.currency),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: _money),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                        controller: _emergency,
                        decoration: _dec('Emergency rate /hr', prefix: AdminConfig.currency),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: _money),
                  ),
                ]),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AdminButton('Save Changes',
              kind: ButtonKind.filled, icon: Icons.save_outlined, height: 50, onPressed: _save),
        ),
      ]),
    );
  }
}
