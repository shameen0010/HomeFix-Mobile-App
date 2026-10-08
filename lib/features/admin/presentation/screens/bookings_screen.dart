import 'package:flutter/material.dart';

import '../../core/admin_format.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_widgets.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/booking_ui.dart';

enum _StatusFilter { all, emergency, active, completed, cancelled }

enum _DateFilter { all, today, week }

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key, required this.repository});
  final AdminRepository repository;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late final Stream<List<BookingModel>> _stream = widget.repository.watchBookings();
  _StatusFilter _status = _StatusFilter.all;
  _DateFilter _date = _DateFilter.all;
  String _category = 'all';
  String _provider = 'all'; // all | assigned | unassigned
  String _query = '';

  bool _matches(BookingModel b) {
    final statusOk = switch (_status) {
      _StatusFilter.all => true,
      _StatusFilter.emergency => b.isEmergency,
      _StatusFilter.active => b.isActive,
      _StatusFilter.completed => b.status == 'completed',
      _StatusFilter.cancelled => b.status == 'cancelled',
    };
    if (!statusOk) return false;
    if (_category != 'all' && b.category != _category) return false;
    if (_provider == 'assigned' && !b.hasProvider) return false;
    if (_provider == 'unassigned' && b.hasProvider) return false;

    final when = b.scheduledAt ?? b.createdAt;
    final now = DateTime.now();
    if (_date == _DateFilter.today) {
      if (when == null || when.year != now.year || when.month != now.month || when.day != now.day) {
        return false;
      }
    } else if (_date == _DateFilter.week) {
      if (when == null || when.isBefore(now.subtract(const Duration(days: 7)))) return false;
    }

    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return b.code.toLowerCase().contains(q) ||
        b.title.toLowerCase().contains(q) ||
        b.customerName.toLowerCase().contains(q) ||
        (b.providerName ?? '').toLowerCase().contains(q);
  }

  String _footnote(BookingModel b) {
    if (b.status == 'cancelled') return b.cancelReason ?? 'Cancelled';
    if (b.status == 'completed') {
      return b.rating == null ? 'Completed' : '${b.rating!.toStringAsFixed(1)} Customer Review';
    }
    if (b.isEmergency && !b.hasProvider) return 'High Priority Escalation';
    if (b.status == 'confirmed') return startsIn(b.scheduledAt);
    if (b.status == 'pending' && !b.hasProvider) return 'Awaiting provider assignment';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(
        children: [
          const AdminHeader(subtitle: 'Bookings'),
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorView(message: 'Could not load bookings.\n${snap.error}');
                }
                if (!snap.hasData) return const LoadingView();

                final all = snap.data!;
                final visible = all.where(_matches).toList();
                final urgent = all.where((b) => b.isEmergency && b.isActive && !b.hasProvider).length;
                final done = all.where((b) => b.status == 'completed').length;
                final cancelled = all.where((b) => b.status == 'cancelled').length;
                final fulfillment = (done + cancelled) == 0 ? 100.0 : done * 100 / (done + cancelled);
                final categories = <String, String>{
                  'all': 'All',
                  for (final c in (all.map((b) => b.category).toSet().toList()..sort())) c: c,
                };

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    AdminSearchBox(
                      hint: 'Search bookings (ID, customer, provider)',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        AdminChoiceChip(
                            label: 'All',
                            count: all.length,
                            selected: _status == _StatusFilter.all,
                            onTap: () => setState(() => _status = _StatusFilter.all)),
                        AdminChoiceChip(
                            label: 'Emergency',
                            count: all.where((b) => b.isEmergency).length,
                            dotColor: AdminColors.orange,
                            selected: _status == _StatusFilter.emergency,
                            onTap: () => setState(() => _status = _StatusFilter.emergency)),
                        AdminChoiceChip(
                            label: 'Active',
                            count: all.where((b) => b.isActive).length,
                            selected: _status == _StatusFilter.active,
                            onTap: () => setState(() => _status = _StatusFilter.active)),
                        AdminChoiceChip(
                            label: 'Completed',
                            count: done,
                            selected: _status == _StatusFilter.completed,
                            onTap: () => setState(() => _status = _StatusFilter.completed)),
                        AdminChoiceChip(
                            label: 'Cancelled',
                            count: cancelled,
                            selected: _status == _StatusFilter.cancelled,
                            onTap: () => setState(() => _status = _StatusFilter.cancelled)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: AdminDropdown<String>(
                          label: 'Category',
                          value: _category,
                          items: categories,
                          onChanged: (v) => setState(() => _category = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AdminDropdown<_DateFilter>(
                          label: 'Date',
                          value: _date,
                          items: const {
                            _DateFilter.all: 'All time',
                            _DateFilter.today: 'Today',
                            _DateFilter.week: 'Last 7 days',
                          },
                          onChanged: (v) => setState(() => _date = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AdminDropdown<String>(
                          label: 'Provider',
                          value: _provider,
                          items: const {
                            'all': 'All',
                            'assigned': 'Assigned',
                            'unassigned': 'Unassigned',
                          },
                          onChanged: (v) => setState(() => _provider = v),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: AdminCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Text('$urgent', style: ts(26, w: FontWeight.w700)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Urgent', style: ts(12, w: FontWeight.w600)),
                                  Text('Queue', style: ts(11, color: AdminColors.grey)),
                                  const SizedBox(height: 2),
                                  const StatusPill('Needs Pro', tone: Tone.orange, size: 9.5),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: AdminColors.primary, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${fulfillment.toStringAsFixed(1)}%',
                                      style: ts(18, w: FontWeight.w700)),
                                  Text('Fulfillment', style: ts(11, color: AdminColors.grey)),
                                  StatusPill(fulfillment >= 90 ? 'Stable' : 'Review',
                                      tone: fulfillment >= 90 ? Tone.green : Tone.orange,
                                      size: 9.5),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    if (visible.isEmpty)
                      const EmptyView(message: 'No bookings match your filters')
                    else
                      for (final b in visible)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BookingCard(
                            booking: b,
                            footnote: _footnote(b),
                            onView: () => showBookingDetails(context, widget.repository, b),
                          ),
                        ),
                    Center(
                      child: Text(
                          'Showing ${visible.length} of ${formatCount(all.length)} bookings',
                          style: ts(12, color: AdminColors.grey)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.footnote, required this.onView});
  final BookingModel booking;
  final String footnote;
  final VoidCallback onView;

  Widget _party(IconData icon, String label, String name) => Expanded(
        child: Row(children: [
          Icon(icon, size: 16, color: AdminColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ts(10, color: AdminColors.grey)),
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(12, w: FontWeight.w600)),
              ],
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final (label, tone) = bookingStatusChip(b);
    final muted = b.status == 'cancelled';
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(b.code, style: ts(12, w: FontWeight.w700)),
            const SizedBox(width: 8),
            StatusPill(label, tone: tone, size: 10),
            const Spacer(),
            Text(timeAgo(b.createdAt ?? b.scheduledAt),
                style: ts(10.5, color: AdminColors.grey)),
          ]),
          const SizedBox(height: 8),
          Text(b.title,
              style: ts(16, w: FontWeight.w700,
                  color: muted ? AdminColors.grey : AdminColors.dark)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _party(Icons.person_outline_rounded, 'Customer', b.customerName),
              _party(Icons.engineering_outlined, 'Provider', b.providerName ?? 'Unassigned'),
            ]),
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.place_outlined, size: 14, color: AdminColors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(b.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(11.5, color: AdminColors.grey)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Text(footnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(11.5, w: FontWeight.w600,
                      color: b.isEmergency && b.isActive
                          ? const Color(0xFFB45309)
                          : AdminColors.grey)),
            ),
            AdminButton('View Details',
                height: 36, icon: Icons.arrow_forward_rounded, onPressed: onView),
          ]),
        ],
      ),
    );
  }
}
