import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/admin_feedback.dart';
import '../../core/admin_format.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_widgets.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/report_data.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/services/report_exporter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final Stream<List<BookingModel>> _stream =
      widget.repository.watchBookings(limit: 1000);
  late Future<AdminCounts> _counts = widget.repository.fetchCounts();

  String _category = 'all';
  String _status = 'all';
  String _provider = 'all';
  ReportData? _report;

  static const _statusItems = {
    'all': 'All Statuses',
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'in_progress': 'In Progress',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  void _generate(List<BookingModel> bookings) {
    setState(() => _report = ReportData.build(bookings,
        category: _category, status: _status, providerId: _provider));
    showAdminSnack(context, 'Report generated');
  }

  void _reset() => setState(() {
        _category = 'all';
        _status = 'all';
        _provider = 'all';
        _report = null;
      });

  String _trend(int now, int before) {
    if (before == 0) return now == 0 ? 'No change' : 'New activity';
    final pct = ((now - before) * 100 / before).round();
    return '${pct >= 0 ? '+' : ''}$pct% this month';
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(
        children: [
          const AdminHeader(subtitle: 'Finance'),
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorView(message: 'Could not load report data.\n${snap.error}');
                }
                if (!snap.hasData) return const LoadingView();
                return _content(snap.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(List<BookingModel> bookings) {
    final now = DateTime.now();
    final thisMonth = bookings
        .where((b) => b.date != null && b.date!.year == now.year && b.date!.month == now.month)
        .length;
    final prev = DateTime(now.year, now.month - 1);
    final lastMonth = bookings
        .where((b) => b.date != null && b.date!.year == prev.year && b.date!.month == prev.month)
        .length;

    final total = bookings.length;
    final completed = bookings.where((b) => b.status == 'completed').length;
    final cancelled = bookings.where((b) => b.status == 'cancelled').length;
    final emergency = bookings.where((b) => b.isEmergency).length;
    final completedRate = total == 0 ? 0 : (completed * 100 / total).round();
    final cancelRate = total == 0 ? 0.0 : cancelled * 100 / total;

    final categories = <String, String>{
      'all': 'All Categories',
      for (final c in (bookings.map((b) => b.category).toSet().toList()..sort())) c: c,
    };
    final providers = <String, String>{'all': 'All Service Providers'};
    for (final b in bookings) {
      if (b.hasProvider) providers[b.providerId!] = b.providerName ?? b.providerId!;
    }

    return RefreshIndicator(
      onRefresh: () async {
        final f = widget.repository.fetchCounts();
        setState(() => _counts = f);
        await f.catchError((_) => const AdminCounts(
            customers: 0, newCustomers: 0, providers: 0,
            approvedProviders: 0, pendingProviders: 0, openDisputes: 0));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          FutureBuilder<AdminCounts>(
            future: _counts,
            builder: (context, snap) {
              final c = snap.data;
              final loading = snap.connectionState == ConnectionState.waiting;
              String v(int? n) => n == null ? (loading ? '...' : '-') : formatCount(n);
              final activePct = (c == null || c.providers == 0)
                  ? null
                  : (c.approvedProviders * 100 / c.providers).round();
              return Column(children: [
                Row(children: [
                  Expanded(
                    child: StatCard(
                        label: 'Total Bookings',
                        value: formatCount(total),
                        icon: Icons.calendar_month_outlined,
                        caption: _trend(thisMonth, lastMonth)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                        label: 'Completed',
                        value: formatCount(completed),
                        icon: Icons.check_circle_outline_rounded,
                        caption: '$completedRate% rate'),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: StatCard(
                        label: 'Cancelled',
                        value: formatCount(cancelled),
                        icon: Icons.cancel_outlined,
                        caption: '${cancelRate.toStringAsFixed(1)}% drop rate',
                        captionTone: Tone.red),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                        label: 'Emergency',
                        value: formatCount(emergency),
                        icon: Icons.bolt_rounded,
                        caption: total == 0
                            ? 'No bookings'
                            : '${(emergency * 100 / total).round()}% of total',
                        captionTone: Tone.orange),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: StatCard(
                        label: 'Customers',
                        value: v(c?.customers),
                        icon: Icons.people_outline_rounded,
                        caption: c == null ? null : '+${formatCount(c.newCustomers)} new'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                        label: 'Service Pros',
                        value: v(c?.providers),
                        icon: Icons.engineering_outlined,
                        caption: activePct == null ? null : '$activePct% active'),
                  ),
                ]),
              ]);
            },
          ),
          const SizedBox(height: 14),
          _WeeklyChart(bookings: bookings),
          const SizedBox(height: 14),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('Generate Reports',
                    icon: Icons.tune_rounded,
                    trailing: TextButton(onPressed: _reset, child: const Text('Reset All'))),
                const SizedBox(height: 8),
                AdminDropdown<String>(
                    label: 'Category',
                    value: _category,
                    items: categories,
                    onChanged: (v) => setState(() => _category = v)),
                const SizedBox(height: 10),
                AdminDropdown<String>(
                    label: 'Status',
                    value: _status,
                    items: _statusItems,
                    onChanged: (v) => setState(() => _status = v)),
                const SizedBox(height: 10),
                AdminDropdown<String>(
                    label: 'Provider Scope',
                    value: _provider,
                    items: providers,
                    onChanged: (v) => setState(() => _provider = v)),
                const SizedBox(height: 14),
                AdminButton('Generate Report',
                    kind: ButtonKind.filled,
                    icon: Icons.analytics_outlined,
                    height: 48,
                    onPressed: () => _generate(bookings)),
              ],
            ),
          ),
          if (_report != null) ...[
            const SizedBox(height: 14),
            _ReportCard(report: _report!),
          ],
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.bookings});
  final List<BookingModel> bookings;

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final counts = List<int>.filled(7, 0);
    for (final b in bookings) {
      final d = b.date;
      if (d == null) continue;
      final idx = DateTime(d.year, d.month, d.day).difference(monday).inDays;
      if (idx >= 0 && idx < 7) counts[idx]++;
    }
    final maxV = counts.reduce(math.max);
    final peakIdx = maxV == 0 ? -1 : counts.indexOf(maxV);
    final total = counts.fold<int>(0, (a, b) => a + b);

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Booking Volume', style: ts(14.5, w: FontWeight.w700)),
                  Text('Daily distribution (Mon - Sun)',
                      style: ts(11, color: AdminColors.grey)),
                ],
              ),
            ),
            if (peakIdx >= 0)
              StatusPill('Peak: ${days[peakIdx]} $maxV', tone: Tone.orange, size: 10),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${counts[i]}',
                            style: ts(10.5, w: i == peakIdx ? FontWeight.w700 : FontWeight.w500,
                                color: i == peakIdx ? AdminColors.primary : AdminColors.grey)),
                        const SizedBox(height: 4),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: maxV == 0 ? 4 : 6 + 76 * counts[i] / maxV,
                          decoration: BoxDecoration(
                            color: i == peakIdx ? AdminColors.primary : const Color(0xFFBFD7EE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(days[i], style: ts(10.5, color: AdminColors.grey)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: AdminColors.primary, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('Peak Day', style: ts(10.5, color: AdminColors.grey)),
            const SizedBox(width: 12),
            Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFFBFD7EE), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('Standard Volume', style: ts(10.5, color: AdminColors.grey)),
            const Spacer(),
            Text('$total Total / Wk', style: ts(10.5, w: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final ReportData report;

  Widget _figure(String label, String value, String sub) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ts(9.5, w: FontWeight.w700, color: AdminColors.grey)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: ts(18, w: FontWeight.w700)),
              ),
              Text(sub, style: ts(10.5, color: AdminColors.grey)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final r = report;
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const StatusPill('PLATFORM PERFORMANCE', size: 9.5),
            const Spacer(),
            const Icon(Icons.circle, size: 8, color: AdminColors.green),
            const SizedBox(width: 4),
            Text('Ready to Export', style: ts(10.5, color: AdminColors.grey)),
          ]),
          const SizedBox(height: 8),
          Text(r.title, style: ts(16, w: FontWeight.w700)),
          Text(r.rangeLabel, style: ts(11, color: AdminColors.grey)),
          const SizedBox(height: 12),
          Row(children: [
            _figure('INCLUDED RECORDS', '${formatCount(r.bookings.length)} Bookings',
                '${r.providersInvolved} Providers'),
            const SizedBox(width: 8),
            _figure('FINANCIAL VOLUME', formatMoney(r.financialVolume),
                '${r.satisfactionPct.toStringAsFixed(0)}% Satisfaction'),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AdminColors.orangeBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 18, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Audit Summary: ${r.summary}',
                      style: ts(11.5, color: const Color(0xFF92400E))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('AVAILABLE FILE FORMATS',
              style: ts(10, w: FontWeight.w700, color: AdminColors.grey)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: AdminButton('Export PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  height: 44,
                  onPressed: r.bookings.isEmpty
                      ? null
                      : () => runAdminAction(context, () => ReportExporter.exportPdf(r),
                          success: 'PDF report ready')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AdminButton('Export Excel',
                  icon: Icons.table_chart_outlined,
                  height: 44,
                  onPressed: r.bookings.isEmpty
                      ? null
                      : () => runAdminAction(context, () => ReportExporter.exportExcel(r),
                          success: 'Excel report ready')),
            ),
          ]),
          if (r.bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('No bookings match these filters, so there is nothing to export.',
                  style: ts(11, color: AdminColors.grey)),
            ),
        ],
      ),
    );
  }
}
