import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/hf_theme.dart';
import '../../core/widgets/hf_widgets.dart';
import '../../data/homefix_store.dart';
import '../../data/firestore_notification_service.dart';
import '../../data/profile_photo_service.dart';
import 'provider_execution_screens.dart';

export 'provider_execution_screens.dart';

class LiveProviderNotificationsScreen extends StatelessWidget {
  const LiveProviderNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please log in to view notifications.'));
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreNotificationService().notifications(uid),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs.toList() ?? [];
          docs.sort((a, b) {
            final aDate = a.data()['createdAt'];
            final bDate = b.data()['createdAt'];
            final aValue = aDate is Timestamp ? aDate.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
            final bValue = bDate is Timestamp ? bDate.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
            return bValue.compareTo(aValue);
          });
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              HfScreenHeader(title: 'Notifications', onBack: () => context.pop()),
              if (snapshot.hasError) const Text('Unable to load notifications.', style: TextStyle(color: HfColors.danger)),
              if (docs.isEmpty) const Text('No notifications yet.', style: TextStyle(color: HfColors.muted)),
              for (final document in docs)
                ListTile(
                  onTap: () => FirestoreNotificationService().markRead(document.id),
                  leading: Icon(document.data()['read'] == true ? Icons.notifications_none : Icons.notifications_active, color: HfColors.primary),
                  title: Text((document.data()['title'] ?? 'Notification').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text((document.data()['body'] ?? '').toString()),
                ),
            ],
          );
        },
      ),
    );
  }
}

