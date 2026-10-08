import 'package:intl/intl.dart';

import 'admin_theme.dart';

String formatMoney(num v) =>
    '${AdminConfig.currency}${NumberFormat('#,##0.00').format(v)}';

String formatCount(int v) => NumberFormat.decimalPattern().format(v);

String formatDate(DateTime? d, [String pattern = 'MMM d, yyyy']) =>
    d == null ? '-' : DateFormat(pattern).format(d);

String initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String timeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.isNegative) return formatDate(d, 'MMM d, h:mm a');
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return formatDate(d);
}

String startsIn(DateTime? d) {
  if (d == null) return '';
  final diff = d.difference(DateTime.now());
  if (diff.isNegative) return 'Scheduled ${formatDate(d, 'MMM d, h:mm a')}';
  if (diff.inMinutes < 60) return 'Starts in ${diff.inMinutes}m';
  if (diff.inHours < 24) {
    return 'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
  }
  return 'Starts ${formatDate(d, 'MMM d, h:mm a')}';
}
