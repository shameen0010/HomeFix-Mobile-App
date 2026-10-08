import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../../data/models/customer_profile.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/customer_header.dart';

/// CRUD for saved addresses (users/{uid}/addresses).
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _repo = CustomerRepository.instance;
  late final Stream<List<SavedAddress>> _stream = _repo.watchAddresses();

  Future<void> _edit({SavedAddress? existing}) async {
    final r = await showDialog<_AddressResult>(context: context, builder: (_) => _AddressDialog(existing: existing));
    if (r == null || !mounted) return;
    if (r.delete && existing != null) {
      final ok = await confirmAction(context,
          title: 'Delete ${existing.label}?', message: 'This address will be removed from your account.',
          confirmLabel: 'Delete', destructive: true);
      if (!ok || !mounted) return;
      await runAdminAction(context, () => _repo.deleteAddress(existing.id), success: 'Address deleted');
      return;
    }
    await runAdminAction(
      context,
      () => _repo.saveAddress(id: existing?.id, label: r.label, address: r.address, isDefault: r.isDefault),
      success: existing == null ? 'Address saved' : 'Address updated',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'My Addresses', showBack: true),
        Expanded(
          child: StreamBuilder<List<SavedAddress>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load addresses.\n${snap.error}');
              if (!snap.hasData) return const LoadingView();
              final list = snap.data!;
              return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
                if (list.isEmpty)
                  const EmptyView(message: 'No saved addresses yet', icon: Icons.location_off_outlined),
                for (final a in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AdminCard(
                      child: Row(children: [
                        CircleAvatar(
                            backgroundColor: AdminColors.chipBg,
                            child: Icon(a.label == 'Office' ? Icons.business_rounded : Icons.home_rounded,
                                color: AdminColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(a.label, style: ts(14, w: FontWeight.w700)),
                              const SizedBox(width: 6),
                              if (a.isDefault) const StatusPill('Default', size: 9),
                            ]),
                            Text(a.address, style: ts(11.5, color: AdminColors.grey)),
                          ]),
                        ),
                        IconButton(onPressed: () => _edit(existing: a), icon: const Icon(Icons.edit_outlined, size: 20)),
                      ]),
                    ),
                  ),
              ]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AdminButton('Add Address', kind: ButtonKind.filled, icon: Icons.add_rounded, height: 50, onPressed: () => _edit()),
        ),
      ]),
    );
  }
}

class _AddressResult {
  const _AddressResult({this.delete = false, this.label = '', this.address = '', this.isDefault = false});
  final bool delete, isDefault;
  final String label, address;
}

class _AddressDialog extends StatefulWidget {
  const _AddressDialog({this.existing});
  final SavedAddress? existing;

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final _key = GlobalKey<FormState>();
  late final _address = TextEditingController(text: widget.existing?.address ?? '');
  late String _label = widget.existing?.label ?? 'Home';
  late bool _default = widget.existing?.isDefault ?? false;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add address' : 'Edit address', style: ts(17, w: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AdminDropdown<String>(
              label: 'Label',
              value: _label,
              items: const {'Home': 'Home', 'Office': 'Office', 'Other': 'Other'},
              onChanged: (v) => setState(() => _label = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Full address', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().length < 5) ? 'Enter the full address' : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Default address', style: ts(13)),
              value: _default,
              onChanged: (v) => setState(() => _default = v),
            ),
          ]),
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
              onPressed: () => Navigator.pop(context, const _AddressResult(delete: true)),
              child: const Text('Delete', style: TextStyle(color: AdminColors.red))),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_key.currentState!.validate()) {
              Navigator.pop(context, _AddressResult(label: _label, address: _address.text, isDefault: _default));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
