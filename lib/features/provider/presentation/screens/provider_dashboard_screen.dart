import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/job_model.dart';
import '../../data/models/provider_profile.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/job_actions.dart';
import '../widgets/job_card.dart';
import '../widgets/provider_header.dart';
import 'manage_availability_screen.dart';
import 'manage_services_screen.dart';
import 'provider_profile_screen.dart';
import 'reviews_screen.dart';
import 'booking_history_screen.dart';

bool _sameDay(DateTime? a, DateTime b) =>
    a != null && a.year == b.year && a.month == b.month && a.day == b.day;

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final _repo = ProviderRepository.instance;
  late final Stream<List<JobModel>> _jobs = _repo.watchJobs();
  late final Stream<ProviderProfile?> _profile = _repo.watchProfile();

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
  }

  void _push(Widget w) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(subtitle: 'Dashboard'),
        Expanded(
          child: StreamBuilder<ProviderProfile?>(
            stream: _profile,
            builder: (context, ps) {
              if (ps.hasError) return ErrorView(message: 'Could not load profile.\n${ps.error}');
              if (ps.connectionState == ConnectionState.waiting) return const LoadingView();
              final p = ps.data;
              if (p == null) {
                return const ErrorView(message: 'Provider profile not found. Complete registration first.');
              }
              return StreamBuilder<List<JobModel>>(
                stream: _jobs,
                builder: (context, js) {
                  if (js.hasError) return ErrorView(message: 'Could not load jobs.\n${js.error}');
                  if (!js.hasData) return const LoadingView();
                  return _content(p, js.data!);
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _content(ProviderProfile p, List<JobModel> jobs) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    double earned(DateTime day) => jobs
        .where((j) => j.status == 'completed' && _sameDay(j.earnedAt, day))
        .fold<double>(0, (s, j) => s + j.amount);
    final today = earned(now);
    final diff = today - earned(yesterday);

    final todayJobs = jobs
        .where((j) => (j.status == 'confirmed' || j.status == 'in_progress' || j.status == 'completed') &&
            _sameDay(j.scheduledAt, now))
        .toList();
    final doneToday = todayJobs.where((j) => j.status == 'completed').length;
    final ahead = todayJobs.where((j) => j.status != 'completed').toList()
      ..sort((a, b) => (a.scheduledAt ?? now).compareTo(b.scheduledAt ?? now));
    final pending = jobs.where((j) => j.status == 'pending').toList();
    final urgent = pending.where((j) => j.isEmergency).toList()
      ..sort((a, b) => (a.expiresAt ?? now.add(const Duration(days: 1)))
          .compareTo(b.expiresAt ?? now.add(const Duration(days: 1))));
    final first = p.name.split(' ').first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(children: [
          Expanded(
            child: Text('${_greeting()}, $first', style: ts(20, w: FontWeight.w700)),
          ),
          StatusPill(p.isOnline ? 'Available' : 'Away',
              tone: p.isOnline ? Tone.green : Tone.grey, icon: Icons.circle, size: 10.5),
        ]),
        Text('Ready to tackle today\'s home repair queue?',
            style: ts(12, color: AdminColors.grey)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: StatCard(
                label: 'Today\'s Earnings',
                value: formatMoney(today),
                icon: Icons.attach_money_rounded,
                caption: '${diff >= 0 ? '+' : '-'}${formatMoney(diff.abs())} vs yesterday',
                captionTone: diff >= 0 ? Tone.green : Tone.red),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
                label: 'Jobs Today',
                value: '${todayJobs.length}',
                icon: Icons.build_rounded,
                caption: '$doneToday completed, ${todayJobs.length - doneToday} remaining',
                captionTone: Tone.blue),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: StatCard(
                label: 'Pending',
                value: '${pending.length}',
                icon: Icons.pending_actions_rounded,
                caption: 'Needs Review',
                captionTone: Tone.orange,
                onTap: () => widget.onNavigate(1)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
                label: 'Pro Rating',
                value: p.rating.toStringAsFixed(1),
                icon: Icons.star_rounded,
                caption: '${p.reviewCount} verified reviews',
                captionTone: Tone.grey,
                onTap: () => _push(const ReviewsScreen())),
          ),
        ]),
        if (urgent.isNotEmpty) ...[
          const SizedBox(height: 14),
          _urgentCard(urgent.first),
        ],
        const SizedBox(height: 18),
        SectionTitle('Today\'s Schedule',
            icon: Icons.calendar_today_outlined,
            trailing: Text('${ahead.length} JOB${ahead.length == 1 ? '' : 'S'} AHEAD',
                style: ts(10, w: FontWeight.w700, color: AdminColors.grey))),
        const SizedBox(height: 10),
        if (ahead.isEmpty)
          const EmptyView(message: 'No jobs scheduled for the rest of today', icon: Icons.event_available_outlined)
        else
          for (var i = 0; i < ahead.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: JobCard(job: ahead[i], tag: i == 0 ? 'NEXT UP' : null),
            ),
        const SizedBox(height: 8),
        Text('Quick Actions', style: ts(15, w: FontWeight.w700)),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _quick(Icons.work_outline_rounded, 'Manage\nServices', () => _push(const ManageServicesScreen())),
              _quick(Icons.event_repeat_rounded, 'Manage\nAvailability', () => _push(const ManageAvailabilityScreen())),
              _quick(Icons.history_rounded, 'Booking\nHistory',
                  () => _push(const BookingHistoryScreen())),
              _quick(Icons.person_outline_rounded, 'Profile', () => _push(const ProviderProfileScreen())),
              _quick(Icons.star_border_rounded, 'Ratings and\nReviews', () => _push(const ReviewsScreen())),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quick(IconData icon, String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 92,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircleAvatar(
                  radius: 17,
                  backgroundColor: AdminColors.chipBg,
                  child: Icon(icon, size: 18, color: AdminColors.primary)),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: ts(10.5, w: FontWeight.w600)),
            ]),
          ),
        ),
      );

  Widget _urgentCard(JobModel j) {
    return AdminCard(
      borderColor: AdminColors.orange,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const StatusPill('URGENT FLASH REQUEST', tone: Tone.orange, size: 9.5),
          const SizedBox(width: 8),
          if (j.expiresAt != null) _Countdown(expiresAt: j.expiresAt!),
          const Spacer(),
          Text(formatMoney(j.amount), style: ts(16, w: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Text(j.title, style: ts(17, w: FontWeight.w700)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.place_outlined, size: 14, color: AdminColors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
                j.distanceKm == null ? j.address : '${j.distanceKm!.toStringAsFixed(1)} km away',
                style: ts(11.5, color: AdminColors.grey)),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.payments_outlined, size: 14, color: AdminColors.grey),
          const SizedBox(width: 4),
          Text('Cash', style: ts(11.5, color: AdminColors.grey)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            flex: 3,
            child: AdminButton('View Details',
                kind: ButtonKind.filled, icon: Icons.arrow_forward_rounded, height: 42,
                onPressed: () => openJob(context, j)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: AdminButton('Decline', height: 42, onPressed: () => declineJobAction(context, j)),
          ),
        ]),
      ]),
    );
  }
}

class _Countdown extends StatefulWidget {
  const _Countdown({required this.expiresAt});
  final DateTime expiresAt;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.expiresAt.difference(DateTime.now());
    final text = left.isNegative
        ? 'Expired'
        : left.inMinutes < 1
            ? 'Expires in <1m'
            : 'Expires in ${left.inMinutes}m';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.timer_outlined, size: 14, color: AdminColors.grey),
      const SizedBox(width: 3),
      Text(text, style: ts(10.5, color: AdminColors.grey)),
    ]);
  }
}
