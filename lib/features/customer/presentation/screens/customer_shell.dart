import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import 'customer_bookings_screen.dart';
import 'customer_home_screen.dart';
import 'customer_messages_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_search_screen.dart';

/// Entry point of the customer module (Home / Search / Bookings / Messages / Profile).
/// Usage: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerShell()));
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  final Set<int> _visited = {0};

  @override
  void initState() {
    super.initState();
    CustomerNav.tab.value = 0;
    CustomerNav.tab.addListener(_onTab);
  }

  @override
  void dispose() {
    CustomerNav.tab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() => setState(() => _visited.add(CustomerNav.tab.value));

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const CustomerHomeScreen();
      case 1:
        return const CustomerSearchScreen();
      case 2:
        return const CustomerBookingsScreen();
      case 3:
        return const CustomerMessagesScreen();
      default:
        return const CustomerProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = CustomerNav.tab.value;
    return Theme(
      data: adminTheme,
      child: Scaffold(
        backgroundColor: AdminColors.bg,
        body: IndexedStack(
          index: index,
          children: [for (var i = 0; i < 5; i++) _visited.contains(i) ? _page(i) : const SizedBox.shrink()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => CustomerNav.tab.value = i,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Search'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Bookings'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Messages'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
