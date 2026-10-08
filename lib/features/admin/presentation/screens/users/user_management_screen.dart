import 'package:flutter/material.dart';

import '../../../core/admin_theme.dart';
import '../../../core/admin_widgets.dart';
import '../../../data/repositories/admin_repository.dart';
import 'customers_tab.dart';
import 'providers_tab.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  int _tab = 0;

  Widget _segment(String label, IconData icon, int index) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AdminColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : AdminColors.grey),
              const SizedBox(width: 6),
              Text(label,
                  style: ts(13,
                      w: FontWeight.w600,
                      color: selected ? Colors.white : AdminColors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(
        children: [
          const AdminHeader(subtitle: 'User Management'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AdminColors.chipBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                _segment('Customers', Icons.person_outline_rounded, 0),
                _segment('Providers', Icons.engineering_outlined, 1),
              ]),
            ),
          ),
          Expanded(
            child: _tab == 0
                ? CustomersTab(repository: widget.repository)
                : ProvidersTab(repository: widget.repository),
          ),
        ],
      ),
    );
  }
}
