// Re-exports the shared HomeFix UI kit (theme, widgets, feedback helpers) so
// provider screens need a single import. Move `admin/core` to `lib/core`
// later if you want a neutral location; only these exports must change.
export '../../admin/core/admin_exception.dart';
export '../../admin/core/admin_feedback.dart';
export '../../admin/core/admin_format.dart';
export '../../admin/core/admin_theme.dart';
export '../../admin/core/admin_widgets.dart';

class ProviderConfig {
  ProviderConfig._();
  /// Set your real support hotline here.
  static const hotline = '+94112345678';
  static const appVersion = '2.4.1 (Build 412)';
  static const days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];
}

/// '08:00' -> '08:00 AM'
String fmtHm(String hhmm) {
  final p = hhmm.split(':');
  final h = int.tryParse(p.first) ?? 0;
  final m = p.length > 1 ? p[1] : '00';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '${h12.toString().padLeft(2, '0')}:$m ${h < 12 ? 'AM' : 'PM'}';
}

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
