import '../../core/provider_ui.dart';

/// "Today", "Tomorrow" or "Wed".
String dayWord(DateTime? d) {
  if (d == null) return '';
  final now = DateTime.now();
  final diff = DateTime(d.year, d.month, d.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  return formatDate(d, 'EEE');
}

/// "Today, Oct 16 | 11:30 AM"
String whenLabel(DateTime? d) =>
    d == null ? 'Time not set' : '${dayWord(d)}, ${formatDate(d, 'MMM d')}  |  ${formatDate(d, 'h:mm a')}';

/// "In 45 mins" / "In 3 hrs" or null when it is further away.
String? inLabel(DateTime? d) {
  if (d == null) return null;
  final diff = d.difference(DateTime.now());
  if (diff.isNegative) return 'Now';
  if (diff.inMinutes < 60) return 'In ${diff.inMinutes} mins';
  if (diff.inHours < 24) return 'In ${diff.inHours} hrs';
  return null;
}
