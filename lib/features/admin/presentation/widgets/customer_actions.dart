import 'package:flutter/material.dart';

import '../../core/admin_feedback.dart';
import '../../core/admin_theme.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/admin_repository.dart';

/// Deactivate (asks for a reason) or reactivate a customer account.
Future<void> toggleCustomerStatus(
    BuildContext context, AdminRepository repo, AppUser user) async {
  if (user.isActive) {
    final reason = await promptText(
      context,
      title: 'Deactivate ${user.name}?',
      message: 'Active bookings are paused and app access is restricted.',
      hint: 'Reason for action (e.g. disputed cancellation fee)',
      confirmLabel: 'Deactivate',
    );
    if (reason == null || !context.mounted) return;
    await runAdminAction(
      context,
      () => repo.setCustomerActive(user.id, active: false, reason: reason),
      success: '${user.name} was deactivated',
    );
  } else {
    final ok = await confirmAction(
      context,
      title: 'Reactivate ${user.name}?',
      message: 'The customer regains full access to the app.',
      confirmLabel: 'Reactivate',
    );
    if (!ok || !context.mounted) return;
    await runAdminAction(
      context,
      () => repo.setCustomerActive(user.id, active: true),
      success: '${user.name} was reactivated',
    );
  }
}

/// Opens the edit dialog and saves the validated values.
Future<void> editCustomer(
    BuildContext context, AdminRepository repo, AppUser user) async {
  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (_) => _EditCustomerDialog(user: user),
  );
  if (result == null || !context.mounted) return;
  await runAdminAction(
    context,
    () => repo.updateCustomer(user.id,
        name: result['name']!,
        phone: result['phone']!,
        address: result['address']!),
    success: 'Customer details updated',
  );
}

class _EditCustomerDialog extends StatefulWidget {
  const _EditCustomerDialog({required this.user});
  final AppUser user;

  @override
  State<_EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<_EditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(
      text: widget.user.phone == '-' ? '' : widget.user.phone);
  late final _address = TextEditingController(
      text: widget.user.address == '-' ? '' : widget.user.address);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'address': _address.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit customer', style: ts(17, w: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: _dec('Full name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Enter a valid name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: _dec('Phone'),
                keyboardType: TextInputType.phone,
                validator: (v) => RegExp(r'^[+0-9 ()\-]{7,20}$')
                        .hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Enter a valid phone number',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: _dec('Default home address'),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().length < 5)
                    ? 'Enter a valid address'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
