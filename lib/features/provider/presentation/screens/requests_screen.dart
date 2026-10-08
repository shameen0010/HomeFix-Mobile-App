import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/booking_card.dart';
import '../widgets/provider_header.dart';
import '../widgets/request_card.dart';

enum _Tab { pending, accepted, declined }

/// FR-P05/P06: incoming requests (Pending / Accepted / Declined).
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _repo = ProviderRepository.instance;
  late final Stream<List<JobModel>> _jobs = _repo.watchJobs();
  late final Stream<List<JobModel>> _declined = _repo.watchDeclinedJobs();
  _Tab _tab = _Tab.pending;

  Widget _segment(String label, int count, _Tab t) {
    final on = _tab == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: on ? AdminColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: ts(12.5, w: FontWeight.w600, color: on ? Colors.white : AdminColors.dark)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: on ? Colors.white24 : Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text('$count', style: ts(10.5, w: FontWeight.w700, color: on ? Colors.white : AdminColors.grey)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(subtitle: 'Requests'),
        Expanded(
          child: StreamBuilder<List<JobModel>>(
            stream: _jobs,
            builder: (context, js) {
              if (js.hasError) return ErrorView(message: 'Could not load requests.\n${js.error}');
              if (!js.hasData) return const LoadingView();
              return StreamBuilder<List<JobModel>>(
                stream: _declined,
                builder: (context, ds) {
                  final all = js.data!;
                  final declined = ds.data ?? const <JobModel>[];
                  final pending = all.where((j) => j.status == 'pending').toList()
                    ..sort((a, b) {
                      if (a.isEmergency != b.isEmergency) return a.isEmergency ? -1 : 1;
                      return (a.scheduledAt ?? DateTime(2100)).compareTo(b.scheduledAt ?? DateTime(2100));
                    });
                  final accepted = all.where((j) => j.isUpcoming).toList()
                    ..sort((a, b) => (a.scheduledAt ?? DateTime(2100)).compareTo(b.scheduledAt ?? DateTime(2100)));
                  int past(JobModel j) =>
                      all.where((x) => x.customerId == j.customerId && x.status == 'completed').length;

                  final list = switch (_tab) {
                    _Tab.pending => pending,
                    _Tab.accepted => accepted,
                    _Tab.declined => declined,
                  };

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Incoming Requests', style: ts(21, w: FontWeight.w700)),
                            Text('Review and dispatch incoming customer orders',
                                style: ts(11.5, color: AdminColors.grey)),
                          ]),
                        ),
                        const StatusPill('LIVE STREAM', tone: Tone.orange, icon: Icons.sensors_rounded, size: 9.5),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          _segment('Pending', pending.length, _Tab.pending),
                          _segment('Accepted', accepted.length, _Tab.accepted),
                          _segment('Declined', declined.length, _Tab.declined),
                        ]),
                      ),
                      if (_tab == _Tab.pending && pending.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            const CircleAvatar(radius: 16, backgroundColor: Colors.white,
                                child: Icon(Icons.bolt_rounded, size: 18, color: AdminColors.primary)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Immediate attention requested', style: ts(12.5, w: FontWeight.w700)),
                                Text('Fast responses boost your pro acceptance rank by +15%',
                                    style: ts(10.5, color: AdminColors.grey)),
                              ]),
                            ),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (list.isEmpty)
                        EmptyView(
                            message: switch (_tab) {
                              _Tab.pending => 'No pending requests right now',
                              _Tab.accepted => 'No accepted jobs yet',
                              _Tab.declined => 'You have not declined any requests',
                            },
                            icon: Icons.inbox_outlined)
                      else
                        for (final j in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _tab == _Tab.accepted
                                ? BookingCard(job: j)
                                : RequestCard(job: j, pastBookings: past(j), declined: _tab == _Tab.declined),
                          ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
