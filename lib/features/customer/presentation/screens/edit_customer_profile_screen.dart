import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../../data/models/customer_profile.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/customer_header.dart';

class EditCustomerProfileScreen extends StatefulWidget {
  const EditCustomerProfileScreen({super.key, required this.profile});
  final CustomerProfile profile;

  @override
  State<EditCustomerProfileScreen> createState() => _EditCustomerProfileScreenState();
}

class _EditCustomerProfileScreenState extends State<EditCustomerProfileScreen> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _phone = TextEditingController(text: widget.profile.phone == '-' ? '' : widget.profile.phone);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final ok = await runAdminAction(
        context, () => CustomerRepository.instance.updateProfile(name: _name.text, phone: _phone.text),
        success: 'Profile updated');
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Edit Profile', showBack: true),
        Expanded(
          child: Form(
            key: _key,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                validator: (v) => RegExp(r'^[+0-9 ()\-]{7,20}$').hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Enter a valid phone number',
              ),
              const SizedBox(height: 12),
              InfoField(label: 'Email (cannot be changed here)', value: widget.profile.email, icon: Icons.mail_outline_rounded),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AdminButton('Save Changes', kind: ButtonKind.filled, icon: Icons.save_outlined, height: 50, onPressed: _save),
        ),
      ]),
    );
  }
}
