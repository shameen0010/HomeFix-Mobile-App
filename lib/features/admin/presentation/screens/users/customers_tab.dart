import 'package:flutter/material.dart';

import '../../../core/admin_format.dart';
import '../../../core/admin_theme.dart';
import '../../../core/admin_widgets.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../widgets/customer_actions.dart';
import 'user_detail_screen.dart';

enum _Filter { all, active, suspended }

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  late final Stream<List<AppUser>> _stream = widget.repository.watchCustomers();
  _Filter _filter = _Filter.all;
  String _query = '';
  int _page = 1;

  List<AppUser> _apply(List<AppUser> all) {
    final q = _query.trim().toLowerCase();
    return all.where((u) {
      final byFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.active => u.isActive,
        _Filter.suspended => !u.isActive,
      };
      final byQuery = q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phone.contains(q) ||
          u.code.toLowerCase().contains(q);
      return byFilter && byQuery;
    }).toList();
  }

  void _setFilter(_Filter f) => setState(() {
        _filter = f;
        _page = 1;
      });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return ErrorView(message: 'Could not load customers.\n${snap.error}');
        }
        if (!snap.hasData) return const LoadingView();

        final all = snap.data!;
        final filtered = _apply(all);
        final totalPages = filtered.isEmpty
            ? 1
            : (filtered.length / AdminConfig.pageSize).ceil();
        final page = _page > totalPages ? totalPages : _page;
        final start = (page - 1) * AdminConfig.pageSize;
        final visible =
            filtered.skip(start).take(AdminConfig.pageSize).toList();
        final activeCount = all.where((u) => u.isActive).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            AdminSearchBox(
              hint: 'Search customers by name, phone, email',
              onChanged: (v) => setState(() {
                _query = v;
                _page = 1;
              }),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                AdminChoiceChip(
                    label: 'All',
                    count: all.length,
                    selected: _filter == _Filter.all,
                    onTap: () => _setFilter(_Filter.all)),
                AdminChoiceChip(
                    label: 'Active',
                    count: activeCount,
                    dotColor: AdminColors.primary,
                    selected: _filter == _Filter.active,
                    onTap: () => _setFilter(_Filter.active)),
                AdminChoiceChip(
                    label: 'Suspended',
                    count: all.length - activeCount,
                    dotColor: AdminColors.red,
                    selected: _filter == _Filter.suspended,
                    onTap: () => _setFilter(_Filter.suspended)),
              ]),
            ),
            const SizedBox(height: 14),
            if (visible.isEmpty)
              const EmptyView(message: 'No customers match your filters')
            else
              for (final u in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CustomerCard(user: u, repository: widget.repository),
                ),
            if (visible.isNotEmpty) ...[
              PaginationBar(
                  page: page,
                  totalPages: totalPages,
                  onPage: (p) => setState(() => _page = p)),
              Center(
                child: Text(
                  'Showing ${start + 1}-${start + visible.length} of ${formatCount(filtered.length)} customers',
                  style: ts(12, color: AdminColors.grey),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.user, required this.repository});
  final AppUser user;
  final AdminRepository repository;

  void _open(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => UserDetailScreen(userId: user.id, repository: repository),
    ));
  }

  Widget _mini(String label, String value, {Color? valueColor, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ts(10.5, color: AdminColors.grey)),
        const SizedBox(height: 2),
        Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AdminColors.grey),
            const SizedBox(width: 2),
          ],
          Flexible(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(12, w: FontWeight.w600, color: valueColor ?? AdminColors.dark)),
          ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = user.isActive;
    return AdminCard(
      borderColor: active ? null : AdminColors.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminAvatar(
                name: user.name,
                photoUrl: user.photoUrl,
                badgeColor: active ? AdminColors.primary : AdminColors.red,
                badgeIcon: active ? Icons.check : Icons.close,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(16, w: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(12, color: AdminColors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusPill(active ? 'Active' : 'Suspended',
                      tone: active ? Tone.blue : Tone.red),
                  const SizedBox(height: 4),
                  Text(user.code, style: ts(10.5, color: AdminColors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (active)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AdminColors.field,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(flex: 4, child: _mini('Phone', user.phone)),
                Expanded(
                    flex: 4,
                    child: _mini('Location', user.location,
                        icon: Icons.place_outlined)),
                Expanded(
                    flex: 3,
                    child: _mini('Bookings', '${user.totalBookings} Total',
                        valueColor: AdminColors.primary)),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AdminColors.redBg,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REASON FOR ACTION',
                      style: ts(10, w: FontWeight.w700, color: const Color(0xFFB91C1C))),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: AdminColors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(user.suspendReason ?? 'No reason recorded',
                            style: ts(12.5, color: const Color(0xFF7F1D1D))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: AdminButton('View', onPressed: () => _open(context))),
            const SizedBox(width: 8),
            if (active) ...[
              Expanded(
                  child: AdminButton('Edit',
                      onPressed: () => editCustomer(context, repository, user))),
              const SizedBox(width: 8),
              Expanded(
                  child: AdminButton('Deactivate',
                      kind: ButtonKind.danger,
                      onPressed: () =>
                          toggleCustomerStatus(context, repository, user))),
            ] else
              Expanded(
                  flex: 2,
                  child: AdminButton('Reactivate',
                      kind: ButtonKind.filled,
                      icon: Icons.power_settings_new_rounded,
                      onPressed: () =>
                          toggleCustomerStatus(context, repository, user))),
          ]),
        ],
      ),
    );
  }
}
