import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_draft.dart';
import '../../data/models/booking_info.dart';
import '../../data/repositories/customer_repository.dart';
import 'availability.dart';

/// Status chip text + colour used by the bookings list and tracking screens.
(String, Tone) bookingChip(BookingInfo b) {
  switch (b.status) {
    case 'pending':
      return (b.hasProvider ? 'Pending' : 'Finding provider', Tone.orange);
    case 'confirmed':
      return ('Confirmed', Tone.blue);
    case 'in_progress':
      return (b.stage == 'done' ? 'Finished' : 'In Progress', Tone.orange);
    case 'completed':
      return ('Completed', Tone.green);
    case 'cancelled':
      return ('Cancelled', Tone.red);
    default:
      return (b.status, Tone.grey);
  }
}

InputDecoration fieldDeco(String hint, {IconData? icon}) => InputDecoration(
      hintText: hint,
      hintStyle: ts(12.5, color: AdminColors.grey),
      prefixIcon: icon == null ? null : Icon(icon, size: 18, color: AdminColors.grey),
      filled: true,
      fillColor: AdminColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.primary)),
    );

/// "Label *            hint" row above a form field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key, this.required = false, this.hint});
  final String label;
  final bool required;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Row(children: [
          Text(label, style: ts(12.5, w: FontWeight.w600)),
          if (required) Text(' *', style: ts(12.5, w: FontWeight.w700, color: AdminColors.red)),
          const Spacer(),
          if (hint != null) Text(hint!, style: ts(10.5, w: FontWeight.w600, color: AdminColors.grey)),
        ]),
      );
}

/// Step indicator of the checkout (Service > Schedule > Location > Summary).
class BookingStepper extends StatelessWidget {
  const BookingStepper({super.key, required this.step});
  final int step; // 0..3 = active step

  static const _labels = ['Service', 'Schedule', 'Location', 'Summary'];
  static const _icons = [
    Icons.check_rounded, Icons.schedule_rounded, Icons.place_outlined, Icons.receipt_long_outlined
  ];

  @override
  Widget build(BuildContext context) {
    Widget dot(int i) {
      final done = i < step, active = i == step;
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done || active ? AdminColors.primary : AdminColors.chipBg,
        ),
        child: Icon(done ? Icons.check_rounded : _icons[i],
            size: 16, color: done || active ? Colors.white : AdminColors.grey),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(children: [
        Row(children: [
          for (var i = 0; i < 4; i++) ...[
            dot(i),
            if (i < 3)
              Expanded(child: Container(height: 2, color: i < step ? AdminColors.primary : AdminColors.chipBg)),
          ],
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var i = 0; i < 4; i++)
            Text(_labels[i],
                style: ts(10, w: i == step ? FontWeight.w700 : FontWeight.w500,
                    color: i <= step ? AdminColors.primary : AdminColors.grey)),
        ]),
      ]),
    );
  }
}

/// Arrival windows of a day: the four Figma anchors that fit the provider's hours,
/// or evenly spaced windows when none of them fit.
List<DateTime> windowsFor(ProviderProfile p, DateTime day) {
  final now = DateTime.now();
  final today = day.year == now.year && day.month == now.month && day.day == now.day;
  if (today && !p.acceptsSameDay) return const [];
  bool ok(DateTime t) => validateSlot(p, t) == null;
  final anchors = <DateTime>[
    for (final m in const [540, 690, 840, 990]) DateTime(day.year, day.month, day.day, m ~/ 60, m % 60)
  ].where(ok).toList();
  if (anchors.isNotEmpty) return anchors;
  final d = p.schedule[ProviderConfig.days[day.weekday - 1]];
  if (d == null || !d.enabled) return const [];
  int mins(String s) {
    final x = s.split(':');
    return (int.tryParse(x[0]) ?? 0) * 60 + (int.tryParse(x.length > 1 ? x[1] : '0') ?? 0);
  }
  final out = <DateTime>[];
  for (var m = mins(d.start); m + 30 <= mins(d.end); m += 150) {
    final t = DateTime(day.year, day.month, day.day, m ~/ 60, m % 60);
    if (ok(t)) out.add(t);
  }
  return out;
}

