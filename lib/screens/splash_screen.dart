import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _openOnboarding);
  }

  void _openOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF2FF),
              Color(0xFFF7F9FF),
              Color(0xFFFFF6EC),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _TrustBadges(),
                    const SizedBox(height: 56),
                    const _HomeFixLogo(),
                    const SizedBox(height: 24),
                    Text(
                      'HomeFix.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Reliable Home Services, Just a Booking Away',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _GuaranteeBadge(),
                    const SizedBox(height: 64),
                    Text(
                      'EVERYDAY SOLUTIONS',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ServiceChip(Icons.water_drop_outlined, 'Plumbing'),
                        _ServiceChip(Icons.bolt, 'Electrical'),
                        _ServiceChip(
                          Icons.cleaning_services_outlined,
                          'Cleaning',
                        ),
                        _ServiceChip(Icons.build_outlined, 'Repairs'),
                        _ServiceChip(
                          Icons.format_paint_outlined,
                          'Painting',
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    const SizedBox(
                      width: 140,
                      height: 4,
                      child: _LoadingBar(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: AppColors.primary,
                        ),
                        Text(
                          'Opening your home dashboard...',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustBadges extends StatelessWidget {
  const _TrustBadges();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _Badge(
          text: 'CERTIFIED NETWORK',
          background: AppColors.chipBg,
          foreground: AppColors.primary,
          bold: true,
        ),
        _Badge(
          icon: Icons.verified_outlined,
          text: '100% Vetted',
        ),
      ],
    );
  }
}

class _HomeFixLogo extends StatelessWidget {
  const _HomeFixLogo();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B8FB5), Color(0xFF0B5F7A)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.home_rounded, size: 56, color: Colors.white),
        ),
        Positioned(
          right: -8,
          bottom: -8,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.bolt, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _GuaranteeBadge extends StatelessWidget {
  const _GuaranteeBadge();

  @override
  Widget build(BuildContext context) {
    return const _Badge(
      icon: Icons.shield_outlined,
      text: 'Care & Comfort Guaranteed',
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color background;
  final Color foreground;
  final bool bold;

  const _Badge({
    this.icon,
    required this.text,
    this.background = Colors.white,
    this.foreground = AppColors.grey,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 5,
          children: [
            if (icon != null)
              Icon(icon, size: 13, color: AppColors.primary),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: foreground,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, animation) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _controller.value,
          backgroundColor: AppColors.chipBg,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ServiceChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 5,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
