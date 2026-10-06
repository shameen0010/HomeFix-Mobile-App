import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/provider_verification_model.dart';
import '../widgets/admin_kpi_card.dart';
import '../widgets/provider_verification_card.dart';
import 'booking_monitoring_screen.dart';
import 'provider_verification_screen.dart';
import 'user_management_screen.dart';
import 'analytics_report_screen.dart';

const adminTeal = Color(0xFF00796B);

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int tab = 0;
  final screens = const [
    AdminDashboardScreen(),
    UserManagementScreen(),
    BookingMonitoringScreen(),
    ProviderVerificationScreen(),
    AnalyticsReportScreen(),
  ];
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: adminTeal,
        brightness: Theme.of(context).brightness,
      ),
    ),
    child: Scaffold(
      body: SafeArea(
        child: IndexedStack(index: tab, children: screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman),
            label: 'Operations',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
    ),
  );
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => _Page(
    title: 'Admin overview',
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, users) =>
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('providers')
                .snapshots(),
            builder: (context, providers) =>
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .snapshots(),
                  builder: (context, bookings) {
                    final userCount = users.data?.docs.length ?? 0;
                    final providerCount = providers.data?.docs.length ?? 0;
                    final bookingCount = bookings.data?.docs.length ?? 0;
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Good day, Admin',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.8,
                          children: [
                            AdminKpiCard(
                              label: 'Users',
                              value: '$userCount',
                              icon: Icons.people,
                            ),
                            AdminKpiCard(
                              label: 'Providers',
                              value: '$providerCount',
                              icon: Icons.handyman,
                            ),
                            AdminKpiCard(
                              label: 'Bookings',
                              value: '$bookingCount',
                              icon: Icons.calendar_month,
                            ),
                            const AdminKpiCard(
                              label: 'Open disputes',
                              value: '—',
                              icon: Icons.gavel,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Pending verification',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (providers.hasError)
                          Text('Unable to load providers: ${providers.error}'),
                        if (!providers.hasData)
                          const Center(child: CircularProgressIndicator()),
                        if (providers.hasData)
                          ...providers.data!.docs.map(
                            (doc) => ProviderVerificationCard(
                              provider: ProviderVerificationModel.fromDocument(
                                doc,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
          ),
    ),
  );
}

class _Page extends StatelessWidget {
  final String title;
  final Widget child;
  const _Page({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      Expanded(child: child),
    ],
  );
}

Widget adminPage(String title, Widget child) =>
    _Page(title: title, child: child);

void showAdminError(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Update failed: $error')));
