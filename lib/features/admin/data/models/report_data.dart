import 'booking_model.dart';

/// Immutable snapshot of a generated report (filters already applied).
class ReportData {
  ReportData({
    required this.title,
    required this.generatedAt,
    required this.rangeLabel,
    required this.bookings,
    required this.completed,
    required this.cancelled,
    required this.emergency,
    required this.providersInvolved,
    required this.financialVolume,
    required this.satisfactionPct,
    required this.summary,
  });

  final String title, rangeLabel, summary;
  final DateTime generatedAt;
  final List<BookingModel> bookings;
  final int completed, cancelled, emergency, providersInvolved;
  final double financialVolume, satisfactionPct;

  factory ReportData.build(
    List<BookingModel> source, {
    String category = 'all',
    String status = 'all',
    String providerId = 'all',
  }) {
    final rows = source.where((b) {
      if (category != 'all' && b.category != category) return false;
      if (status != 'all' && b.status != status) return false;
      if (providerId != 'all' && b.providerId != providerId) return false;
      return true;
    }).toList();

    final completed = rows.where((b) => b.status == 'completed').toList();
    final cancelled = rows.where((b) => b.status == 'cancelled').length;
    final emergency = rows.where((b) => b.isEmergency).length;
    final providers = rows
        .where((b) => b.hasProvider)
        .map((b) => b.providerId)
        .toSet()
        .length;
    final volume = completed.fold<double>(0, (s, b) => s + b.amount);
    final rated = completed.where((b) => b.rating != null).toList();
    final avg = rated.isEmpty
        ? 0.0
        : rated.fold<double>(0, (s, b) => s + b.rating!) / rated.length;
    final rate = rows.isEmpty ? 0 : (completed.length * 100 / rows.length).round();

    final dates = rows.map((b) => b.date).whereType<DateTime>().toList()..sort();
    String fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final range = dates.isEmpty ? 'No records' : '${fmt(dates.first)} to ${fmt(dates.last)}';

    return ReportData(
      title: 'Platform Performance Report',
      generatedAt: DateTime.now(),
      rangeLabel: range,
      bookings: rows,
      completed: completed.length,
      cancelled: cancelled,
      emergency: emergency,
      providersInvolved: providers,
      financialVolume: volume,
      satisfactionPct: avg / 5 * 100,
      summary:
          'Completion rate is $rate% across ${rows.length} bookings, with $emergency emergency requests and $cancelled cancellations in this period.',
    );
  }
}
