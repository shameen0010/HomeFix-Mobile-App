import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/provider_repository.dart';
import 'messages_screen.dart';
import 'more_screen.dart';
import 'provider_dashboard_screen.dart';
import 'requests_screen.dart';
import 'schedule_screen.dart';

/// Entry point of the provider module (bottom navigation).
/// Registration flow: `TradeCredentialsScreen` -> `RegistrationCompleteScreen` -> `ProviderShell`.
class ProviderShell extends StatefulWidget {
  const ProviderShell({super.key});

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell> {
  int _index = 0;
  final Set<int> _visited = {0};
  late final Stream<List<JobModel>> _jobs = ProviderRepository.instance.watchJobs();

  void _go(int i) => setState(() {
        _index = i;
        _visited.add(i);
      });

  Widget _page(int i) {
    switch (i) {
      case 0:
        return ProviderDashboardScreen(onNavigate: _go);
      case 1:
        return const RequestsScreen();
      case 2:
        return const ScheduleScreen();
      case 3:
        return const MessagesScreen();
      default:
        return const MoreScreen();
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
            for (var i = 0; i < 5; i++) _visited.contains(i) ? _page(i) : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: StreamBuilder<List<JobModel>>(
          stream: _jobs,
          builder: (context, snap) {
            final pending = snap.data?.where((j) => j.status == 'pending').length ?? 0;
            return NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _go,
              destinations: [
                const NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Dashboard'),
                NavigationDestination(
                    icon: Badge(
                        isLabelVisible: pending > 0,
                        label: Text('$pending'),
                        child: const Icon(Icons.inbox_outlined)),
                    selectedIcon: const Icon(Icons.inbox_rounded),
                    label: 'Requests'),
                const NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: 'Schedule'),
                const NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded),
                    label: 'Messages'),
                const NavigationDestination(
                    icon: Icon(Icons.more_horiz_rounded), label: 'More'),
              ],
            );
          },
        ),
      ),
    );
  }
}
