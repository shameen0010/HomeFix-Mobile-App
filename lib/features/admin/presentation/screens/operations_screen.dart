import 'package:flutter/material.dart';

import '../../core/admin_feedback.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_widgets.dart';
import '../../data/models/service_category.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/category_style.dart';
import 'disputes_screen.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  late final Stream<List<ServiceCategory>> _stream = widget.repository.watchCategories();
  String _query = '';

  Future<void> _toggle(ServiceCategory c, bool value) => runAdminAction(
        context,
        () => widget.repository.setCategoryActive(c.id, value),
        success: '${c.name} ${value ? 'enabled' : 'disabled'}',
        showLoader: false,
      );

  Future<void> _delete(ServiceCategory c) async {
    final ok = await confirmAction(context,
        title: 'Delete ${c.name}?',
        message: 'This removes the category from the dispatch list. Existing bookings are not affected.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok || !mounted) return;
    await runAdminAction(context, () => widget.repository.deleteCategory(c.id),
        success: '${c.name} deleted');
  }

  Future<void> _reorder(List<ServiceCategory> list, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final ids = list.map((c) => c.id).toList();
    ids.insert(newIndex, ids.removeAt(oldIndex));
    await runAdminAction(context, () => widget.repository.reorderCategories(ids),
        success: 'Order updated', showLoader: false);
  }

  Future<void> _openForm(List<ServiceCategory> all, {ServiceCategory? existing}) async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder: (_) => _CategoryDialog(
        existing: existing,
        takenNames: all
            .where((c) => c.id != existing?.id)
            .map((c) => c.name.toLowerCase())
            .toSet(),
      ),
    );
    if (result == null || !mounted) return;
    await runAdminAction(
      context,
      () => widget.repository.saveCategory(
        id: existing?.id,
        name: result.name,
        icon: result.icon,
        servicesCount: result.servicesCount,
        nextOrder: all.length,
      ),
      success: existing == null ? 'Category added' : 'Category updated',
    );
  }

  Widget _card(ServiceCategory c, int index,
      {required bool draggable, required List<ServiceCategory> all}) {
    final style = categoryStyle(c.icon);
    return Container(
      key: ValueKey(c.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: AdminCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(children: [
          if (draggable)
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_indicator_rounded, color: AdminColors.grey),
            )
          else
            const SizedBox(width: 24),
          const SizedBox(width: 6),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(style.icon, color: style.fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(15.5, w: FontWeight.w700)),
                Text('${c.servicesCount} Services  |  ${c.prosCount} Pros',
                    style: ts(11, color: AdminColors.grey)),
              ],
            ),
          ),
          Switch(value: c.isActive, onChanged: (v) => _toggle(c, v)),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Edit',
            onPressed: () => _openForm(all, existing: c),
            icon: const Icon(Icons.edit_outlined, size: 20, color: AdminColors.grey),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Delete',
            onPressed: () => _delete(c),
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AdminColors.red),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(
        children: [
          const AdminHeader(subtitle: 'Operations Dispatch'),
          Expanded(
            child: StreamBuilder<List<ServiceCategory>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorView(message: 'Could not load categories.\n${snap.error}');
                }
                if (!snap.hasData) return const LoadingView();

                final all = snap.data!;
                final q = _query.trim().toLowerCase();
                final shown = q.isEmpty
                    ? all
                    : all.where((c) => c.name.toLowerCase().contains(q)).toList();
                final activeCount = all.where((c) => c.isActive).length;

                final Widget list = q.isEmpty
                    ? ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: shown.length,
                        onReorder: (o, n) => _reorder(all, o, n),
                        itemBuilder: (_, i) => _card(shown[i], i, draggable: true, all: all),
                      )
                    : Column(children: [
                        for (var i = 0; i < shown.length; i++)
                          _card(shown[i], i, draggable: false, all: all),
                      ]);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    AdminSearchBox(
                      hint: 'Search service verticals...',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 12),
                    if (shown.isEmpty)
                      const EmptyView(message: 'No categories found')
                    else
                      list,
                    AdminButton('Add Category',
                        kind: ButtonKind.filled,
                        icon: Icons.add_rounded,
                        height: 46,
                        onPressed: () => _openForm(all)),
                    const SizedBox(height: 14),
                    AdminCard(
                      color: AdminColors.chipBg,
                      child: Row(children: [
                        const Icon(Icons.hub_outlined, color: AdminColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Category Dispatch Status',
                                  style: ts(13.5, w: FontWeight.w700)),
                              Text('$activeCount of ${all.length} categories accepting bookings',
                                  style: ts(11.5, color: AdminColors.grey)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => DisputesScreen(repository: widget.repository),
                      )),
                      child: AdminCard(
                        child: Row(children: [
                          const Icon(Icons.gavel_rounded, color: AdminColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Job Dispute Resolution',
                                    style: ts(13.5, w: FontWeight.w700)),
                                Text('Review complaints, reviews and ratings',
                                    style: ts(11.5, color: AdminColors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AdminColors.grey),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFormResult {
  const _CategoryFormResult(this.name, this.icon, this.servicesCount);
  final String name, icon;
  final int servicesCount;
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.takenNames, this.existing});
  final ServiceCategory? existing;
  final Set<String> takenNames;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _services =
      TextEditingController(text: '${widget.existing?.servicesCount ?? 0}');
  late String _icon = widget.existing?.icon ?? 'plumber';

  @override
  void dispose() {
    _name.dispose();
    _services.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context,
        _CategoryFormResult(_name.text.trim(), _icon, int.parse(_services.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add category' : 'Edit category',
          style: ts(17, w: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Category name', border: OutlineInputBorder()),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.length < 2) return 'Enter a category name';
                if (widget.takenNames.contains(t.toLowerCase())) {
                  return 'This category already exists';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _services,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Number of services', border: OutlineInputBorder()),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 0 || n > 999) return 'Enter a number from 0 to 999';
                return null;
              },
            ),
            const SizedBox(height: 12),
            AdminDropdown<String>(
              label: 'Icon',
              value: _icon,
              items: {for (final e in kCategoryStyles.entries) e.key: e.value.label},
              onChanged: (v) => setState(() => _icon = v),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
