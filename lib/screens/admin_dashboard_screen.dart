import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/auth_widgets.dart';
import 'onboarding_screen.dart'; // AppColors

const _blueBg = Color(0xFFDCEBFA);
const _orangeBg = Color(0xFFFFE2B8);
const _orangeFg = Color(0xFFB45309);
const _peach = Color(0xFFFFE8CC);

// ============================================================
//  SHELL: page + bottom navigation
// ============================================================
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    (Icons.group_outlined, Icons.group, 'Users'),
    (Icons.calendar_month_outlined, Icons.calendar_month, 'Bookings'),
    (Icons.engineering_outlined, Icons.engineering, 'Operations'),
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Report'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: _tab == 0
            ? const _DashboardTab()
            : Center(
                child: Text('${_items[_tab].$3} — coming soon',
                    style: poppins(14, color: AppColors.grey)),
              ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tab = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            i == _tab ? _items[i].$2 : _items[i].$1,
                            size: 22,
                            color:
                                i == _tab ? AppColors.primary : AppColors.grey,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _items[i].$3,
                            style: poppins(
                              10,
                              w: i == _tab ? FontWeight.w600 : FontWeight.w400,
                              color:
                                  i == _tab ? AppColors.primary : AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  SAMPLE DATA (replace with Firestore later)
// ============================================================
class _Stat {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String badge;
  final int badgeKind; // 0 blue chip, 1 orange chip, 2 plain text
  final String value;
  final String suffix;
  final IconData? valueIcon;
  final String label;
  const _Stat(this.icon, this.iconBg, this.iconFg, this.badge, this.badgeKind,
      this.value, this.label,
      {this.suffix = '', this.valueIcon});
}

const _stats = [
  _Stat(Icons.groups_outlined, _blueBg, AppColors.primary, '+8.4%', 0,
      '14,280', 'Total Customers'),
  _Stat(Icons.verified_user_outlined, _blueBg, AppColors.primary, '32 pending',
      1, '1,840', 'Service Providers'),
  _Stat(Icons.calendar_today_outlined, _blueBg, AppColors.primary, 'All time',
      2, '28,450', 'Total Bookings'),
  _Stat(Icons.notifications_none_rounded, _peach, AppColors.orange,
      'Needs Action', 1, '42', 'Pending Bookings',
      suffix: ' dispatch'),
  _Stat(Icons.check_circle_outline, _blueBg, AppColors.primary, '94.5%', 0,
      '26,890', 'Completed (Success)'),
  _Stat(Icons.star_border_rounded, _peach, AppColors.orange, '12.4k rev.', 2,
      '4.8', 'Reviews & Rating',
      valueIcon: Icons.star_border_rounded),
];

class _Activity {
  final String title, time, sub;
  final String? initials;
  final IconData? icon;
  const _Activity(this.title, this.time, this.sub, {this.initials, this.icon});
}

const _activities = [
  _Activity('David Miller registered', '14m ago',
      'Master Plumber • Credentials submitted',
      initials: 'DM'),
  _Activity('Customer review flagged', '38m ago',
      'Service #HF-8840 • 2 Stars • Flagged for review',
      icon: Icons.flag_outlined),
];

// ============================================================
//  DASHBOARD TAB
// ============================================================
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AdminHeader(),
          const SizedBox(height: 18),
          const _OverviewRow(),
          const SizedBox(height: 16),

          // 2-column stat grid
          for (var i = 0; i < _stats.length; i += 2) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _StatCard(_stats[i])),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(_stats[i + 1])),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 4),
          const _ActionBanner(),
          const SizedBox(height: 14),
          const _ModerationCard(),
          const SizedBox(height: 20),
          const _RecentActivity(),
        ],
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('HomeFix', style: poppins(16, w: FontWeight.w700)),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _blueBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('ADMIN',
                      style: poppins(8.5,
                          color: AppColors.primary, w: FontWeight.w700)),
                ),
              ]),
              Text('Admin Dashboard',
                  style: poppins(11, color: AppColors.grey)),
            ],
          ),
        ),
        IconButton(
          onPressed: () {}, // TODO: notifications
          icon: const Icon(Icons.notifications_none_rounded,
              color: AppColors.dark),
        ),
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'logout') {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'logout',
              child: Row(children: [
                const Icon(Icons.logout, size: 18, color: AppColors.dark),
                const SizedBox(width: 8),
                Text('Log out', style: poppins(13)),
              ]),
            ),
          ],
          child: Container(
            width: 36,
            height: 36,
            decoration:
                const BoxDecoration(color: kDeepTeal, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline,
                color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EXECUTIVE SCOPE',
                  style: poppins(9,
                      color: AppColors.grey, w: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Platform Overview',
                  style: poppins(19, w: FontWeight.w700)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE3EEFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily GMV',
                    style: poppins(9,
                        color: AppColors.primary, w: FontWeight.w600)),
                Text('\$34,820', style: poppins(14, w: FontWeight.w700)),
              ],
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 44,
              height: 24,
              child: CustomPaint(painter: _SparkPainter()),
            ),
          ]),
        ),
      ],
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter();
  static const _pts = [0.15, 0.45, 0.3, 0.6, 0.5, 0.85, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < _pts.length; i++) {
      final x = size.width * i / (_pts.length - 1);
      final y = size.height * (1 - _pts[i]);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Chip(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(text,
            style: poppins(9.5, color: fg, w: FontWeight.w600)),
      );
}