String windowLabel(DateTime start) =>
    '${formatDate(start, 'h:mm a')} - ${formatDate(start.add(const Duration(minutes: 30)), 'h:mm a')}';

/// Date strip + arrival windows driven by the provider's schedule and live slot locks.
class SlotPicker extends StatefulWidget {
  const SlotPicker({super.key, required this.provider, required this.onChanged, this.initial});
  final ProviderProfile provider;
  final DateTime? initial;
  final ValueChanged<DateTime?> onChanged;

  @override
  State<SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<SlotPicker> {
  final _repo = CustomerRepository.instance;
  late final List<DateTime> _days;
  late DateTime _day;
  DateTime? _slot;
  late Stream<DayLoad> _load;

  @override
  void initState() {
    super.initState();
    final t = DateTime.now();
    _days = [for (var i = 0; i < 14; i++) DateTime(t.year, t.month, t.day + i)];
    final init = widget.initial;
    DateTime? first;
    for (final d in _days) {
      if (windowsFor(widget.provider, d).isNotEmpty) {
        first = d;
        break;
      }
    }
    _day = init != null ? DateTime(init.year, init.month, init.day) : (first ?? _days.first);
    _slot = init;
    _load = _repo.watchDayLoad(widget.provider.id, _day);
  }

  void _pickDay(DateTime d) {
    setState(() {
      _day = d;
      _slot = null;
      _load = _repo.watchDayLoad(widget.provider.id, d);
    });
    widget.onChanged(null);
  }

  IconData _icon(DateTime t) => t.hour < 11
      ? Icons.wb_twilight_rounded
      : t.hour < 15
          ? Icons.wb_sunny_outlined
          : t.hour < 18
              ? Icons.wb_cloudy_outlined
              : Icons.nights_stay_outlined;

  @override
  Widget build(BuildContext context) {
    final windows = windowsFor(widget.provider, _day);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(formatDate(_day, 'MMMM yyyy'), style: ts(11.5, color: AdminColors.grey)),
      const SizedBox(height: 8),
      SizedBox(
        height: 74,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final d = _days[i];
            final enabled = windowsFor(widget.provider, d).isNotEmpty;
            final sel = d == _day;
            return GestureDetector(
              onTap: enabled ? () => _pickDay(d) : null,
              child: Container(
                width: 64,
                decoration: BoxDecoration(
                  color: sel ? AdminColors.primary : AdminColors.field,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Opacity(
                  opacity: enabled ? 1 : 0.4,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(formatDate(d, 'EEE').toUpperCase(),
                        style: ts(10, w: FontWeight.w600, color: sel ? Colors.white70 : AdminColors.grey)),
                    Text('${d.day}',
                        style: ts(20, w: FontWeight.w700, color: sel ? Colors.white : AdminColors.dark)),
                    Icon(Icons.circle, size: 5, color: sel ? AdminColors.orange : Colors.transparent),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 14),
      Text('Available Arrival Windows', style: ts(12.5, w: FontWeight.w700)),
      const SizedBox(height: 8),
      StreamBuilder<DayLoad>(
        stream: _load,
        builder: (context, snap) {
          if (snap.hasError) return Text('Could not check availability.', style: ts(12, color: AdminColors.red));
          if (windows.isEmpty) {
            return Text('No arrival windows on this day. Pick another date.',
                style: ts(12, color: AdminColors.grey));
          }
          final taken = snap.data?.taken ?? const <String>{};
          final max = widget.provider.schedule[ProviderConfig.days[_day.weekday - 1]]?.maxJobs ?? 4;
          final full = taken.length >= max;
          return LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - 8) / 2;
            return Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in windows)
                Builder(builder: (_) {
                  final isTaken = full || taken.contains(slotKeyOf(t));
                  final sel = _slot == t && !isTaken;
                  return GestureDetector(
                    onTap: isTaken
                        ? null
                        : () {
                            setState(() => _slot = t);
                            widget.onChanged(t);
                          },
                    child: Container(
                      width: w,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                          color: sel ? AdminColors.primary : AdminColors.field,
                          borderRadius: BorderRadius.circular(12)),
                      child: Opacity(
                        opacity: isTaken ? 0.4 : 1,
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(_icon(t), size: 16, color: sel ? Colors.white : AdminColors.primary),
                          const SizedBox(width: 6),
                          Text(isTaken ? 'Booked' : formatDate(t, 'hh:mm a'),
                              style: ts(12.5, w: FontWeight.w700, color: sel ? Colors.white : AdminColors.dark)),
                        ]),
                      ),
                    ),
                  );
                }),
            ]);
          });
        },
      ),
    ]);
  }
}

