import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/booking_card.dart';
import '../widgets/job_format.dart';
import '../widgets/provider_header.dart';

enum _Day { today, tomorrow, week, date }

/// Upcoming Bookings: schedule list + month calendar view.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final Stream<List<JobModel>> _stream = ProviderRepository.instance.watchJobs();
  bool _calendar = false;
  _Day _day = _Day.today;
  DateTime _picked = DateTime.now();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _category = 'all';

  static DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);
  bool _same(DateTime? a, DateTime b) => a != null && _d(a) == _d(b);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final r = await showDatePicker(
        context: context, initialDate: _picked, firstDate: _d(now), lastDate: now.add(const Duration(days: 365)));
    if (r != null) setState(() {
      _picked = r;
      _day = _Day.date;
    });
  }

  Future<void> _filter(List<String> categories) async {
    final v = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => Theme(
        data: adminTheme,
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.all(16), child: Text('Filter by service', style: ts(15, w: FontWeight.w700))),
            for (final c in ['all', ...categories])
              ListTile(
                title: Text(c == 'all' ? 'All services' : c),
                trailing: c == _category ? const Icon(Icons.check, color: AdminColors.primary) : null,
                onTap: () => Navigator.pop(context, c),
              ),
          ]),
        ),
      ),
    );
    if (v != null) setState(() => _category = v);
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(subtitle: 'Upcoming Bookings'),
        Expanded(
          child: StreamBuilder<List<JobModel>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load bookings.\n${snap.error}');
              if (!snap.hasData) return const LoadingView();
              final upcoming = snap.data!.where((j) => j.isUpcoming).toList()
                ..sort((a, b) => (a.scheduledAt ?? DateTime(2100)).compareTo(b.scheduledAt ?? DateTime(2100)));
              final categories = upcoming.map((j) => j.category).toSet().toList()..sort();
              final jobs = _category == 'all' ? upcoming : upcoming.where((j) => j.category == _category).toList();
              final nextId = jobs.where((j) => j.status == 'confirmed').isEmpty
                  ? null
                  : jobs.firstWhere((j) => j.status == 'confirmed').id;
              final now = DateTime.now();
              final today = jobs.where((j) => _same(j.scheduledAt, now)).toList();
              final tomorrow = jobs.where((j) => _same(j.scheduledAt, now.add(const Duration(days: 1)))).toList();
              final week = jobs.where((j) {
                final s = j.scheduledAt;
                return s != null && !_d(s).isBefore(_d(now)) && _d(s).isBefore(_d(now).add(const Duration(days: 7)));
              }).toList();
              final confirmed = upcoming.where((j) => j.status == 'confirmed').length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text('Upcoming\nBookings', style: ts(24, w: FontWeight.w700, height: 1.15))),
                    StatusPill('$confirmed Confirmed', tone: Tone.orange, size: 10.5),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                        tooltip: 'Filter', onPressed: () => _filter(categories), icon: const Icon(Icons.tune_rounded)),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      _segment('Schedule (${jobs.length})', Icons.list_alt_rounded, !_calendar, () => setState(() => _calendar = false)),
                      _segment('Calendar View', Icons.calendar_month_outlined, _calendar, () => setState(() => _calendar = true)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  if (_calendar) ..._calendarView(jobs, nextId) else ..._scheduleView(jobs, today, tomorrow, week, nextId),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _segment(String label, IconData icon, bool on, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
                color: on ? AdminColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 16, color: on ? Colors.white : AdminColors.grey),
              const SizedBox(width: 6),
              Text(label, style: ts(12, w: FontWeight.w600, color: on ? Colors.white : AdminColors.grey)),
            ]),
          ),
        ),
      );

  List<Widget> _scheduleView(List<JobModel> jobs, List<JobModel> today, List<JobModel> tomorrow,
      List<JobModel> week, String? nextId) {
    final shown = switch (_day) {
      _Day.today => today,
      _Day.tomorrow => tomorrow,
      _Day.week => week,
      _Day.date => jobs.where((j) => _same(j.scheduledAt, _picked)).toList(),
    };
    final children = <Widget>[
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          AdminChoiceChip(label: 'Today', count: today.length, selected: _day == _Day.today, onTap: () => setState(() => _day = _Day.today)),
          AdminChoiceChip(label: 'Tomorrow', count: tomorrow.length, selected: _day == _Day.tomorrow, onTap: () => setState(() => _day = _Day.tomorrow)),
          AdminChoiceChip(label: 'This Week', count: week.length, selected: _day == _Day.week, onTap: () => setState(() => _day = _Day.week)),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
                tooltip: 'Pick a date',
                onPressed: _pickDate,
                icon: Icon(Icons.calendar_month_outlined, color: _day == _Day.date ? AdminColors.primary : null)),
          ),
        ]),
      ),
      const SizedBox(height: 14),
    ];
    if (shown.isEmpty) {
      children.add(const EmptyView(message: 'No bookings for this period', icon: Icons.event_available_outlined));
      return children;
    }
    DateTime? last;
    for (final j in shown) {
      final day = _d(j.scheduledAt ?? DateTime.now());
      if (last == null || day != last) {
        last = day;
        final count = shown.where((x) => _same(x.scheduledAt, day)).length;
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 2),
          child: Row(children: [
            const Icon(Icons.circle, size: 9, color: AdminColors.orange),
            const SizedBox(width: 6),
            Expanded(
              child: Text('${dayWord(day).toUpperCase()}  \u2022  ${formatDate(day, 'EEEE, MMM d').toUpperCase()}',
                  style: ts(11, w: FontWeight.w700, color: AdminColors.grey)),
            ),
            StatusPill('$count Job${count == 1 ? '' : 's'}', tone: Tone.orange, size: 10),
          ]),
        ));
      }
      children.add(Padding(padding: const EdgeInsets.only(bottom: 12), child: BookingCard(job: j, nextUp: j.id == nextId)));
    }
    return children;
  }

  List<Widget> _calendarView(List<JobModel> jobs, String? nextId) {
    final first = DateTime(_month.year, _month.month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = first.weekday - 1; // Monday first
    final cells = <Widget>[
      for (final w in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
        Center(child: Text(w, style: ts(11, w: FontWeight.w700, color: AdminColors.grey))),
      for (var i = 0; i < offset; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        Builder(builder: (_) {
          final date = DateTime(_month.year, _month.month, day);
          final count = jobs.where((j) => _same(j.scheduledAt, date)).length;
          final selected = _same(_picked, date);
          return GestureDetector(
            onTap: () => setState(() => _picked = date),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: selected ? AdminColors.primary : (count > 0 ? AdminColors.chipBg : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$day', style: ts(12.5, w: FontWeight.w600, color: selected ? Colors.white : AdminColors.dark)),
                if (count > 0)
                  Text('$count', style: ts(9, w: FontWeight.w700, color: selected ? Colors.white : AdminColors.primary)),
              ]),
            ),
          );
        }),
    ];
    final dayJobs = jobs.where((j) => _same(j.scheduledAt, _picked)).toList();
    return [
      AdminCard(
        child: Column(children: [
          Row(children: [
            IconButton(
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded)),
            Expanded(child: Center(child: Text(formatDate(_month, 'MMMM yyyy'), style: ts(15, w: FontWeight.w700)))),
            IconButton(
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded)),
          ]),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: cells,
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Text('${dayWord(_picked)}, ${formatDate(_picked, 'MMM d')}', style: ts(14, w: FontWeight.w700)),
      const SizedBox(height: 8),
      if (dayJobs.isEmpty)
        const EmptyView(message: 'No bookings on this day', icon: Icons.event_available_outlined)
      else
        for (final j in dayJobs)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: BookingCard(job: j, nextUp: j.id == nextId)),
    ];
  }
}
