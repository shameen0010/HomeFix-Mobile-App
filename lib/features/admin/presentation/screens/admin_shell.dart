import 'package:flutter/material.dart';

import '../../core/admin_theme.dart';
import '../../data/repositories/admin_repository.dart';
import 'admin_overview_screen.dart';
import 'bookings_screen.dart';
import 'operations_screen.dart';
import 'reports_screen.dart';
import 'users/user_management_screen.dart';

/// Entry point of the admin module: Material 3 bottom navigation with
/// Dashboard / Users / Bookings / Operations / Reports tabs.
///
/// Usage: `Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminShell()));`
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, this.dashboard});

  /// Optional custom dashboard tab (e.g. your existing AdminDashboardScreen body).
  final Widget? dashboard;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final AdminRepository _repo = AdminRepository();
  int _index = 0;
  final Set<int> _visited = {0};

  void _go(int i) => setState(() {
        _index = i;
        _visited.add(i);
      });

  Widget _page(int i) {
    switch (i) {
      case 0:
        return widget.dashboard ??
            AdminOverviewScreen(repository: _repo, onNavigate: _go);
      case 1:
        return UserManagementScreen(repository: _repo);
      case 2:
        return BookingsScreen(repository: _repo);
      case 3:
        return OperationsScreen(repository: _repo);
      default:
        return ReportsScreen(repository: _repo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: adminTheme,
      child: Scaffold(
        backgroundColor: AdminColors.bg,
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < 5; i++)
              _visited.contains(i) ? _page(i) : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard'),
            NavigationDestination(
                icon: Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(Icons.people_alt_rounded),
                label: 'Users'),
            NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Bookings'),
            NavigationDestination(
                icon: Icon(Icons.engineering_outlined),
                selectedIcon: Icon(Icons.engineering_rounded),
                label: 'Operations'),
            NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: 'Reports'),
          ],
        ),
      ),
    );
  }
}