/// Photo attachments (max 4) used by checkout and the emergency form.
class PhotoStrip extends StatefulWidget {
  const PhotoStrip({super.key, required this.photos, this.onChanged, this.max = 4});
  final List<Uint8List> photos;
  final VoidCallback? onChanged;
  final int max;

  @override
  State<PhotoStrip> createState() => _PhotoStripState();
}

class _PhotoStripState extends State<PhotoStrip> {
  Future<void> _add() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1600);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        if (mounted) showAdminSnack(context, 'Photo is larger than 10MB.', error: true);
        return;
      }
      setState(() => widget.photos.add(bytes));
      widget.onChanged?.call();
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Could not access your photos.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: widget.photos.length >= widget.max ? null : _add,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(color: AdminColors.field, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            const CircleAvatar(
                radius: 20, backgroundColor: AdminColors.chipBg,
                child: Icon(Icons.add_a_photo_outlined, color: AdminColors.primary, size: 20)),
            const SizedBox(height: 8),
            Text(widget.photos.length >= widget.max ? 'Maximum photos added' : 'Tap to upload a photo',
                style: ts(12, w: FontWeight.w600, color: AdminColors.primary)),
            Text('JPEG or PNG up to 10MB', style: ts(10.5, color: AdminColors.grey)),
          ]),
        ),
      ),
      if (widget.photos.isNotEmpty) ...[
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(widget.photos[i], width: 110, height: 84, fit: BoxFit.cover),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() => widget.photos.removeAt(i));
                    widget.onChanged?.call();
                  },
                  child: const CircleAvatar(
                      radius: 11, backgroundColor: Colors.black54,
                      child: Icon(Icons.close_rounded, size: 14, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ],
    ]);
  }
}

/// Soft coloured banner (info / warning).
class NoticeBox extends StatelessWidget {
  const NoticeBox({super.key, required this.icon, required this.text, this.title, this.bg = AdminColors.chipBg,
      this.fg = AdminColors.primary});
  final IconData icon;
  final String text;
  final String? title;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (title != null) Text(title!, style: ts(12.5, w: FontWeight.w700, color: fg)),
              Text(text, style: ts(11.5, height: 1.4, color: fg)),
            ]),
          ),
        ]),
      );
}

/// Sticky bottom bar with a primary button (+ optional extra children below it).
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.of(context).viewPadding.bottom),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -2)),
        ]),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      );
}

/// "STEP n OF 4" bar of the emergency flow.
class EmergencyProgress extends StatelessWidget {
  const EmergencyProgress({super.key, required this.step});
  final int step; // 1..4

  static const _names = ['Service Type', 'Location & Issue', 'Dispatch Tier', 'Final Review'];

  @override
  Widget build(BuildContext context) => AdminCard(
        child: Column(children: [
          Row(children: [
            Text('STEP $step OF 4', style: ts(10, w: FontWeight.w700, color: AdminColors.primary)),
            const Spacer(),
            Text(step == 1 ? '25% complete' : _names[step - 1],
                style: ts(10, w: FontWeight.w700, color: AdminColors.grey)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            for (var i = 1; i <= 4; i++)
              Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i <= step ? AdminColors.primary : AdminColors.chipBg,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ]),
        ]),
      );
}
