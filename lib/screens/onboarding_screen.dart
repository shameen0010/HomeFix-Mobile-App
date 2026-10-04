import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF11768F);
  static const dark = Color(0xFF0F2A43);
  static const grey = Color(0xFF6B7A8D);
  static const bg = Color(0xFFF6F8FF);
  static const chipBg = Color(0xFFDCEBFA);
  static const orange = Color(0xFFF59E0B);
  static const green = Color(0xFF10B981);
}

/// Small rounded chip used on both splash and onboarding.
class Pill extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color bg;
  final Color fg;
  final double size;
  final bool bold;

  const Pill({
    super.key,
    required this.text,
    this.icon,
    this.bg = Colors.white,
    this.fg = AppColors.dark,
    this.size = 12,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: size + 3, color: AppColors.primary),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: size,
            color: fg,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ]),
    );
  }
}

class _PageData {
  final String title;
  final String? desc;
  final IconData icon;
  final List<(IconData, String)> chips;
  const _PageData(this.title, this.desc, this.icon, this.chips);
}

const _pages = <_PageData>[
  _PageData(
    'Find the Right Service',
    'Explore certified plumbers, electricians, cleaners, and appliance '
        'technicians tailored for your home needs in minutes.',
    Icons.search_rounded,
    [
      (Icons.verified_outlined, 'Verified Pricing'),
      (Icons.handyman_outlined, '50+ Home Services'),
    ],
  ),
  _PageData(
    'Choose Trusted Professionals',
    'Browse background-checked specialists with transparent reviews, '
        'ratings, and verified credentials to keep your home safe.',
    Icons.person_rounded,
    [
      (Icons.star_border_rounded, '4.8 Avg Rating'),
      (Icons.shield_outlined, 'Background Checked'),
    ],
  ),
  _PageData(
    'Book & Manage Easily',
    null,
    Icons.calendar_month_rounded,
    [
      (Icons.event_available_outlined, 'Instant Slot Booking'),
      (Icons.notifications_none_rounded, 'Real-time Updates'),
    ],
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  void _goLogin() {
    // TODO: replace with your login route / screen
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _next() {
    if (_isLast) {
      _goLogin();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _back() => _controller.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- FIXED TOP BAR ----------
            _TopBar(
              index: _index,
              onBack: _back,
              onSkip: _goLogin,
            ),

            // ---------- ONLY THIS PART SWIPES ----------
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _PageContent(data: _pages[i]),
              ),
            ),

            // ---------- FIXED BOTTOM SECTION ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : const Color(0xFFD0D5DD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLast ? 'Get Started' : 'Next',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Fixed height so the button never shifts
                  SizedBox(height: 24, child: Center(child: _bottomLink())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomLink() {
    final small = GoogleFonts.poppins(fontSize: 12, color: AppColors.grey);
    final link = GoogleFonts.poppins(
      fontSize: 12,
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );
    switch (_index) {
      case 0:
        return GestureDetector(
          onTap: _goLogin,
          child: Text('I already have an account',
              style: small.copyWith(color: AppColors.dark)),
        );
      case 1:
        return GestureDetector(
          onTap: () => _controller.animateToPage(0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic),
          child: Text('Back to Overview',
              style: small.copyWith(color: AppColors.dark)),
        );
      default:
        return GestureDetector(
          onTap: _goLogin,
          child: Text.rich(TextSpan(children: [
            TextSpan(text: 'Already have an account?  ', style: small),
            TextSpan(text: 'Log In', style: link),
          ])),
        );
    }
  }
}

class _TopBar extends StatelessWidget {
  final int index;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  const _TopBar({
    required this.index,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final skipStyle =
        GoogleFonts.poppins(fontSize: 13, color: AppColors.grey);

    final Widget back = index == 0
        ? const SizedBox(width: 44)
        : InkWell(
            onTap: onBack,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: AppColors.chipBg, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back,
                  size: 20, color: AppColors.dark),
            ),
          );

    final Widget center = switch (index) {
      0 => const Pill(
          icon: Icons.home_outlined,
          text: 'HOMEFIX',
          bg: AppColors.chipBg,
          fg: AppColors.primary,
          size: 10,
          bold: true,
        ),
      1 => const Pill(
          text: 'STEP 2 OF 3',
          bg: AppColors.chipBg,
          fg: AppColors.primary,
          size: 10,
          bold: true,
        ),
      _ => Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.work_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('HomeFix',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark)),
        ]),
    };

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // On page 0 the pill sits on the left, other pages have back button
            if (index == 0) center else back,
            if (index != 0) Expanded(child: Center(child: center)),
            if (index == 0) const Spacer(),
            TextButton(
              onPressed: onSkip,
              child: Text('Skip', style: skipStyle),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _PageData data;
  const _PageContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(flex: 5, child: Center(child: _Illustration(data.icon))),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 10),
          // Fixed-height description area so layout stays identical
          SizedBox(
            height: 72,
            child: data.desc == null
                ? null
                : Text(
                    data.desc!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.grey,
                    ),
                  ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in data.chips) Pill(icon: c.$1, text: c.$2),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Placeholder illustration. Replace with the SVG/PNG exported from Figma:
/// SvgPicture.asset('assets/images/onboarding_1.svg')
class _Illustration extends StatelessWidget {
  final IconData icon;
  const _Illustration(this.icon);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 240,
          height: 170,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(90, AppColors.dark),
                      const SizedBox(height: 6),
                      _bar(60, AppColors.primary),
                    ],
                  ),
                ),
              ]),
              const Spacer(),
              _bar(double.infinity, const Color(0xFFE5E9F2), h: 10),
              const SizedBox(height: 8),
              _bar(140, const Color(0xFFE5E9F2), h: 10),
              const SizedBox(height: 12),
              _bar(double.infinity, AppColors.primary, h: 18),
            ],
          ),
        ),
        const Positioned(
          top: -12,
          right: -12,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.green,
            child: Icon(Icons.check, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _bar(double w, Color c, {double h = 6}) => Container(
        width: w,
        height: h,
        decoration:
            BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
      );
}