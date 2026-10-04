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
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, _, _) => const OnboardingScreen(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF2FF), Color(0xFFF6F8FF), Color(0xFFFFF6EC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top chips
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Pill(
                      text: 'CERTIFIED NETWORK',
                      bg: AppColors.chipBg,
                      fg: AppColors.primary,
                      size: 9,
                      bold: true,
                    ),
                    Pill(
                      icon: Icons.verified_outlined,
                      text: '100% Vetted',
                      size: 10,
                    ),
                  ],
                ),
              ),

              // Center logo block
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
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
                            child: const Icon(Icons.home_rounded,
                                size: 56, color: Colors.white),
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
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.bolt,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'HomeFix',
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 4, bottom: 14),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reliable Home Services, Just a Booking Away',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.grey),
                      ),
                      const SizedBox(height: 22),
                      const Pill(
                        icon: Icons.shield_outlined,
                        text: 'Care & Comfort Guaranteed',
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom section
              Text(
                'EVERYDAY SOLUTIONS',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ServiceChip(Icons.water_drop_outlined, 'Plumbing'),
                    _ServiceChip(Icons.bolt, 'Electrical'),
                    _ServiceChip(Icons.cleaning_services_outlined, 'Cleaning'),
                    _ServiceChip(Icons.build_outlined, 'Repairs'),
                    _ServiceChip(Icons.format_paint_outlined, 'Painting'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Animated progress bar
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 3),
                builder: (_, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 140,
                    height: 4,
                    child: LinearProgressIndicator(
                      value: v,
                      backgroundColor: AppColors.chipBg,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 6, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Opening your home dashboard...',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
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
  Widget build(BuildContext context) => Pill(
        icon: icon,
        text: text,
        bg: AppColors.chipBg,
        size: 11,
      );
}