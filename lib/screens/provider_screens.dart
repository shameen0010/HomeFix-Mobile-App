import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/hf_theme.dart';
import '../core/widgets/hf_widgets.dart';
import '../data/homefix_store.dart';


// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER BOTTOM NAVIGATION SHELL
// ═══════════════════════════════════════════════════════════════════════════

const providerNav = [
  HfNavItem(Icons.dashboard_outlined, 'Dashboard'),
  HfNavItem(Icons.inbox_outlined, 'Requests'),
  HfNavItem(Icons.calendar_today_outlined, 'Schedule'),
  HfNavItem(Icons.chat_bubble_outline, 'Messages'),
  HfNavItem(Icons.more_horiz, 'More'),
];

class ProviderShell extends StatelessWidget {
  const ProviderShell({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: HfBottomNav(
        items: providerNav,
        index: index,
        onTap: (i) {
          context.go([
            '/p/home',
            '/p/requests',
            '/p/schedule',
            '/p/messages',
            '/p/more',
          ][i]);
        },
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
                onPressed: () {},
                icon: const Icon(Icons.home_outlined, color: HfColors.navy),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 16,
                backgroundColor: HfColors.primarySoft,
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Icon(Icons.person, color: HfColors.primary, size: 18)
                    : null,
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
            onViewDetails: () {},
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
            onViewDetails: () {},
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
                onTap: () {},
              ),
              _QuickAction(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {},
              ),
              _QuickAction(
                icon: Icons.star_outline,
                label: 'Ratings and\nReviews',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
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

const _mockChat = [
  _ChatMsg(
    sender: 'customer',
    text:
        'Hi David, just checking if you have any questions about the pipe leak under the kitchen sink?',
    time: '10:15 AM',
    senderName: 'Sarah',
  ),
  _ChatMsg(
    sender: 'provider',
    text:
        'Hi Sarah! I reviewed the photo you attached. It looks like the joint seal under the main valve. I have the replacement gaskets and fittings in my van.',
    time: '10:18 AM',
    senderName: 'You',
  ),
  _ChatMsg(
    sender: 'customer',
    text:
        'Great! I\'ve cleared the space under the sink. I have \$48 cash ready as requested.',
    time: '10:20 AM',
    senderName: 'Sarah',
  ),
  _ChatMsg(
    sender: 'provider',
    text:
        'Perfect, thank you! I am finishing up my previous stop and will head your way shortly.',
    time: '10:45 AM',
    senderName: 'You',
  ),
];

class ProviderChatScreen extends ConsumerStatefulWidget {
  const ProviderChatScreen({super.key});

  @override
  ConsumerState<ProviderChatScreen> createState() =>
      _ProviderChatScreenState();
}

class _ProviderChatScreenState extends ConsumerState<ProviderChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMsg> _messages = List.from(_mockChat);

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
                    child: Icon(Icons.person,
                        color: HfColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Sarah Jenkins',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: HfColors.navy,
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
                          'Customer • Oakridge Lane',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: HfColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CircleIconBtn(
                    icon: Icons.phone_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(width: 6),
                  _CircleIconBtn(
                    icon: Icons.info_outline,
                    onTap: () {},
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
                        'Booking #HF-8921 confirmed for Today at 11:30 AM',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: HfColors.primary,
                        ),
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
// PROVIDER PLACEHOLDER SCREENS (for bottom nav routes not yet built)
// ═══════════════════════════════════════════════════════════════════════════

class ProviderRequestsPlaceholder extends StatelessWidget {
  const ProviderRequestsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: HfColors.muted),
            const SizedBox(height: 12),
            Text('Booking Requests',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: HfColors.navy)),
            const SizedBox(height: 4),
            Text('No new requests at the moment.',
                style: GoogleFonts.inter(fontSize: 13, color: HfColors.grey)),
          ],
        ),
      ),
    );
  }
}

class ProviderSchedulePlaceholder extends StatelessWidget {
  const ProviderSchedulePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 48, color: HfColors.muted),
            const SizedBox(height: 12),
            Text('Schedule',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: HfColors.navy)),
            const SizedBox(height: 4),
            Text('Your schedule is clear today.',
                style: GoogleFonts.inter(fontSize: 13, color: HfColors.grey)),
          ],
        ),
      ),
    );
  }
}

class ProviderMessagesPlaceholder extends StatelessWidget {
  const ProviderMessagesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 48, color: HfColors.muted),
            const SizedBox(height: 12),
            Text('Messages',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: HfColors.navy)),
            const SizedBox(height: 4),
            Text('No active conversations.',
                style: GoogleFonts.inter(fontSize: 13, color: HfColors.grey)),
          ],
        ),
      ),
    );
  }
}

class ProviderMorePlaceholder extends StatelessWidget {
  const ProviderMorePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.more_horiz, size: 48, color: HfColors.muted),
            const SizedBox(height: 12),
            Text('More Options',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: HfColors.navy)),
            const SizedBox(height: 4),
            Text('Settings, profile, and more.',
                style: GoogleFonts.inter(fontSize: 13, color: HfColors.grey)),
          ],
        ),
      ),
    );
  }
}
