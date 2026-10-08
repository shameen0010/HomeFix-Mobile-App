import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/provider_profile.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/provider_header.dart';

/// FR-P04: weekly working hours, same-day acceptance and time off.
class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() => _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  final _repo = ProviderRepository.instance;
  Map<String, DaySchedule>? _schedule;
  bool _sameDay = false;
  DateTime? _from, _to;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _repo.getProfile();
      if (!mounted) return;
      if (p == null) {
        setState(() => _error = 'Provider profile not found.');
        return;
      }
      setState(() {
        _schedule = Map.of(p.schedule);
        _sameDay = p.acceptsSameDay;
        _from = p.vacationFrom;
        _to = p.vacationTo;
        _error = null;
      });
    } on AdminException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _editDay(String day) async {
    final r = await showDialog<DaySchedule>(
        context: context, builder: (_) => _DayDialog(day: day, value: _schedule![day]!));
    if (r != null) setState(() => _schedule![day] = r);
  }

  Future<void> _pickVacation() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _from != null && _to != null ? DateTimeRange(start: _from!, end: _to!) : null,
    );
    if (r != null) setState(() {
      _from = r.start;
      _to = r.end;
    });
  }

  Future<void> _save() async {
    if (!_schedule!.values.any((d) => d.enabled)) {
      showAdminSnack(context, 'Enable at least one working day.', error: true);
      return;
    }
    final ok = await runAdminAction(
      context,
      () => _repo.saveAvailability(
          schedule: _schedule!, acceptsSameDay: _sameDay, vacationFrom: _from, vacationTo: _to),
      success: 'Availability saved',
    );
    if (ok && mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final today = ProviderConfig.days[DateTime.now().weekday - 1];
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Manage Availability', showBack: true),
        Expanded(
          child: _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _schedule == null
                  ? const LoadingView()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Text('Set your routine working days and arrival windows.',
                            style: ts(12, color: AdminColors.grey)),
                        const SizedBox(height: 12),
                        AdminCard(
                          child: Row(children: [
                            const CircleAvatar(
                                radius: 20, backgroundColor: AdminColors.orangeBg,
                                child: Icon(Icons.bolt_rounded, color: AdminColors.orange)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Flexible(child: Text('Accepting Same-Day', style: ts(14, w: FontWeight.w700))),
                                  const SizedBox(width: 6),
                                  if (_sameDay) const StatusPill('LIVE', tone: Tone.orange, size: 9),
                                ]),
                                Text('Instant booking for plumbing and electrical emergencies',
                                    style: ts(10.5, color: AdminColors.grey)),
                              ]),
                            ),
                            Switch(value: _sameDay, onChanged: (v) => setState(() => _sameDay = v)),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        Text('ROUTINE SCHEDULE',
                            style: ts(10.5, w: FontWeight.w700, color: AdminColors.grey)),
                        const SizedBox(height: 8),
                        for (final day in ProviderConfig.days) _dayRow(day, day == today),
                        const SizedBox(height: 4),
                        AdminCard(
                          color: AdminColors.field,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Icon(Icons.beach_access_outlined, color: AdminColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('Planning time off?', style: ts(13.5, w: FontWeight.w700)),
                              ),
                            ]),
                            Text('Pause incoming bookings with vacation mode to protect your response metrics.',
                                style: ts(11, color: AdminColors.grey)),
                            const SizedBox(height: 6),
                            Row(children: [
                              TextButton.icon(
                                onPressed: _pickVacation,
                                icon: const Icon(Icons.date_range_rounded, size: 18),
                                label: Text(_from == null || _to == null
                                    ? 'Set Vacation Dates'
                                    : '${formatDate(_from, 'MMM d')} - ${formatDate(_to, 'MMM d')}'),
                              ),
                              if (_from != null)
                                IconButton(
                                  tooltip: 'Clear',
                                  onPressed: () => setState(() {
                                    _from = null;
                                    _to = null;
                                  }),
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                ),
                            ]),
                          ]),
                        ),
                      ],
                    ),
        ),
        if (_schedule != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: AdminButton('Save Availability',
                kind: ButtonKind.filled, icon: Icons.save_outlined, height: 50, onPressed: _save),
          ),
      ]),
    );
  }

  Widget _dayRow(String day, bool isToday) {
    final d = _schedule![day]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: d.enabled ? () => _editDay(day) : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: isToday ? AdminColors.primary : Colors.transparent, width: 4),
              top: const BorderSide(color: AdminColors.border),
              right: const BorderSide(color: AdminColors.border),
              bottom: const BorderSide(color: AdminColors.border),
            ),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(capitalize(day), style: ts(15, w: FontWeight.w700)),
                  if (isToday) const StatusPill('Today', size: 9.5),
                  if (d.enabled) StatusPill('Max ${d.maxJobs} jobs', tone: Tone.grey, size: 9.5),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.schedule_rounded, size: 14,
                      color: d.enabled ? AdminColors.primary : AdminColors.grey),
                  const SizedBox(width: 4),
                  Text(d.enabled ? '${fmtHm(d.start)} - ${fmtHm(d.end)}' : 'Day off',
                      style: ts(11.5, w: FontWeight.w600,
                          color: d.enabled ? AdminColors.primary : AdminColors.grey)),
                ]),
              ]),
            ),
            Switch(
              value: d.enabled,
              onChanged: (v) => setState(() => _schedule![day] = d.copyWith(enabled: v)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DayDialog extends StatefulWidget {
  const _DayDialog({required this.day, required this.value});
  final String day;
  final DaySchedule value;

  @override
  State<_DayDialog> createState() => _DayDialogState();
}

class _DayDialogState extends State<_DayDialog> {
  late String _start = widget.value.start;
  late String _end = widget.value.end;
  late int _max = widget.value.maxJobs;

  TimeOfDay _parse(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool start) async {
    final r = await showTimePicker(context: context, initialTime: _parse(start ? _start : _end));
    if (r == null) return;
    setState(() => start ? _start = _fmt(r) : _end = _fmt(r));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(capitalize(widget.day), style: ts(17, w: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => _pick(true), child: Text('From ${fmtHm(_start)}'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: () => _pick(false), child: Text('To ${fmtHm(_end)}'))),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Max jobs', style: ts(13, w: FontWeight.w600)),
          Row(children: [
            IconButton(
                onPressed: _max > 1 ? () => setState(() => _max--) : null,
                icon: const Icon(Icons.remove_circle_outline)),
            Text('$_max', style: ts(15, w: FontWeight.w700)),
            IconButton(
                onPressed: _max < 12 ? () => setState(() => _max++) : null,
                icon: const Icon(Icons.add_circle_outline)),
          ]),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final s = _parse(_start), e = _parse(_end);
            if (e.hour * 60 + e.minute <= s.hour * 60 + s.minute) {
              showAdminSnack(context, 'End time must be after start time.', error: true);
              return;
            }
            Navigator.pop(context, widget.value.copyWith(start: _start, end: _end, maxJobs: _max));
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
