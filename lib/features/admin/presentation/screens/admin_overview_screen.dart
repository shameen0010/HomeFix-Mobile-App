import 'package:flutter/material.dart';

import '../../core/admin_format.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_widgets.dart';
import '../../data/repositories/admin_repository.dart';

/// Lightweight dashboard tab (FR-A09). Pass your own widget to AdminShell
/// via `dashboard:` to replace it with the Figma dashboard.
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen(
      {super.key, required this.repository, required this.onNavigate});
  final AdminRepository repository;
  final ValueChanged<int> onNavigate;

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  late Future<AdminCounts> _future = widget.repository.fetchCounts();

  void _reload() => setState(() => _future = widget.repository.fetchCounts());

  Widget _shortcut(IconData icon, String title, String sub, int tab) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => widget.onNavigate(tab),
          child: AdminCard(
            child: Row(children: [
              Icon(icon, color: AdminColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ts(13.5, w: FontWeight.w700)),
                    Text(sub, style: ts(11.5, color: AdminColors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AdminColors.grey),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(
        children: [
          const AdminHeader(subtitle: 'Dashboard'),
          Expanded(
            child: FutureBuilder<AdminCounts>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                if (snap.hasError || snap.data == null) {
                  return ErrorView(
                      message: 'Could not load dashboard figures.', onRetry: _reload);
                }
                final c = snap.data!;
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      Row(children: [
                        Expanded(
                            child: StatCard(
                                label: 'Customers',
                                value: formatCount(c.customers),
                                icon: Icons.people_outline_rounded,
                                caption: '+${formatCount(c.newCustomers)} this month')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                label: 'Service Pros',
                                value: formatCount(c.providers),
                                icon: Icons.engineering_outlined,
                                caption: '${formatCount(c.approvedProviders)} verified')),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: StatCard(
                                label: 'Pending Verification',
                                value: formatCount(c.pendingProviders),
                                icon: Icons.pending_actions_rounded,
                                caption: 'Needs review',
                                captionTone: Tone.orange,
                                onTap: () => widget.onNavigate(1))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                label: 'Open Disputes',
                                value: formatCount(c.openDisputes),
                                icon: Icons.gavel_rounded,
                                caption: 'Awaiting action',
                                captionTone: Tone.red,
                                onTap: () => widget.onNavigate(3))),
                      ]),
                      const SizedBox(height: 16),
                      Text('Quick access', style: ts(15, w: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _shortcut(Icons.verified_user_outlined, 'Review providers',
                          'Verify, reject or suspend providers', 1),
                      _shortcut(Icons.calendar_month_outlined, 'Monitor bookings',
                          'Track live and emergency bookings', 2),
                      _shortcut(Icons.category_outlined, 'Manage categories',
                          'Service verticals and disputes', 3),
                      _shortcut(Icons.bar_chart_rounded, 'Reports & analytics',
                          'Generate and export PDF / Excel', 4),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
