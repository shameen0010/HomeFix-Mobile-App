import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/provider_profile.dart';
import '../../data/models/service_item.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/provider_header.dart';

/// FR-P03: CRUD for the provider's service catalog.
class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final _repo = ProviderRepository.instance;
  late final Stream<List<ServiceItem>> _services = _repo.watchServices();
  late final Stream<ProviderProfile?> _profile = _repo.watchProfile();
  String _category = 'all';

  Future<void> _openForm(ProviderProfile? p, {ServiceItem? existing}) async {
    final categories = {...?p?.trades, if (existing != null) existing.category}.toList();
    if (categories.isEmpty) categories.add('General');
    final r = await showDialog<_ServiceForm>(
      context: context,
      builder: (_) => _ServiceDialog(existing: existing, categories: categories),
    );
    if (r == null || !mounted) return;
    if (r.delete && existing != null) {
      final ok = await confirmAction(context,
          title: 'Delete ${existing.name}?',
          message: 'Customers will no longer be able to book this service.',
          confirmLabel: 'Delete', destructive: true);
      if (!ok || !mounted) return;
      await runAdminAction(context, () => _repo.deleteService(existing.id), success: 'Service deleted');
      return;
    }
    await runAdminAction(
      context,
      () => _repo.saveService(
        id: existing?.id,
        name: r.name,
        category: r.category,
        price: r.price,
        priceType: r.priceType,
        durationMin: r.durationMin,
        durationMax: r.durationMax,
        isActive: r.isActive,
      ),
      success: existing == null ? 'Service added' : 'Service updated',
    );
  }

  Future<void> _editArea(ProviderProfile p) async {
    final r = await showDialog<(String, int)>(
        context: context, builder: (_) => _AreaDialog(area: p.coverageArea, radius: p.radiusMiles));
    if (r == null || !mounted) return;
    await runAdminAction(context, () => _repo.updateCoverage(r.$1, r.$2), success: 'Service area updated');
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Manage Services', showBack: true),
        Expanded(
          child: StreamBuilder<ProviderProfile?>(
            stream: _profile,
            builder: (context, ps) {
              if (ps.hasError) return ErrorView(message: 'Could not load profile.\n${ps.error}');
              if (ps.connectionState == ConnectionState.waiting) return const LoadingView();
              final p = ps.data;
              return StreamBuilder<List<ServiceItem>>(
                stream: _services,
                builder: (context, ss) {
                  if (ss.hasError) return ErrorView(message: 'Could not load services.\n${ss.error}');
                  if (!ss.hasData) return const LoadingView();
                  final all = ss.data!;
                  final active = all.where((s) => s.isActive).length;
                  final cats = all.map((s) => s.category).toSet().toList()..sort();
                  final shown = _category == 'all' ? all : all.where((s) => s.category == _category).toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      Row(children: [
                        Text('My Services', style: ts(22, w: FontWeight.w700)),
                        const SizedBox(width: 8),
                        StatusPill('$active Active Services', size: 10),
                      ]),
                      const SizedBox(height: 12),
                      if (p != null)
                        AdminCard(
                          child: Column(children: [
                            Row(children: [
                              const CircleAvatar(
                                  radius: 20, backgroundColor: AdminColors.chipBg,
                                  child: Icon(Icons.storefront_outlined, color: AdminColors.primary)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Active Catalog', style: ts(15, w: FontWeight.w700)),
                                  Text('Instant customer bookings enabled',
                                      style: ts(11, color: AdminColors.grey)),
                                ]),
                              ),
                              Switch(
                                value: p.catalogActive,
                                onChanged: (v) => runAdminAction(context, () => _repo.setCatalogActive(v),
                                    success: v ? 'Catalog enabled' : 'Catalog paused', showLoader: false),
                              ),
                            ]),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: AdminColors.field, borderRadius: BorderRadius.circular(20)),
                                  child: Row(children: [
                                    const Icon(Icons.navigation_outlined, size: 14, color: AdminColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text('Within ${p.radiusMiles} miles of ${p.coverageArea}',
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: ts(11, w: FontWeight.w600)),
                                    ),
                                  ]),
                                ),
                              ),
                              TextButton(onPressed: () => _editArea(p), child: const Text('Edit Area')),
                            ]),
                          ]),
                        ),
                      const SizedBox(height: 12),
                      AdminButton('Add New Service',
                          kind: ButtonKind.filled, icon: Icons.add_rounded, height: 48,
                          onPressed: () => _openForm(p)),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          AdminChoiceChip(
                              label: 'All', count: all.length, selected: _category == 'all',
                              onTap: () => setState(() => _category = 'all')),
                          for (final c in cats)
                            AdminChoiceChip(
                                label: c, count: all.where((s) => s.category == c).length,
                                selected: _category == c, onTap: () => setState(() => _category = c)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      if (shown.isEmpty)
                        const EmptyView(message: 'No services yet. Add your first one.', icon: Icons.work_outline_rounded)
                      else
                        for (final s in shown)
                          Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(p, s)),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AdminColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'Need custom pricing for materials? You can adjust quotes on-site after diagnostic directly from the active dispatch screen.',
                                style: ts(11, color: AdminColors.grey)),
                          ),
                        ]),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _card(ProviderProfile? p, ServiceItem s) {
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.handyman_rounded, size: 18, color: AdminColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              StatusPill(s.category.toUpperCase(), size: 9.5),
              const SizedBox(height: 4),
              Text(s.name, style: ts(16, w: FontWeight.w700)),
            ]),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => _openForm(p, existing: s),
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.payments_outlined, size: 16, color: AdminColors.orange),
          const SizedBox(width: 6),
          Text(formatMoney(s.price), style: ts(13.5, w: FontWeight.w700)),
          Text(' ${s.priceLabel}', style: ts(11, color: AdminColors.grey)),
          const SizedBox(width: 12),
          const Icon(Icons.schedule_rounded, size: 15, color: AdminColors.grey),
          const SizedBox(width: 4),
          Flexible(child: Text(s.durationLabel, style: ts(11, color: AdminColors.grey))),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.circle, size: 8, color: s.isActive ? AdminColors.primary : AdminColors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(s.isActive ? 'Active & Bookable' : 'Paused',
                  style: ts(11.5, w: FontWeight.w600,
                      color: s.isActive ? AdminColors.primary : AdminColors.grey)),
            ),
            Switch(
              value: s.isActive,
              onChanged: (v) => runAdminAction(context, () => _repo.setServiceActive(s.id, v),
                  success: v ? '${s.name} is bookable' : '${s.name} paused', showLoader: false),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ServiceForm {
  const _ServiceForm({
    this.delete = false,
    this.name = '',
    this.category = '',
    this.price = 0,
    this.priceType = 'fixed',
    this.durationMin = 0,
    this.durationMax = 0,
    this.isActive = true,
  });
  final bool delete, isActive;
  final String name, category, priceType;
  final double price;
  final int durationMin, durationMax;
}

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({required this.categories, this.existing});
  final ServiceItem? existing;
  final List<String> categories;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _price = TextEditingController(
      text: widget.existing == null ? '' : widget.existing!.price.toStringAsFixed(2));
  late final _min = TextEditingController(text: '${widget.existing?.durationMin ?? 30}');
  late final _max = TextEditingController(text: '${widget.existing?.durationMax ?? 60}');
  late String _category = widget.existing?.category ?? widget.categories.first;
  late String _type = widget.existing?.priceType ?? 'fixed';
  late bool _active = widget.existing?.isActive ?? true;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  String? _num(String? v, {bool decimal = false}) {
    final n = decimal ? double.tryParse(v?.trim() ?? '') : int.tryParse(v?.trim() ?? '');
    if (n == null || n <= 0) return 'Enter a value above 0';
    return null;
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    final min = int.parse(_min.text.trim());
    final max = int.parse(_max.text.trim());
    if (max < min) {
      showAdminSnack(context, 'Maximum duration must be at least the minimum.', error: true);
      return;
    }
    Navigator.pop(
        context,
        _ServiceForm(
          name: _name.text.trim(),
          category: _category,
          price: double.parse(_price.text.trim()),
          priceType: _type,
          durationMin: min,
          durationMax: max,
          isActive: _active,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add service' : 'Edit service',
          style: ts(17, w: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Service name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Enter a service name' : null,
            ),
            const SizedBox(height: 12),
            AdminDropdown<String>(
              label: 'Category',
              value: _category,
              items: {for (final c in widget.categories) c: c},
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            AdminDropdown<String>(
              label: 'Pricing',
              value: _type,
              items: const {'fixed': 'Fixed price', 'hourly': 'Base rate per hour'},
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: 'Price (${AdminConfig.currency})', border: const OutlineInputBorder()),
              validator: (v) => _num(v, decimal: true),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min mins', border: OutlineInputBorder()),
                  validator: _num,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max mins', border: OutlineInputBorder()),
                  validator: _num,
                ),
              ),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Active & bookable', style: ts(13)),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          ]),
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: () => Navigator.pop(context, const _ServiceForm(delete: true)),
            child: const Text('Delete', style: TextStyle(color: AdminColors.red)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _AreaDialog extends StatefulWidget {
  const _AreaDialog({required this.area, required this.radius});
  final String area;
  final int radius;

  @override
  State<_AreaDialog> createState() => _AreaDialogState();
}

class _AreaDialogState extends State<_AreaDialog> {
  final _key = GlobalKey<FormState>();
  late final _area = TextEditingController(text: widget.area == '-' ? '' : widget.area);
  late double _radius = widget.radius.toDouble();

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Service area', style: ts(17, w: FontWeight.w700)),
      content: Form(
        key: _key,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _area,
            decoration: const InputDecoration(labelText: 'Base location', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a location' : null,
          ),
          const SizedBox(height: 12),
          Text('Radius: ${_radius.round()} miles', style: ts(12.5, w: FontWeight.w600)),
          Slider(
            value: _radius,
            min: 1,
            max: 50,
            divisions: 49,
            onChanged: (v) => setState(() => _radius = v),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_key.currentState!.validate()) {
              Navigator.pop(context, (_area.text.trim(), _radius.round()));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