class LiveProviderServicesScreen extends StatelessWidget {
  const LiveProviderServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please log in to manage services.'));
    final services = FirebaseFirestore.instance.collection('services').where('providerId', isEqualTo: uid);
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: services.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Unable to load services.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              HfScreenHeader(title: 'Manage Services', onBack: () => context.pop()),
              const SizedBox(height: 12),
              HfCard(color: HfColors.primarySoft, child: Row(children: [
                const Icon(Icons.check_circle, color: HfColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('${docs.where((doc) => doc.data()['active'] == true).length} active services')),
              ])),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                const HfCard(child: Text('No services have been added to your provider profile yet.'))
              else
                ...docs.map((document) {
                  final data = document.data();
                  final active = data['active'] == true;
                  final category = (data['category'] ?? 'SERVICE').toString().toUpperCase();
                  final price = data['price'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HfCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        HfBadge(label: category, tone: BadgeTone.blue),
                        const Spacer(),
                        Switch(
                          value: active,
                          activeTrackColor: HfColors.primary,
                          onChanged: (value) async {
                            try {
                              await document.reference.update({'active': value, 'updatedAt': FieldValue.serverTimestamp()});
                            } on FirebaseException catch (error) {
                              if (context.mounted) hfSnack(context, 'Could not update service: ${error.message}');
                            }
                          },
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text((data['title'] ?? 'Home service').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text((data['subtitle'] ?? 'Professional home service').toString(), style: const TextStyle(color: HfColors.muted)),
                      const SizedBox(height: 8),
                      Text('Rs. $price ${data['unit'] ?? '/job'}', style: const TextStyle(fontWeight: FontWeight.w700, color: HfColors.primary)),
                    ])),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class LiveProviderAvailabilityScreen extends StatefulWidget {
  const LiveProviderAvailabilityScreen({super.key});

  @override
  State<LiveProviderAvailabilityScreen> createState() => _LiveProviderAvailabilityScreenState();
}

class _LiveProviderAvailabilityScreenState extends State<LiveProviderAvailabilityScreen> {
  final days = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  late final Map<String, bool> active = {for (final day in days) day: true};
  late final Map<String, String> start = {for (final day in days) day: '08:00 AM'};
  late final Map<String, String> end = {for (final day in days) day: '05:00 PM'};
  bool sameDayEmergency = true;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snapshot = await FirebaseFirestore.instance.collection('providers').doc(uid).get();
    final data = snapshot.data()?['availability'];
    if (data is Map) {
      for (final day in days) {
        final value = data[day];
        if (value is Map) {
          active[day] = value['active'] == true;
          start[day] = (value['start'] ?? start[day]).toString();
          end[day] = (value['end'] ?? end[day]).toString();
        }
      }
    }
    if (snapshot.data()?['sameDayEmergency'] is bool) sameDayEmergency = snapshot.data()!['sameDayEmergency'];
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('providers').doc(uid).set({
        'sameDayEmergency': sameDayEmergency,
        'availableToday': active[days[DateTime.now().weekday - 1]] ?? false,
        'availability': {
          for (final day in days) day: {'active': active[day], 'start': start[day], 'end': end[day]},
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        hfSnack(context, 'Availability saved successfully.');
        context.pop();
      }
    } on FirebaseException catch (error) {
      if (mounted) hfSnack(context, 'Could not save availability: ${error.message}');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return SafeArea(
      child: Column(children: [
        HfScreenHeader(title: 'Manage Availability', onBack: () => context.pop()),
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            HfCard(color: HfColors.primarySoft, child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Accepting Same-Day Emergency'),
              subtitle: const Text('Allow urgent requests from customers'),
              value: sameDayEmergency,
              onChanged: (value) => setState(() => sameDayEmergency = value),
            )),
            const SizedBox(height: 16),
            const Text('ROUTINE SCHEDULE', style: TextStyle(fontWeight: FontWeight.w700, color: HfColors.muted)),
            const SizedBox(height: 8),
            ...days.map((day) => HfCard(child: Column(children: [
              Row(children: [
                Expanded(child: Text(day, style: const TextStyle(fontWeight: FontWeight.w700))),
                Switch(value: active[day]!, activeTrackColor: HfColors.primary, onChanged: (value) => setState(() => active[day] = value)),
              ]),
              if (active[day]!) Row(children: [
                Expanded(child: Text(start[day]!)),
                const Text(' to ', style: TextStyle(color: HfColors.muted)),
                Expanded(child: Text(end[day]!)),
              ]),
            ]))),
          ],
        )),
        Padding(padding: const EdgeInsets.all(16), child: HfPrimaryButton(label: saving ? 'Saving...' : 'Save Availability', onPressed: saving ? () {} : _save)),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER BOTTOM NAVIGATION SHELL
// ═══════════════════════════════════════════════════════════════════════════

const providerNav = [
  HfNavItem(Icons.dashboard_outlined, 'Dashboard'),
  HfNavItem(Icons.inbox_outlined, 'Requests'),
  HfNavItem(Icons.calendar_today_outlined, 'Schedule'),
  HfNavItem(Icons.chat_bubble_outline, 'Messages'),
  HfNavItem(Icons.settings_outlined, 'Settings'),
];

class ProviderShell extends StatefulWidget {
  const ProviderShell({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _selectedIndex == widget.index
              ? widget.child
              : const ProviderDashboard(),
          _selectedIndex == 1 && widget.index == 1
              ? widget.child
              : const ProviderRequestsScreen(),
          _selectedIndex == 2 && widget.index == 2
              ? widget.child
              : const LiveProviderScheduleScreen(),
          _selectedIndex == 3 && widget.index == 3
              ? widget.child
              : const ProviderMessagesScreen(),
          _selectedIndex == 4 && widget.index == 4
              ? widget.child
              : const ProviderMorePlaceholder(),
        ],
      ),
      bottomNavigationBar: HfBottomNav(
        items: providerNav,
        index: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 30 — PROVIDER DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════

class ProviderDashboard extends ConsumerStatefulWidget {
  const ProviderDashboard({super.key});

  @override
  ConsumerState<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends ConsumerState<ProviderDashboard> {
  bool isOnline = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.session;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── Top Bar ──────────────────────────────────────────────
          Row(
            children: [
              // HomeFix PRO badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B8FB5), Color(0xFF0B5F7A)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'HomeFix',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: HfColors.warning,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PRO',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Online toggle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline
                      ? HfColors.success.withValues(alpha: 0.1)
                      : HfColors.field,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline
                        ? HfColors.success.withValues(alpha: 0.3)
                        : HfColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? HfColors.success : HfColors.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isOnline ? HfColors.success : HfColors.grey,
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 20,
                      child: FittedBox(
                        child: Switch(
                          value: isOnline,
                          onChanged: (v) => setState(() => isOnline = v),
                          activeTrackColor: HfColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => context.push('/p/notifications'),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined, color: HfColors.navy),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: HfColors.emergency,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Profile',
                child: InkWell(
                  onTap: () => context.push('/p/profile'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: HfColors.primarySoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: HfColors.primary.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                          ? Image.network(
                              user.avatarUrl!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 22,
                                  color: HfColors.primary,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 22,
                                color: HfColors.primary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Welcome Header ───────────────────────────────────────
          Text(
            'Good morning, ${user?.firstName ?? 'David'} 👋',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: HfColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Ready to accept jobs today in your service area?',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: HfColors.grey,
            ),
          ),
          const SizedBox(height: 16),

          // ── Metrics Grid (2x2) ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: "TODAY'S EARNINGS",
                  value: '\$140.00',
                  sub: '+\$35 vs yesterday',
                  subColor: HfColors.success,
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'JOBS TODAY',
                  value: '3',
                  sub: '1 completed, 2 remaining',
                  icon: Icons.work_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'PENDING',
                  value: '2',
                  sub: 'Needs Review',
                  subColor: HfColors.warning,
                  icon: Icons.pending_actions,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'PRO RATING',
                  value: '4.9 ★',
                  sub: '142 verified reviews',
                  icon: Icons.star_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Urgent Request Banner ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: HfColors.warning.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: HfColors.warning.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flash_on,
                              color: Color(0xFFD97706), size: 12),
                          const SizedBox(width: 3),
                          Text(
                            'URGENT DISPATCH',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFD97706),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '12 MINS LEFT',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: HfColors.danger,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$48.00',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: HfColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pipe Leakage Repair',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: HfColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: HfColors.grey),
                    const SizedBox(width: 3),
                    Text(
                      '1.2 miles away',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: HfColors.grey),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.payments_outlined,
                        size: 13, color: HfColors.grey),
                    const SizedBox(width: 3),
                    Text(
                      'Cash',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: HfColors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HfColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'View Details →',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: HfColors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: HfColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Decline',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Today's Schedule ──────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: HfColors.navy),
              const SizedBox(width: 6),
              Text(
                "Today's Schedule",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HfColors.navy,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: HfColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '3 JOBS AHEAD',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: HfColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Job Card 1 — Next Up
          _ScheduleJobCard(
            isNextUp: true,
            time: '11:30 AM',
            statusLabel: 'On Route',
            customerName: 'Sarah Jenkins',
            jobTitle: 'Pipe Leakage Repair • Kitchen Sink',
            address: '742 Evergreen Terrace',
            onViewDetails: () => context.push('/p/active-service'),
          ),
          const SizedBox(height: 10),

          // Job Card 2
          _ScheduleJobCard(
            isNextUp: false,
            time: '2:00 PM',
            statusLabel: '',
            customerName: 'Michael Chang',
            jobTitle: 'Drain Unclogging • Master Bathroom',
            address: '108 Park Ave, Apt 4B',
            price: '\$65.00 • Pay On-Site',
            onViewDetails: () => context.push('/p/booking-request'),
          ),
          const SizedBox(height: 20),

          // ── Quick Actions ────────────────────────────────────────
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: HfColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickAction(
                icon: Icons.build_outlined,
                label: 'Manage\nServices',
                onTap: () => context.push('/p/services'),
              ),
              _QuickAction(
                icon: Icons.schedule_outlined,
                label: 'Manage\nAvailability',
                onTap: () => context.push('/p/availability'),
              ),
              _QuickAction(
                icon: Icons.history_outlined,
                label: 'Booking\nHistory',
                onTap: () => context.push('/p/history'),
              ),
              _QuickAction(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () => context.push('/p/profile'),
              ),
              _QuickAction(
                icon: Icons.star_outline,
                label: 'Ratings and\nReviews',
                onTap: () => context.push('/p/ratings'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LiveProviderDashboard extends StatelessWidget {
  const _LiveProviderDashboard();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please log in to view your dashboard.'));
    return SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('providers').doc(uid).snapshots(),
        builder: (context, providerSnapshot) {
          final provider = providerSnapshot.data?.data() ?? const <String, dynamic>{};
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('bookings').where('providerId', isEqualTo: uid).snapshots(),
            builder: (context, bookingSnapshot) {
              final docs = bookingSnapshot.data?.docs ?? const [];
              final pendingDocs = docs.where((doc) => (doc.data()['status'] ?? '').toString().toLowerCase() == 'pending').toList();
              final activeCount = docs.where((doc) {
                final status = (doc.data()['status'] ?? '').toString().toLowerCase();
                return ['accepted', 'confirmed', 'en_route', 'in_progress', 'started', 'scheduled'].contains(status);
              }).length;
              final completed = docs.where((doc) => (doc.data()['status'] ?? '').toString().toLowerCase() == 'completed').length;
              final name = (provider['name'] ?? 'Provider').toString();
              final rating = (provider['rating'] as num?)?.toDouble() ?? 0;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Row(children: [
                    const HfBrandMark(compact: true),
                    const Spacer(),
                    IconButton(onPressed: () => context.push('/p/notifications'), icon: const Icon(Icons.notifications_outlined)),
                    const CircleAvatar(backgroundColor: HfColors.primarySoft, child: Icon(Icons.person, color: HfColors.primary)),
                  ]),
                  const SizedBox(height: 16),
                  Text('Welcome, $name', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: HfColors.navy)),
                  const Text('Manage your live service requests', style: TextStyle(color: HfColors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _LiveMetric(label: 'PENDING', value: '${pendingDocs.length}', icon: Icons.pending_actions)),
                    const SizedBox(width: 10),
                    Expanded(child: _LiveMetric(label: 'ACTIVE', value: '$activeCount', icon: Icons.work_outline)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _LiveMetric(label: 'COMPLETED', value: '$completed', icon: Icons.check_circle_outline)),
                    const SizedBox(width: 10),
                    Expanded(child: _LiveMetric(label: 'RATING', value: rating == 0 ? '—' : rating.toStringAsFixed(1), icon: Icons.star_outline)),
                  ]),
                  const SizedBox(height: 18),
                  Row(children: [
                    Text('Pending requests', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    TextButton(onPressed: () => context.go('/p/requests'), child: const Text('See all')),
                  ]),
                  if (bookingSnapshot.hasError)
                    const Text('Unable to load requests.', style: TextStyle(color: HfColors.danger))
                  else if (pendingDocs.isEmpty)
                    const Text('No pending requests yet.', style: TextStyle(color: HfColors.muted))
                  else
                    ...pendingDocs.take(3).map((doc) => _LiveProviderRequest(document: doc)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LiveMetric extends StatelessWidget {
  const _LiveMetric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => HfCard(
        child: Row(children: [
          Icon(icon, color: HfColors.primary),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            Text(label, style: const TextStyle(color: HfColors.muted, fontSize: 10)),
          ]),
        ]),
      );
}

class _LiveProviderRequest extends StatelessWidget {
  const _LiveProviderRequest({required this.document});
  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  @override
  Widget build(BuildContext context) {
    final data = document.data();
    return HfCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text((data['serviceTitle'] ?? data['serviceType'] ?? 'Home service').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text((data['customerName'] ?? 'Customer').toString(), style: const TextStyle(color: HfColors.muted)),
        Text((data['address'] ?? 'Address not provided').toString(), style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 10),
        HfPrimaryButton(label: 'Review Request', onPressed: () => context.go('/p/requests')),
      ]),
    );
  }
}

class LiveProviderScheduleScreen extends StatelessWidget {
  const LiveProviderScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please log in to view your schedule.'));
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('bookings').where('providerId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs.where((doc) {
            final status = (doc.data()['status'] ?? '').toString().toLowerCase();
            return status != 'cancelled' && status != 'completed';
          }).toList() ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const HfScreenHeader(title: 'Schedule'),
              if (snapshot.hasError)
                const Text('Unable to load your schedule.', style: TextStyle(color: HfColors.danger))
              else if (docs.isEmpty)
                const Text('No scheduled bookings yet.', style: TextStyle(color: HfColors.muted))
              else
                for (final document in docs)
                  HfCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((document.data()['serviceTitle'] ?? document.data()['serviceType'] ?? 'Home service').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text((document.data()['customerName'] ?? 'Customer').toString(), style: const TextStyle(color: HfColors.muted)),
                    Text((document.data()['address'] ?? 'Address not provided').toString(), style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    Text((document.data()['status'] ?? 'pending').toString(), style: const TextStyle(color: HfColors.primary, fontWeight: FontWeight.w700)),
                  ])),
            ],
          );
        },
      ),
    );
  }
}

// ─── Metric Card ───────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? subColor;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.sub,
    this.subColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: HfColors.grey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: HfColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: subColor ?? HfColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Job Card ─────────────────────────────────────────────────────
class _ScheduleJobCard extends StatelessWidget {
  final bool isNextUp;
  final String time;
  final String statusLabel;
  final String customerName;
  final String jobTitle;
  final String address;
  final String? price;
  final VoidCallback onViewDetails;

  const _ScheduleJobCard({
    required this.isNextUp,
    required this.time,
    required this.statusLabel,
    required this.customerName,
    required this.jobTitle,
    required this.address,
    this.price,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isNextUp
            ? Border.all(color: HfColors.primary.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: time + status
          Row(
            children: [
              if (isNextUp) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: HfColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NEXT UP • $time',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: HfColors.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HfColors.grey,
                  ),
                ),
              ],
              const Spacer(),
              if (statusLabel.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: HfColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: HfColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: HfColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Customer info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: HfColors.primarySoft,
                child:
                    Icon(Icons.person, color: HfColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HfColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      jobTitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: HfColors.grey,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: HfColors.muted),
                        const SizedBox(width: 2),
                        Text(
                          address,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: HfColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Actions row
          if (isNextUp)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HfColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'View Details →',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CircleIconBtn(
                  icon: Icons.phone_outlined,
                  onTap: () {},
                ),
                const SizedBox(width: 6),
                _CircleIconBtn(
                  icon: Icons.chat_bubble_outline,
                  onTap: () => context.push('/p/chat'),
                ),
              ],
            )
          else
            Row(
              children: [
                if (price != null) ...[
                  Text(
                    price!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HfColors.navy,
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: onViewDetails,
                  child: Text(
                    'View Job Brief',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HfColors.primary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Circle Icon Button ────────────────────────────────────────────────────
class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: HfColors.field,
          shape: BoxShape.circle,
          border: Border.all(color: HfColors.border),
        ),
        child: Icon(icon, size: 18, color: HfColors.primary),
      ),
    );
  }
}

// ─── Quick Action ──────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: HfColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                    color: HfColors.primary.withValues(alpha: 0.15)),
              ),
              child: Icon(icon, color: HfColors.primary, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: HfColors.navy,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 31 — MANAGE SERVICES
// ═══════════════════════════════════════════════════════════════════════════

class _ServiceData {
  final String id;
  final String category;
  final String title;
  final String price;
  final String duration;
  bool isActive = true;

  _ServiceData({
    required this.id,
    required this.category,
    required this.title,
    required this.price,
    required this.duration,
  });
}

class ManageServicesScreen extends ConsumerStatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  ConsumerState<ManageServicesScreen> createState() =>
      _ManageServicesScreenState();
}

class _ManageServicesScreenState extends ConsumerState<ManageServicesScreen> {
  bool catalogActive = true;
  String selectedFilter = 'All';

  final services = [
    _ServiceData(
      id: 's1',
      category: 'PLUMBING',
      title: 'Pipe Leakage Repair',
      price: '\$45.00 base / hr',
      duration: '35-60 mins est.',
    ),
    _ServiceData(
      id: 's2',
      category: 'PLUMBING',
      title: 'Drain Unclogging & Cleaning',
      price: '\$65.00 base',
      duration: '60-90 mins est.',
    ),
    _ServiceData(
      id: 's3',
      category: 'PLUMBING',
      title: 'Bathroom Fixture Installation',
      price: '\$80.00 base',
      duration: '45-90 mins est.',
    ),
    _ServiceData(
      id: 's4',
      category: 'MAINTENANCE',
      title: 'General Home Maintenance',
      price: '\$55.00 base',
      duration: '30-45 mins est.',
    ),
  ];

  List<_ServiceData> get filteredServices {
    if (selectedFilter == 'All') return services;
    return services.where((s) => s.category == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Column(
        children: [
          // ── Top Bar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: HfColors.navy),
                ),
                Text(
                  'Manage Services',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: HfColors.navy,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => context.go('/p/home'),
                  icon: const Icon(Icons.home_outlined, color: HfColors.navy),
                  iconSize: 22,
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: HfColors.primarySoft,
                  child:
                      Icon(Icons.person, color: HfColors.primary, size: 18),
                ),
              ],
            ),
          ),

          // ── Scrollable Content ─────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // My Services header
                Row(
                  children: [
                    Text(
                      'My Services',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: HfColors.navy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: HfColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${services.where((s) => s.isActive).length} Active Services',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: HfColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.tune, size: 20, color: HfColors.grey),
                  ],
                ),
                const SizedBox(height: 12),

                // Active Catalog banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HfColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: HfColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: HfColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Catalog',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: HfColors.navy,
                                  ),
                                ),
                                Text(
                                  'Instant customer bookings enabled',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: HfColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 24,
                            child: FittedBox(
                              child: Switch(
                                value: catalogActive,
                                onChanged: (v) =>
                                    setState(() => catalogActive = v),
                                activeTrackColor: HfColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: HfColors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Within 10 miles of Brooklyn, NY',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: HfColors.grey,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Edit Area',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: HfColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Add New Service button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'Add New Service',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HfColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All (${services.length})',
                        selected: selectedFilter == 'All',
                        onTap: () =>
                            setState(() => selectedFilter = 'All'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label:
                            'Plumbing (${services.where((s) => s.category == 'PLUMBING').length})',
                        selected: selectedFilter == 'PLUMBING',
                        onTap: () =>
                            setState(() => selectedFilter = 'PLUMBING'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label:
                            'General Maintenance (${services.where((s) => s.category == 'MAINTENANCE').length})',
                        selected: selectedFilter == 'MAINTENANCE',
                        onTap: () =>
                            setState(() => selectedFilter = 'MAINTENANCE'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Service cards
                ...filteredServices.map((svc) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ServiceCard(
                        service: svc,
                        onToggle: (v) =>
                            setState(() => svc.isActive = v),
                      ),
                    )),
                const SizedBox(height: 12),

                // Bottom helper notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HfColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: HfColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Need custom pricing for materials? You can adjust quotes on-site after diagnostic directly from the active dispatch screen.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: HfColors.grey,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip ───────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? HfColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? HfColors.navy : HfColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : HfColors.grey,
          ),
        ),
      ),
    );
  }
}

// ─── Service Card ──────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final _ServiceData service;
  final ValueChanged<bool> onToggle;

  const _ServiceCard({required this.service, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: service.category == 'PLUMBING'
                      ? HfColors.primary.withValues(alpha: 0.1)
                      : HfColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  service.category,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: service.category == 'PLUMBING'
                        ? HfColors.primary
                        : HfColors.warning,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: const Icon(Icons.edit_outlined,
                    size: 18, color: HfColors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            service.title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: HfColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 14, color: HfColors.grey),
              Text(
                service.price,
                style: GoogleFonts.inter(
                    fontSize: 12, color: HfColors.grey),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.schedule, size: 14, color: HfColors.grey),
              const SizedBox(width: 2),
              Text(
                service.duration,
                style: GoogleFonts.inter(
                    fontSize: 12, color: HfColors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      service.isActive ? HfColors.success : HfColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                service.isActive ? 'Active & Bookable' : 'Inactive',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      service.isActive ? HfColors.success : HfColors.grey,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 24,
                child: FittedBox(
                  child: Switch(
                    value: service.isActive,
                    onChanged: onToggle,
                    activeTrackColor: HfColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 32 — PROVIDER AVAILABILITY
// ═══════════════════════════════════════════════════════════════════════════

class _DaySchedule {
  final String day;
  final String startTime;
  final String endTime;
  final int maxJobs;
  bool isActive;
  final bool isToday;

  _DaySchedule({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.maxJobs,
    this.isActive = true,
    this.isToday = false,
  });
}

class ProviderAvailabilityScreen extends ConsumerStatefulWidget {
  const ProviderAvailabilityScreen({super.key});

  @override
  ConsumerState<ProviderAvailabilityScreen> createState() =>
      _ProviderAvailabilityScreenState();
}

class _ProviderAvailabilityScreenState
    extends ConsumerState<ProviderAvailabilityScreen> {
  bool sameDayEmergency = true;

  final schedule = [
    _DaySchedule(
      day: 'Monday',
      startTime: '08:00 AM',
      endTime: '05:00 PM',
      maxJobs: 4,
    ),
    _DaySchedule(
      day: 'Tuesday',
      startTime: '08:00 AM',
      endTime: '05:00 PM',
      maxJobs: 4,
    ),
    _DaySchedule(
      day: 'Wednesday',
      startTime: '08:00 AM',
      endTime: '05:00 PM',
      maxJobs: 4,
      isToday: true,
    ),
    _DaySchedule(
      day: 'Thursday',
      startTime: '08:00 AM',
      endTime: '05:00 PM',
      maxJobs: 4,
    ),
    _DaySchedule(
      day: 'Friday',
      startTime: '08:00 AM',
      endTime: '04:00 PM',
      maxJobs: 5,
    ),
    _DaySchedule(
      day: 'Saturday',
      startTime: '09:00 AM',
      endTime: '02:00 PM',
      maxJobs: 2,
      isActive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Top Bar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: HfColors.navy),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Availability',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: HfColors.navy,
                        ),
                      ),
                      Text(
                        'Set your routine working days and arrival windows',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: HfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.go('/p/home'),
                  icon: const Icon(Icons.home_outlined, color: HfColors.navy),
                  iconSize: 22,
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: HfColors.primarySoft,
                  child:
                      Icon(Icons.person, color: HfColors.primary, size: 18),
                ),
              ],
            ),
          ),

          // ── Scrollable Content ─────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                // Same-Day Emergency banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: HfColors.primary.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: HfColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.flash_on,
                            color: HfColors.warning, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Accepting Same-Day',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: HfColors.navy,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: HfColors.success,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'LIVE',
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Instant booking for plumbing and electrical emergencies',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: HfColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        child: FittedBox(
                          child: Switch(
                            value: sameDayEmergency,
                            onChanged: (v) =>
                                setState(() => sameDayEmergency = v),
                            activeTrackColor: HfColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Section header
                Text(
                  'ROUTINE SCHEDULE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: HfColors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),

                // Day rows
                ...schedule.map((day) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DayRow(
                        schedule: day,
                        onToggle: (v) =>
                            setState(() => day.isActive = v),
                      ),
                    )),
                const SizedBox(height: 14),

                // Planning time off card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              HfColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.beach_access_outlined,
                            color: HfColors.warning, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Planning time off?',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: HfColors.navy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pause incoming bookings with vacation mode to protect your response metrics.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: HfColors.grey,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Set Vacation Dates >',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: HfColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── Bottom Save Button ─────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    hfSnack(context, 'Availability saved successfully!');
                    context.pop();
                  },
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    'Save Availability',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HfColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Day Row ───────────────────────────────────────────────────────────────
class _DayRow extends StatelessWidget {
  final _DaySchedule schedule;
  final ValueChanged<bool> onToggle;

  const _DayRow({required this.schedule, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: schedule.isToday
            ? Border.all(color: HfColors.primary.withValues(alpha: 0.4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left indicator for today
          if (schedule.isToday)
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: HfColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      schedule.day,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HfColors.navy,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (schedule.isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: HfColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Today',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: HfColors.field,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Max ${schedule.maxJobs} Jobs',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: HfColors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${schedule.startTime} - ${schedule.endTime}${schedule.isToday ? ' (Max ${schedule.maxJobs} Jobs)' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: HfColors.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 24,
            child: FittedBox(
              child: Switch(
                value: schedule.isActive,
                onChanged: onToggle,
                activeTrackColor: HfColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 33 — PROVIDER CHAT
// ═══════════════════════════════════════════════════════════════════════════

class _ChatMsg {
  final String sender; // 'customer' or 'provider'
  final String text;
  final String time;
  final String senderName;

  const _ChatMsg({
    required this.sender,
    required this.text,
    required this.time,
    required this.senderName,
  });
}

class ProviderChatScreen extends ConsumerStatefulWidget {
  final String customerName;
  final String customerAvatar;
  final String customerAddress;
  final String bookingId;
  final String serviceTitle;

  const ProviderChatScreen({
    super.key,
    this.customerName = 'Customer',
    this.customerAvatar = '',
    this.customerAddress = 'Address not provided',
    this.bookingId = '',
    this.serviceTitle = 'Home service',
  });

  @override
  ConsumerState<ProviderChatScreen> createState() =>
      _ProviderChatScreenState();
}

class _ProviderChatScreenState extends ConsumerState<ProviderChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMsg> _messages = [];

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMsg(
        sender: 'provider',
        text: _msgController.text.trim(),
        time: TimeOfDay.now().format(context),
        senderName: 'You',
      ));
    });
    _msgController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon:
                        const Icon(Icons.arrow_back, color: HfColors.navy),
                  ),
                  Text(
                    'Provider Chat',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: HfColors.navy,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.go('/p/home'),
                    icon: const Icon(Icons.home_outlined,
                        color: HfColors.navy),
                    iconSize: 22,
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: HfColors.primarySoft,
                    child: Icon(Icons.person,
                        color: HfColors.primary, size: 18),
                  ),
                ],
              ),
            ),

            // ── Customer info header ─────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: HfColors.primarySoft,
                    backgroundImage: widget.customerAvatar.isNotEmpty
                        ? NetworkImage(widget.customerAvatar)
                        : null,
                    child: widget.customerAvatar.isEmpty
                        ? Text(
                            widget.customerName.isNotEmpty
                                ? widget.customerName[0]
                                : 'C',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: HfColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.customerName,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: HfColors.navy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: HfColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Active',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: HfColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.customerAddress,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: HfColors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _CircleIconBtn(
                    icon: Icons.phone_outlined,
                    onTap: () => hfSnack(context, 'Calling ${widget.customerName}...'),
                  ),
                  const SizedBox(width: 6),
                  _CircleIconBtn(
                    icon: Icons.info_outline,
                    onTap: () => hfSnack(context, 'Job: ${widget.serviceTitle} (${widget.bookingId})'),
                  ),
                ],
              ),
            ),

            // ── Booking reference badge ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: HfColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: HfColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Booking ${widget.bookingId} • ${widget.serviceTitle}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: HfColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Messages ─────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isProvider = msg.sender == 'provider';
                  return _ChatBubble(
                    message: msg,
                    isProvider: isProvider,
                  );
                },
              ),
            ),

            // ── Input Bar ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: HfColors.field,
                          shape: BoxShape.circle,
                          border: Border.all(color: HfColors.border),
                        ),
                        child: const Icon(Icons.attach_file,
                            size: 18, color: HfColors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type a message to Sarah...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: HfColors.muted,
                          ),
                          filled: true,
                          fillColor: HfColors.field,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {},
                      child: const Icon(Icons.mic_none,
                          color: HfColors.grey, size: 22),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: HfColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat Bubble ───────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final _ChatMsg message;
  final bool isProvider;

  const _ChatBubble({required this.message, required this.isProvider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isProvider ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isProvider) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: HfColors.primarySoft,
              child:
                  Icon(Icons.person, color: HfColors.primary, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isProvider
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isProvider
                        ? HfColors.primary
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isProvider
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isProvider
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isProvider ? Colors.white : HfColors.navy,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${message.senderName} • ${message.time}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: HfColors.muted,
                      ),
                    ),
                    if (isProvider) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 12,
                        color: HfColors.info,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isProvider) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: HfColors.primary,
              child: Text(
                'DM',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER PLACEHOLDER / ROUTE INTEGRATION
// ═══════════════════════════════════════════════════════════════════════════

class ProviderRequestsPlaceholder extends StatelessWidget {
  const ProviderRequestsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderRequestsScreen();
  }
}

class ProviderSchedulePlaceholder extends StatelessWidget {
  const ProviderSchedulePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScheduleScreen();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN: PROVIDER MESSAGES / CUSTOMER CHAT LIST
// ═══════════════════════════════════════════════════════════════════════════

class CustomerChatItem {
  final String id;
  final String customerName;
  final String avatarUrl;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final String jobTitle;
  final String bookingId;
  final String address;
  final bool isActiveJob;

  const CustomerChatItem({
    required this.id,
    required this.customerName,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    required this.jobTitle,
    required this.bookingId,
    required this.address,
    this.isActiveJob = false,
  });
}

class ProviderMessagesScreen extends ConsumerStatefulWidget {
  const ProviderMessagesScreen({super.key});

  @override
  ConsumerState<ProviderMessagesScreen> createState() =>
      _ProviderMessagesScreenState();
}

class _ProviderMessagesScreenState
    extends ConsumerState<ProviderMessagesScreen> {
  String _searchQuery = '';
  int _selectedFilter = 0; // 0: All, 1: Active Jobs, 2: Unread
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<CustomerChatItem> _allChats = [
    CustomerChatItem(
      id: 'chat_1',
      customerName: 'Sarah Jenkins',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      lastMessage:
          "I've turned off the main water valve as you requested. Are you close?",
      time: '11:42 AM',
      unreadCount: 2,
      isOnline: true,
      jobTitle: 'Pipe Leakage Repair',
      bookingId: '#HF-8921',
      address: '742 Evergreen Terrace, Apt 4B',
      isActiveJob: true,
    ),
    CustomerChatItem(
      id: 'chat_2',
      customerName: 'Alex Rivera',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      lastMessage:
          'Sounds good David! Please ring the front buzzer when you arrive.',
      time: '10:15 AM',
      unreadCount: 1,
      isOnline: true,
      jobTitle: 'AC Diagnostic & Filter Fix',
      bookingId: '#HF-8914',
      address: '1204 Pine Valley Rd',
      isActiveJob: true,
    ),
    CustomerChatItem(
      id: 'chat_3',
      customerName: 'Michael Chen',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      lastMessage:
          'Can you inspect the basement sub-panel as well while you are here?',
      time: 'Yesterday',
      unreadCount: 0,
      isOnline: true,
      jobTitle: 'Electrical Panel Upgrade 200A',
      bookingId: '#HF-8872',
      address: '501 Cedar Crest Dr',
      isActiveJob: true,
    ),
    CustomerChatItem(
      id: 'chat_4',
      customerName: 'Emma Watson',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      lastMessage:
          'Thank you for bringing the eco-friendly cleaning solutions! Left 5 stars.',
      time: 'Yesterday',
      unreadCount: 0,
      isOnline: false,
      jobTitle: 'Deep Kitchen & Bath Sanitization',
      bookingId: '#HF-8890',
      address: '88 Elmwood Blvd, Suite 12',
      isActiveJob: false,
    ),
    CustomerChatItem(
      id: 'chat_5',
      customerName: 'Lisa Wong',
      avatarUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      lastMessage:
          'The paint finish matched perfectly! Thank you for fixing the wall seams.',
      time: 'Oct 4',
      unreadCount: 0,
      isOnline: false,
      jobTitle: 'Drywall Patch & Interior Paint',
      bookingId: '#HF-8820',
      address: '320 Maple Ave',
      isActiveJob: false,
    ),
    CustomerChatItem(
      id: 'chat_6',
      customerName: 'Robert Taylor',
      avatarUrl:
          'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
      lastMessage:
          'Appreciate the emergency water pressure fix on Saturday night!',
      time: 'Oct 2',
      unreadCount: 0,
      isOnline: false,
      jobTitle: 'Water Heater Pressure Relief',
      bookingId: '#HF-8805',
      address: '104 Magnolia Court',
      isActiveJob: false,
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openChat(CustomerChatItem chat) {
    context.push(
      '/p/chat',
      extra: {
        'customerName': chat.customerName,
        'customerAvatar': chat.avatarUrl,
        'customerAddress': '${chat.jobTitle} • ${chat.address}',
        'bookingId': chat.bookingId,
        'serviceTitle': chat.jobTitle,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _liveMessages();
    /*
    final query = _searchQuery.trim().toLowerCase();

    final filtered = _allChats.where((c) {
      if (_selectedFilter == 1 && !c.isActiveJob) return false;
      if (_selectedFilter == 2 && c.unreadCount == 0) return false;
      if (query.isNotEmpty) {
        final matchName = c.customerName.toLowerCase().contains(query);
        final matchJob = c.jobTitle.toLowerCase().contains(query);
        final matchMsg = c.lastMessage.toLowerCase().contains(query);
        final matchAddr = c.address.toLowerCase().contains(query);
        return matchName || matchJob || matchMsg || matchAddr;
      }
      return true;
    }).toList();

    final totalUnread =
        _allChats.fold<int>(0, (sum, c) => sum + c.unreadCount);

    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Customer Messages',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: HfColors.navy,
                            ),
                          ),
                          if (totalUnread > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: HfColors.emergency,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$totalUnread new',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Direct communication with your booked clients',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: HfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => hfSnack(context, 'Synced with messages.'),
                  icon: const Icon(Icons.refresh_rounded, color: HfColors.navy),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // ── Search Bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: HfColors.field,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HfColors.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.inter(fontSize: 14, color: HfColors.navy),
                decoration: InputDecoration(
                  hintText: 'Search customer, job, or message...',
                  hintStyle:
                      GoogleFonts.inter(fontSize: 13, color: HfColors.muted),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: HfColors.muted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // ── Active Customers Story Reel ──────────────────────────
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                for (final chat in _allChats.where((c) => c.isOnline))
                  InkWell(
                    onTap: () => _openChat(chat),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: chat.isActiveJob
                                        ? HfColors.primary
                                        : HfColors.border,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    chat.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: HfColors.primarySoft,
                                      child: Center(
                                        child: Text(
                                          chat.customerName[0],
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            color: HfColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: HfColors.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chat.customerName.split(' ').first,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: HfColors.navy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Filter Segment Chips ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                _filterChip(0, 'All (${_allChats.length})'),
                const SizedBox(width: 8),
                _filterChip(1, 'Active Jobs (${_allChats.where((c) => c.isActiveJob).length})'),
                const SizedBox(width: 8),
                _filterChip(2, 'Unread ($totalUnread)'),
              ],
            ),
          ),

          const Divider(height: 1, color: HfColors.border),

          // ── Conversations List ───────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 48, color: HfColors.muted),
                          const SizedBox(height: 12),
                          Text(
                            'No conversations found',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: HfColors.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different search or filter setting',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: HfColors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedFilter = 0;
                              });
                            },
                            child: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final chat = filtered[index];
                      return _buildChatCard(chat);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? HfColors.primary : HfColors.field,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? HfColors.primary : HfColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : HfColors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildChatCard(CustomerChatItem chat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: chat.unreadCount > 0
              ? HfColors.primary.withValues(alpha: 0.35)
              : HfColors.border,
          width: chat.unreadCount > 0 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openChat(chat),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with online status
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: chat.unreadCount > 0
                            ? HfColors.primary
                            : HfColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        chat.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: HfColors.primarySoft,
                          child: Center(
                            child: Text(
                              chat.customerName[0],
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: HfColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (chat.isOnline)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: HfColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Chat content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Name + Badge + Time
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            chat.customerName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: HfColors.navy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.isActiveJob) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: HfColors.primarySoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              chat.bookingId,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: HfColors.primary,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          chat.time,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: chat.unreadCount > 0
                                ? HfColors.primary
                                : HfColors.muted,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Job title and location
                    Text(
                      '${chat.jobTitle} • ${chat.address}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: HfColors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Message snippet & unread count badge
                    Row(
                      children: [
                        if (chat.unreadCount == 0)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.done_all_rounded,
                                size: 15, color: HfColors.primary),
                          ),
                        Expanded(
                          child: Text(
                            chat.lastMessage,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: chat.unreadCount > 0
                                  ? HfColors.navy
                                  : HfColors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: HfColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${chat.unreadCount}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Quick Phone Call button
              IconButton(
                onPressed: () =>
                    hfSnack(context, 'Calling ${chat.customerName}...'),
                icon: const Icon(Icons.phone_outlined,
                    size: 20, color: HfColors.primary),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Call Customer',
              ),
            ],
          ),
        ),
      ),
    );*/
  }

  Widget _liveMessages() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please log in to view messages.'));
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('bookings').where('providerId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const HfScreenHeader(title: 'Messages'),
              if (snapshot.hasError)
                const Text('Unable to load conversations.', style: TextStyle(color: HfColors.danger))
              else if (docs.isEmpty)
                const Text('No conversations yet.', style: TextStyle(color: HfColors.muted))
              else
                for (final document in docs)
                  ListTile(
                    onTap: () => context.push('/p/chat', extra: {
                      'customerName': document.data()['customerName'] ?? 'Customer',
                      'bookingId': document.id,
                      'serviceTitle': document.data()['serviceTitle'] ?? document.data()['serviceType'] ?? 'Home service',
                    }),
                    leading: const HfAvatar(url: null, fallback: 'C'),
                    title: Text((document.data()['customerName'] ?? 'Customer').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text((document.data()['serviceTitle'] ?? document.data()['serviceType'] ?? 'Home service').toString()),
                    trailing: const HfBadge(label: 'Booking', tone: BadgeTone.green),
                  ),
            ],
          );
        },
      ),
    );
  }
}

typedef ProviderMessagesPlaceholder = ProviderMessagesScreen;

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER MORE / PLACEHOLDER ROUTE
// ═══════════════════════════════════════════════════════════════════════════

class ProviderMorePlaceholder extends StatelessWidget {
  const ProviderMorePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderSettingsScreen();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 34 — PROVIDER PUBLIC PROFILE
// ═══════════════════════════════════════════════════════════════════════════

class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  ConsumerState<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class LiveProviderProfileScreen extends StatelessWidget {
  const LiveProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please log in to view your profile.'));
    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('providers').doc(uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Unable to load provider profile.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!.data() ?? {};
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                HfScreenHeader(title: 'Provider Profile', onBack: () => context.pop()),
                HfCard(child: Column(children: [
                  HfAvatar(url: data['photoUrl']?.toString(), size: 84, fallback: (data['name'] ?? 'Provider').toString()),
                  const SizedBox(height: 8),
                  Text((data['name'] ?? 'Provider').toString(), style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w800)),
                  Text((data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '').toString(), style: const TextStyle(color: HfColors.muted)),
                  Text((data['phone'] ?? 'Phone not added').toString(), style: const TextStyle(color: HfColors.muted)),
                  const SizedBox(height: 8),
                  Text('${data['rating'] ?? 0} (${data['reviewCount'] ?? 0} reviews)', style: const TextStyle(fontWeight: FontWeight.w700)),
                  HfBadge(label: (data['verificationStatus'] ?? data['status'] ?? 'pending').toString().toUpperCase(), tone: BadgeTone.teal),
                  const SizedBox(height: 10),
                  HfSoftButton(
                    label: 'Change Photo',
                    icon: Icons.photo_camera_outlined,
                    onPressed: () => _uploadPhoto(context, uid),
                  ),
                ])),
                const SizedBox(height: 12),
                HfCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Business details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Specialty: ${(data['specialty'] ?? data['serviceType'] ?? 'Not added').toString()}'),
                  Text('Service area: ${(data['area'] ?? data['serviceArea'] ?? 'Not added').toString()}'),
                  Text('Experience: ${(data['yearsExp'] ?? data['experience'] ?? 0).toString()} years'),
                  Text('Hourly rate: Rs. ${(data['hourlyRate'] ?? 0).toString()}'),
                  const SizedBox(height: 8),
                  Text((data['bio'] ?? 'No business bio added.').toString(), style: const TextStyle(color: HfColors.muted)),
                ])),
                const SizedBox(height: 12),
                HfPrimaryButton(label: 'Edit Profile', icon: Icons.edit_outlined, onPressed: () => _edit(context, uid, data)),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(BuildContext context, String uid) async {
    try {
      final url = await ProfilePhotoService().pickAndUpload(
        userId: uid,
        collection: 'providers',
      );
      if (url == null) return;
      await FirebaseFirestore.instance.collection('providers').doc(uid).set({
        'avatarUrl': url,
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (context.mounted) hfSnack(context, 'Profile photo updated.');
    } catch (error) {
      if (context.mounted) hfSnack(context, 'Could not upload photo: $error');
    }
  }

  Future<void> _edit(BuildContext context, String uid, Map<String, dynamic> data) async {
    final name = TextEditingController(text: data['name']?.toString() ?? '');
    final phone = TextEditingController(text: data['phone']?.toString() ?? '');
    final area = TextEditingController(text: data['area']?.toString() ?? data['serviceArea']?.toString() ?? '');
    final bio = TextEditingController(text: data['bio']?.toString() ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Provider Profile'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
          TextField(controller: area, decoration: const InputDecoration(labelText: 'Service area')),
          TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('providers').doc(uid).set({
              'name': name.text.trim(), 'phone': phone.text.trim(), 'area': area.text.trim(),
              'serviceArea': area.text.trim(), 'bio': bio.text.trim(), 'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            if (context.mounted) Navigator.pop(context, true);
          }, child: const Text('Save')),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
    area.dispose();
    bio.dispose();
    if (result == true && context.mounted) hfSnack(context, 'Profile updated.');
  }
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.session;
    final displayName = user?.name.isNotEmpty == true ? user!.name : 'David Miller';

    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── Top Bar ──────────────────────────────────────────────
            Row(
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: HfColors.navy, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                // HomeFix Logo + Online pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B8FB5), Color(0xFF0B5F7A)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'HomeFix',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: HfColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: HfColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: HfColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Online',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: HfColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Settings icon
                IconButton(
                  onPressed: () => context.push('/p/settings'),
                  icon: const Icon(Icons.settings_outlined, color: HfColors.navy, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                // Notification icon
                IconButton(
                  onPressed: () => context.push('/p/notifications'),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined, color: HfColors.navy, size: 22),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: HfColors.emergency,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 4),
                // Avatar / Profile icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: HfColors.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: HfColors.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                        ? Image.network(
                            user.avatarUrl!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 22,
                                color: HfColors.primary,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 22,
                              color: HfColors.primary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your public service credentials, bio, and rates',
              style: GoogleFonts.inter(fontSize: 12, color: HfColors.grey),
            ),
            const SizedBox(height: 16),

            // ── Profile Hero Card ────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HfColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Photo with edit badge
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: HfColors.primarySoft,
                          backgroundImage: user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : const NetworkImage(
                                  'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=200'),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Change photo clicked')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: HfColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: HfColors.navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Master Plumber & Pipe Specialist',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: HfColors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Licensed Master Plumber',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: HfColors.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBCE1F2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, size: 12, color: HfColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Verified Pro',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: HfColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          '🏆 Top Rated 2024',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Metrics Bar ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _ProfileMetricCard(
                    title: '4.9 ★',
                    subtitle: '142 reviews',
                    isStar: true,
                    onTap: () => context.push('/p/ratings'),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: _ProfileMetricCard(
                    title: '180+',
                    subtitle: 'Completed',
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: _ProfileMetricCard(
                    title: '99%',
                    subtitle: 'On-Time',
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: _ProfileMetricCard(
                    title: '7 Yrs',
                    subtitle: 'Experience',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── About Me Section ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HfColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'About Me',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: HfColors.navy,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_outlined, size: 18, color: HfColors.grey),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Friendly licensed master plumber serving Brooklyn and Greater NYC with over 7 years of residential leak repairs, fixture installations, and pipe restoration. Fully insured and equipped with professional emergency gear.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF475569),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBCE1F2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on, color: HfColors.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SERVICE COVERAGE',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: HfColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Brooklyn & Lower Manhattan (10 mi radius)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: HfColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Pricing Overview Section ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HfColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Pricing Overview',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: HfColors.navy,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_outlined, size: 18, color: HfColors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Price item 1
                  const _ProfilePricingCard(
                    title: 'Standard Diagnostic & 1st Hour',
                    subtitle: 'Includes equipment check & triage',
                    price: '\$45.00 / hr',
                  ),
                  const SizedBox(height: 10),
                  // Price item 2
                  const _ProfilePricingCard(
                    title: 'Emergency Response',
                    badge: '24/7',
                    subtitle: 'Burst pipes & urgent water shutoff',
                    price: '\$65.00 / hr',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Action Buttons ───────────────────────────────────────
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Profile details opened')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11768F),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Profile Information',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Previewing public customer view')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: HfColors.primary,
                side: const BorderSide(color: HfColors.primary),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Preview Public Customer View',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Metric Card ──────────────────────────────────────────────────
class _ProfileMetricCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isStar;
  final VoidCallback? onTap;

  const _ProfileMetricCard({
    required this.title,
    required this.subtitle,
    this.isStar = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HfColors.border),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isStar ? const Color(0xFFD97706) : HfColors.navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: HfColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Pricing Card ─────────────────────────────────────────────────
class _ProfilePricingCard extends StatelessWidget {
  final String title;
  final String? badge;
  final String subtitle;
  final String price;

  const _ProfilePricingCard({
    required this.title,
    this.badge,
    required this.subtitle,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HfColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: HfColors.navy,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          badge!,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: HfColors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: HfColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 35 — RATINGS & REVIEWS
// ═══════════════════════════════════════════════════════════════════════════

class ProviderRatingsScreen extends ConsumerStatefulWidget {
  const ProviderRatingsScreen({super.key});

  @override
  ConsumerState<ProviderRatingsScreen> createState() => _ProviderRatingsScreenState();
}

class LiveProviderRatingsScreen extends StatelessWidget {
  const LiveProviderRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please log in to view ratings.'));
    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('reviews').where('providerId', isEqualTo: uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Unable to load reviews.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final reviews = snapshot.data!.docs;
            final total = reviews.fold<double>(0, (sum, doc) => sum + ((doc.data()['rating'] as num?)?.toDouble() ?? 0));
            final average = reviews.isEmpty ? 0.0 : total / reviews.length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                HfScreenHeader(title: 'Ratings & Reviews', onBack: () => context.pop()),
                HfCard(child: Column(children: [
                  Text(average.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w900)),
                  HfStars(value: average),
                  Text('${reviews.length} verified reviews', style: const TextStyle(color: HfColors.muted)),
                ])),
                const SizedBox(height: 16),
                if (reviews.isEmpty) const HfCard(child: Text('No customer reviews yet.')),
                ...reviews.map((document) {
                  final data = document.data();
                  return HfCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text((data['customerName'] ?? 'Customer').toString(), style: const TextStyle(fontWeight: FontWeight.w700))),
                      HfStars(value: (data['rating'] as num?)?.toDouble() ?? 0),
                    ]),
                    const SizedBox(height: 8),
                    Text((data['comment'] ?? 'No written comment.').toString()),
                  ]));
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProviderRatingsScreenState extends ConsumerState<ProviderRatingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.session;

    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── Top Bar ──────────────────────────────────────────────
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/p/home');
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: HfColors.navy, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: HfColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: HfColors.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Reviews',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: HfColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: HfColors.primarySoft,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : const NetworkImage(
                          'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Header Title ─────────────────────────────────────────
            Text(
              'Ratings & Reviews',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: HfColors.navy,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Customer feedback and satisfaction ratings for ${user?.firstName ?? 'David Miller'}',
              style: GoogleFonts.inter(fontSize: 13, color: HfColors.grey),
            ),
            const SizedBox(height: 16),

            // ── Rating Summary Card ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HfColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '4.9',
                        style: GoogleFonts.inter(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: HfColors.navy,
                        ),
                      ),
                      Text(
                        ' /5.0',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: HfColors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (i) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on 142 verified customer reviews',
                    style: GoogleFonts.inter(fontSize: 12, color: HfColors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Progress bars
                  const _RatingBarRow(label: '5 ★', percent: 0.92, displayPercent: '92%'),
                  const SizedBox(height: 6),
                  const _RatingBarRow(label: '4 ★', percent: 0.07, displayPercent: '7%'),
                  const SizedBox(height: 6),
                  const _RatingBarRow(label: '3 ★', percent: 0.01, displayPercent: '1%'),
                  const SizedBox(height: 6),
                  const _RatingBarRow(label: '2 ★', percent: 0.00, displayPercent: '0%'),
                  const SizedBox(height: 6),
                  const _RatingBarRow(label: '1 ★', percent: 0.00, displayPercent: '0%'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Tag Chips Row (Positive Highlights) ──────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _RatingHighlightChip(icon: Icons.timer_outlined, label: '100% Punctual'),
                _RatingHighlightChip(icon: Icons.cleaning_services_outlined, label: 'Clean Workspace'),
                _RatingHighlightChip(icon: Icons.payments_outlined, label: 'Fair Cash Pricing'),
                _RatingHighlightChip(icon: Icons.thumb_up_alt_outlined, label: 'Polite & Professional'),
              ],
            ),
            const SizedBox(height: 20),

            // ── Customer Reviews List ────────────────────────────────
            Text(
              'Verified Customer Feedback',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: HfColors.navy,
              ),
            ),
            const SizedBox(height: 12),

            // Review Card 1 (Sarah Jenkins)
            _ReviewCardWidget(
              avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
              customerName: 'Sarah Jenkins',
              timeAgo: '2 hours ago',
              rating: '5.0 ★',
              serviceTag: '🔧 Pipe Leakage Repair',
              comment:
                  'David arrived exactly on time and fixed the under-sink pipe joint leak within 45 minutes! Left the kitchen spotless and the \$48 cash payment was smooth and honest. Highly recommended!',
              providerReply:
                  'Thank you Sarah! Glad we could fix it quickly before any water damage occurred. Cheers!',
            ),
            const SizedBox(height: 12),

            // Review Card 2 (Michael Chang)
            _ReviewCardWidget(
              avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
              customerName: 'Michael Chang',
              timeAgo: 'Yesterday',
              rating: '4.8 ★',
              serviceTag: '🚿 Drain Unclogging',
              comment:
                  'Very professional and responsive. Arrived equipped with all necessary plumbing rods and unclogged our shower drain in no time.',
              providerReply:
                  'Glad we could help clear it up so promptly! Don\'t hesitate to reach out if you notice any other flow issues.',
            ),
            const SizedBox(height: 12),

            // Review Card 3 (Elena Rostova)
            const _ReviewCardWidget(
              avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
              customerName: 'Elena Rostova',
              timeAgo: '3 days ago',
              rating: '5.0 ★',
              serviceTag: '🚰 Water Valve Installation',
              comment:
                  'David replaced the main shut-off valve quickly and cleanly. Tested water pressure thoroughly before finishing. Excellent craftsman!',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rating Bar Row ───────────────────────────────────────────────────────
class _RatingBarRow extends StatelessWidget {
  final String label;
  final double percent;
  final String displayPercent;

  const _RatingBarRow({
    required this.label,
    required this.percent,
    required this.displayPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: HfColors.navy,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: HfColors.field,
              valueColor: const AlwaysStoppedAnimation(HfColors.primary),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            displayPercent,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: HfColors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Rating Highlight Chip ────────────────────────────────────────────────
class _RatingHighlightChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RatingHighlightChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBCE1F2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: HfColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: HfColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Review Card Widget ───────────────────────────────────────────────────
class _ReviewCardWidget extends StatelessWidget {
  final String avatarUrl;
  final String customerName;
  final String timeAgo;
  final String rating;
  final String serviceTag;
  final String comment;
  final String? providerReply;

  const _ReviewCardWidget({
    required this.avatarUrl,
    required this.customerName,
    required this.timeAgo,
    required this.rating,
    required this.serviceTag,
    required this.comment,
    this.providerReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HfColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: HfColors.primarySoft,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customerName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: HfColors.navy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle,
                            color: Color(0xFF3B82F6), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          'Verified Customer',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: HfColors.grey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      timeAgo,
                      style: GoogleFonts.inter(fontSize: 11, color: HfColors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rating,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              serviceTag,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: HfColors.navy,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF334155),
              height: 1.45,
            ),
          ),
          if (providerReply != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: HfColors.primary, width: 3),
                  top: BorderSide(color: HfColors.border),
                  right: BorderSide(color: HfColors.border),
                  bottom: BorderSide(color: HfColors.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '💬 David Miller',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: HfColors.navy,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Pro Provider',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: HfColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    providerReply!,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: HfColors.grey,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 36 — SETTINGS
// ═══════════════════════════════════════════════════════════════════════════

class ProviderSettingsScreen extends ConsumerStatefulWidget {
  const ProviderSettingsScreen({super.key});

  @override
  ConsumerState<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends ConsumerState<ProviderSettingsScreen> {
  bool emergencyJobs = true;
  String travelBuffer = '30 mins';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.session;
    final displayName = user?.name.isNotEmpty == true ? user!.name : 'David Miller';

    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── Top Bar ──────────────────────────────────────────────
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/p/home');
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: HfColors.navy, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: HfColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.settings_outlined, color: HfColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Settings',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: HfColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: HfColors.primarySoft,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : const NetworkImage(
                          'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Profile Mini Header Card ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HfColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: HfColors.primarySoft,
                        backgroundImage: user?.avatarUrl != null
                            ? NetworkImage(user!.avatarUrl!)
                            : const NetworkImage(
                                'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: HfColors.navy,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F4FD),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFBCE1F2)),
                                  ),
                                  child: Text(
                                    '✓ Pro Active',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: HfColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Master Licensed Plumber • #NY-89219',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: HfColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 22, color: HfColors.border),
                  InkWell(
                    onTap: () => context.push('/p/profile'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 18, color: HfColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Manage Public Profile',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: HfColors.primary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right,
                              size: 18, color: HfColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Work & Dispatch Preferences ──────────────────────────
            Row(
              children: [
                Text(
                  'WORK & DISPATCH PREFERENCES',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: HfColors.grey,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Live Mode',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: HfColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HfColors.border),
              ),
              child: Column(
                children: [
                  // Row 1: Emergency Same-Day Jobs
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bolt_rounded,
                              color: Color(0xFFD97706), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Emergency Same-Day Jobs',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: HfColors.navy,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '+15% Surge',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Instant alerts for priority urgent dispatch',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: HfColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: emergencyJobs,
                          onChanged: (v) => setState(() => emergencyJobs = v),
                          activeTrackColor: HfColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: HfColors.border),
                  // Row 2: Travel Buffer Between Jobs
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F4FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.access_time_rounded,
                              color: HfColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Travel Buffer Between Jobs',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: HfColors.navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Prevents overlapping commute delays',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: HfColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: HfColors.field,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: HfColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: travelBuffer,
                              isDense: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 16, color: HfColors.navy),
                              items: ['15 mins', '30 mins', '45 mins', '60 mins']
                                  .map((String val) {
                                return DropdownMenuItem<String>(
                                  value: val,
                                  child: Text(
                                    val,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: HfColors.navy,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => travelBuffer = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Account & Security ───────────────────────────────────
            Text(
              'ACCOUNT & SECURITY',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: HfColors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HfColors.border),
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    iconBg: const Color(0xFFE8F4FD),
                    iconColor: HfColors.primary,
                    title: 'License & Insurance',
                    subtitle: 'Verified (Valid through Dec 2026)',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('License NY-89219 verified with NYC Dept of Buildings')),
                      );
                    },
                  ),
                  const Divider(height: 1, color: HfColors.border),
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    iconBg: const Color(0xFFE8F4FD),
                    iconColor: HfColors.primary,
                    title: 'Change Password & Security PIN',
                    subtitle: 'Updated 2 months ago',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Password security management opened')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Support & Legal ──────────────────────────────────────
            Text(
              'SUPPORT & LEGAL',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: HfColors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HfColors.border),
              ),
              child: Column(
                children: [
                  // Hotline
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.phone_outlined,
                              color: Color(0xFFD97706), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Pro Help & Emergency Hotline',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: HfColors.navy,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '24/7',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Priority phone line for technicians',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: HfColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Calling Pro Helpline: 1-800-555-PROS')),
                            );
                          },
                          icon: const Icon(Icons.call,
                              color: HfColors.primary, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: HfColors.border),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    iconBg: const Color(0xFFE8F4FD),
                    iconColor: HfColors.primary,
                    title: 'Terms of Service & Pro Guarantee',
                    subtitle: 'Review policy standards and covenants',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Pro Terms & Guarantee')),
                      );
                    },
                  ),
                  const Divider(height: 1, color: HfColors.border),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F4FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline,
                              color: HfColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Version',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: HfColors.navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'HomeFix Pro v2.4.1 (Build 412)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: HfColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F4FD),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Latest',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: HfColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Logout Action Button ─────────────────────────────────
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      'Log Out',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                    content: Text(
                      'Are you sure you want to log out of your HomeFix Pro account?',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(color: HfColors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(homefixStoreProvider.notifier).logout();
                          context.go('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Log Out of Pro Account',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings Tile ────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: HfColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: HfColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: HfColors.grey),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 37 — NOTIFICATIONS
// ═══════════════════════════════════════════════════════════════════════════

class ProviderNotificationsScreen extends ConsumerStatefulWidget {
  const ProviderNotificationsScreen({super.key});

  @override
  ConsumerState<ProviderNotificationsScreen> createState() =>
      _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState
    extends ConsumerState<ProviderNotificationsScreen> {
  String selectedFilter = 'All';
  bool urgentDismissed = false;
  bool notif1Read = false;
  bool notif2Read = false;
  bool notif3Read = false;

  int get unreadCount {
    int count = 0;
    if (!urgentDismissed && !notif1Read) count++;
    if (!notif2Read) count++;
    if (!notif3Read) count++;
    return count;
  }

  void markAllRead() {
    setState(() {
      notif1Read = true;
      notif2Read = true;
      notif3Read = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.session;

    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── Top Bar ──────────────────────────────────────────────
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/p/home');
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: HfColors.navy, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: HfColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_active_outlined,
                          color: HfColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Notifications',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: HfColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: HfColors.primarySoft,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : const NetworkImage(
                          'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Top Control Bar ──────────────────────────────────────
            Row(
              children: [
                Text(
                  'Inbox',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: HfColors.navy,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      '$unreadCount New',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: markAllRead,
                  child: Row(
                    children: [
                      const Icon(Icons.done_all,
                          size: 15, color: HfColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Mark all read',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: HfColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Filter Category Chips ────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Bookings', 'Messages', 'System']
                    .map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? HfColors.navy : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? HfColors.navy : HfColors.border,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? Colors.white : HfColors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Section: TODAY ───────────────────────────────────────
            Row(
              children: [
                Text(
                  'TODAY',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: HfColors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  'Updated just now',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: HfColors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Notification 1: Urgent Request Card
            if (!urgentDismissed &&
                (selectedFilter == 'All' || selectedFilter == 'Bookings'))
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HfColors.primary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: HfColors.primary.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B5F7A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt,
                          color: Color(0xFFF59E0B), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!notif1Read) ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3B82F6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  'New Urgent Request nearby!',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: HfColors.navy,
                                  ),
                                ),
                              ),
                              Text(
                                '5m ago',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: HfColors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pipe Leakage Repair at 742 Evergreen Terrace (1.2 mi away). Estimated cash payout: \$48.00',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => notif1Read = true);
                                  context.push('/p/requests');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B5F7A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Review Request',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_rounded,
                                        size: 13),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              TextButton(
                                onPressed: () =>
                                    setState(() => urgentDismissed = true),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Dismiss',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: HfColors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Notification 2: Cash Payment Confirmed
            if (selectedFilter == 'All' || selectedFilter == 'System')
              _NotifItemCard(
                icon: Icons.payments_outlined,
                iconBg: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF10B981),
                isUnread: !notif2Read,
                title: 'Cash Payment Confirmed #HF-8921',
                timeAgo: '1h ago',
                description:
                    'Your settlement of \$48.00 cash from Sarah Jenkins has been recorded to your daily register.',
                onTap: () => setState(() => notif2Read = true),
              ),

            // Notification 3: 5-Star Review Received
            if (selectedFilter == 'All' || selectedFilter == 'Bookings')
              _NotifItemCard(
                icon: Icons.star_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                isUnread: !notif3Read,
                title: '5-Star Review Received!',
                timeAgo: '2h ago',
                description:
                    'Sarah Jenkins left you a 5-star review: "David arrived exactly on time and fixed the stubborn leak with no mess left behind!"',
                onTap: () {
                  setState(() => notif3Read = true);
                  context.push('/p/ratings');
                },
              ),
            const SizedBox(height: 16),

            // ── Section: YESTERDAY ───────────────────────────────────
            if (selectedFilter == 'All' || selectedFilter == 'Messages') ...[
              Text(
                'YESTERDAY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: HfColors.grey,
                ),
              ),
              const SizedBox(height: 10),

              // Notification 4: Michael Chang Message
              InkWell(
                onTap: () => context.push('/p/chat'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HfColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: HfColors.primarySoft,
                        backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Michael Chang',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: HfColors.navy,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '4:15 PM',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: HfColors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '"Can you also check the second bathroom valve tomorrow?"',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Notif Item Card ──────────────────────────────────────────────────────
class _NotifItemCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool isUnread;
  final String title;
  final String timeAgo;
  final String description;
  final VoidCallback onTap;

  const _NotifItemCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.isUnread,
    required this.title,
    required this.timeAgo,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HfColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isUnread) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: HfColors.navy,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: HfColors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