class _StatCard extends StatelessWidget {
  final _Stat s;
  const _StatCard(this.s);

  Widget _badge() {
    switch (s.badgeKind) {
      case 0:
        return _Chip(s.badge, _blueBg, AppColors.primary);
      case 1:
        return _Chip(s.badge, _orangeBg, _orangeFg);
      default:
        return Text(s.badge, style: poppins(10, color: AppColors.grey));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: s.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(s.icon, size: 19, color: s.iconFg),
              ),
              _badge(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(s.value, style: poppins(24, w: FontWeight.w700)),
              if (s.suffix.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(s.suffix,
                    style: poppins(11,
                        color: AppColors.orange, w: FontWeight.w600)),
              ],
              if (s.valueIcon != null) ...[
                const SizedBox(width: 4),
                Icon(s.valueIcon, size: 18, color: AppColors.orange),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(s.label, style: poppins(11, color: AppColors.grey)),
        ],
      ),
    );
  }
}

class _ActionBanner extends StatelessWidget {
  const _ActionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE0B8), Color(0xFFFFF0DC)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_ind_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTION REQUIRED',
                    style: poppins(8.5,
                        color: _orangeFg, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('3 new provider verifications',
                    style: poppins(13, w: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {}, // TODO: open provider verification list
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B1A0B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Review Now',
                  style: poppins(11,
                      color: Colors.white, w: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 14),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ModerationCard extends StatelessWidget {
  const _ModerationCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _peach,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rate_review_outlined,
                    color: AppColors.orange, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text('Complaint & Review Moderation',
                            style: poppins(12.5, w: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      const _Chip('1 pending', _orangeBg, _orangeFg),
                    ]),
                    const SizedBox(height: 2),
                    Text('1 flagged review, 1 open dispute',
                        style: poppins(11, color: AppColors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {}, // TODO: open moderation list
          style: ElevatedButton.styleFrom(
            backgroundColor: kDeepTeal,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Moderate',
                style:
                    poppins(12, color: Colors.white, w: FontWeight.w600)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward, size: 15),
          ]),
        ),
      ],
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.history, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('Recent Activity', style: poppins(15, w: FontWeight.w700)),
          const Spacer(),
          const Icon(Icons.circle, size: 7, color: AppColors.green),
          const SizedBox(width: 5),
          Text('Live Feed',
              style: poppins(10,
                  color: AppColors.primary, w: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        for (final a in _activities) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: a.icon != null ? _peach : kSegOff,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: a.icon != null
                      ? Icon(a.icon, color: AppColors.orange, size: 22)
                      : Text(a.initials ?? '',
                          style: poppins(13,
                              color: AppColors.primary, w: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(a.title,
                              style: poppins(12.5, w: FontWeight.w700)),
                        ),
                        Text(a.time,
                            style: poppins(10, color: AppColors.grey)),
                      ]),
                      const SizedBox(height: 2),
                      Text(a.sub, style: poppins(11, color: AppColors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}