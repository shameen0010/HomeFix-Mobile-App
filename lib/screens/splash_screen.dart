import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/hf_theme.dart';
import '../core/widgets/hf_widgets.dart';
import '../data/homefix_store.dart';
import '../data/models.dart';
import '../main.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      final state = ref.read(homefixStoreProvider);
      if (state.session != null) {
        context.go(homeFor(state.session!.role));
      } else if (state.onboardingDone) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF6FB), Color(0xFFFDF8F2), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const HfPill(label: 'CERTIFIED NETWORK', icon: Icons.circle, selected: false),
                    HfPill(label: '100% Vetted', icon: Icons.verified_outlined, color: HfColors.peach),
                  ],
                ),
                const Spacer(),
                const HfLogo(size: 92),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    text: 'HomeFix',
                    style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w800, color: HfColors.navy),
                    children: const [
                      TextSpan(text: ' •', style: TextStyle(color: HfColors.gold, fontSize: 22)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reliable Home Services, Just a Booking Away',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: HfColors.muted),
                ),
                const SizedBox(height: 16),
                const HfPill(label: 'Care & Comfort Guaranteed', icon: Icons.verified_user_outlined),
                const Spacer(),
                const Text('EVERYDAY SOLUTIONS', style: TextStyle(color: HfColors.muted, fontSize: 11, letterSpacing: 1.4)),
                const SizedBox(height: 12),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    HfPill(label: 'Plumbing', icon: Icons.plumbing),
                    HfPill(label: 'Electrical', icon: Icons.bolt_outlined),
                    HfPill(label: 'Cleaning', icon: Icons.cleaning_services_outlined),
                    HfPill(label: 'Repairs', icon: Icons.build_outlined),
                    HfPill(label: 'Painting', icon: Icons.format_paint_outlined),
                  ],
                ),
                const SizedBox(height: 28),
                Container(width: 86, height: 5, decoration: BoxDecoration(color: HfColors.primary, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 12),
                const Text('Opening your home dashboard...', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
