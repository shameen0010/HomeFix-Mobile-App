import 'package:flutter/material.dart';

class StatusBadgeChip extends StatelessWidget {
  final String status;
  const StatusBadgeChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color =
        normalized.contains('approv') ||
            normalized == 'active' ||
            normalized == 'completed'
        ? Colors.green.shade700
        : normalized.contains('reject') || normalized.contains('cancel')
        ? Colors.red.shade700
        : Colors.orange.shade700;
    return Chip(
      label: Text(status, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withValues(alpha: .12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
