import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/hf_theme.dart';

import '../data/homefix_store.dart';

// ─── Data model for a service category tile ────────────────────────────────
class _ServiceCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ServiceCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

const _categories = [
  _ServiceCategory(
    id: 'plumber',
    title: 'Plumber',
    subtitle: 'Pipes, leaks & drains',
    icon: Icons.plumbing,
  ),
  _ServiceCategory(
    id: 'electrician',
    title: 'Electrician',
    subtitle: 'Wiring, fixtures & panel',
    icon: Icons.electrical_services,
  ),
  _ServiceCategory(
    id: 'cleaner',
    title: 'Cleaner',
    subtitle: 'Deep cleaning & turnover',
    icon: Icons.auto_awesome,
  ),
  _ServiceCategory(
    id: 'carpenter',
    title: 'Carpenter',
    subtitle: 'Furniture & woodwork',
    icon: Icons.carpenter,
  ),
  _ServiceCategory(
    id: 'painter',
    title: 'Painter',
    subtitle: 'Interior & exterior paint',
    icon: Icons.format_paint,
  ),
  _ServiceCategory(
    id: 'appliance_repair',
    title: 'Appliance Repair',
    subtitle: 'HVAC, fridge & oven',
    icon: Icons.build,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 2 — Select Category
// ═══════════════════════════════════════════════════════════════════════════

class SelectCategoryScreen extends ConsumerStatefulWidget {
  const SelectCategoryScreen({super.key});

  @override
  ConsumerState<SelectCategoryScreen> createState() =>
      _SelectCategoryScreenState();
}

class _SelectCategoryScreenState extends ConsumerState<SelectCategoryScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _selected = {};
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  String get _selectedLabel {
    if (_selected.isEmpty) return '';
    final names = _selected
        .map((id) => _categories.firstWhere((c) => c.id == id).title)
        .toList();
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} & ${names[1]}';
    return '${names.take(names.length - 1).join(', ')} & ${names.last}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: HfColors.navy),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B8FB5), Color(0xFF0B5F7A)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.home_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trade Credentials',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: HfColors.navy,
                    ),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: HfColors.primarySoft,
                    child: Icon(Icons.person,
                        color: HfColors.primary, size: 20),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ───────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  // Section header
                  Text(
                    'What service do you provide?',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: HfColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select the service you offer to customers.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: HfColors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Info notice
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: HfColors.info, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'You can select one or multiple services.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: HfColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Category Grid ──────────────────────────────────
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _categories.map((cat) {
                      final isSelected = _selected.contains(cat.id);
                      return _CategoryTile(
                        category: cat,
                        isSelected: isSelected,
                        onTap: () => _toggle(cat.id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Status Badge ───────────────────────────────────
                  if (_selected.isNotEmpty)
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF9C3),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: HfColors.warning,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: HfColors.warning.withValues(
                                          alpha: 0.3 +
                                              0.3 * _pulseController.value,
                                        ),
                                        blurRadius:
                                            4 + 4 * _pulseController.value,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Selected: ${_selected.length} service${_selected.length > 1 ? 's' : ''} chosen ($_selectedLabel)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  if (_selected.isEmpty)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: HfColors.field,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: HfColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: HfColors.muted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'No services selected yet',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: HfColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Verified Partner Banner ────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: HfColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: HfColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: HfColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.verified_user,
                              color: HfColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Partner Network',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: HfColors.navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Showcase certifications & insurance in the next step',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: HfColors.grey,
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

            // ── Bottom Action Area ───────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selected.isEmpty
                            ? null
                            : () {
                                // Store selected categories and navigate
                                context.go('/provider-onboard/complete',
                                    extra: _selected.toList());
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HfColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              HfColors.primary.withValues(alpha: 0.4),
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.6),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Continue  →',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You can add more specialty services later in your profile.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: HfColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
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

// ─── Category Tile Widget ──────────────────────────────────────────────────
class _CategoryTile extends StatefulWidget {
  final _ServiceCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE0F2FE)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? HfColors.primary
                  : HfColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: HfColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              if (!selected)
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
              // Icon row with checkmark
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected
                          ? HfColors.primary.withValues(alpha: 0.15)
                          : HfColors.field,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.category.icon,
                      color: selected ? HfColors.primary : HfColors.grey,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: selected ? 1.0 : 0.0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 250),
                      scale: selected ? 1.0 : 0.5,
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: HfColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Title
              Text(
                widget.category.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HfColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text(
                widget.category.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: HfColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 3 — Registration Complete
// ═══════════════════════════════════════════════════════════════════════════

class RegistrationCompleteScreen extends ConsumerWidget {
  final List<String>? selectedCategories;

  const RegistrationCompleteScreen({super.key, this.selectedCategories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(homefixStoreProvider);
    final user = store.session;

    // Determine primary specialty from selected categories
    final categories = selectedCategories ?? ['plumber'];
    final primaryCategory = _categories.firstWhere(
      (c) => c.id == categories.first,
      orElse: () => _categories.first,
    );

    final providerName = user?.name ?? 'David Miller';
    final providerEmail = user?.email ?? 'david@example.com';
    final providerPhone = user?.phone ?? '+1(555) 019-2834';

    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
              child: Row(
                children: [
                  const SizedBox(width: 48), // balance for centering
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B8FB5), Color(0xFF0B5F7A)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.home_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'HomeFix',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: HfColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: HfColors.primarySoft,
                    child: Icon(Icons.person,
                        color: HfColors.primary, size: 20),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  // Success icon with animated ring
                  Center(
                    child: _SuccessIcon(),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Registration Complete!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: HfColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your service provider account has been\ncreated successfully.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: HfColors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: HfColors.primarySoft,
                              backgroundImage: user?.avatarUrl != null
                                  ? NetworkImage(user!.avatarUrl!)
                                  : null,
                              child: user?.avatarUrl == null
                                  ? Text(
                                      providerName.isNotEmpty
                                          ? providerName[0]
                                          : 'D',
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: HfColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        providerName,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: HfColors.navy,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: HfColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Pro',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    providerEmail,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: HfColors.grey,
                                    ),
                                  ),
                                  Text(
                                    providerPhone,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: HfColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: HfColors.border, height: 1),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(Icons.star, color: HfColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Primary Specialty',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: HfColors.grey,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: HfColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
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
                                    'Active & Ready',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: HfColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Master ${primaryCategory.title}',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: HfColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // What you get next
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                          'WHAT YOU GET NEXT',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: HfColors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _BenefitRow(
                          icon: Icons.check_circle,
                          text:
                              'Instant access to local customer booking leads',
                        ),
                        const SizedBox(height: 10),
                        _BenefitRow(
                          icon: Icons.check_circle,
                          text:
                              'Set your own rates and weekly working hours',
                        ),
                        const SizedBox(height: 10),
                        _BenefitRow(
                          icon: Icons.check_circle,
                          text:
                              'Collect direct cash settlements per completed job',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),

            // ── Bottom CTA ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(homefixStoreProvider.notifier)
                          .completeOnboarding();
                      context.go('/p/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HfColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Go to Dashboard  →',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Success animated icon ─────────────────────────────────────────────────
class _SuccessIcon extends StatefulWidget {
  @override
  State<_SuccessIcon> createState() => _SuccessIconState();
}

class _SuccessIconState extends State<_SuccessIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _rotate = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Transform.rotate(
            angle: _rotate.value,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B8FB5), Color(0xFF0B5F7A)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: HfColors.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Benefit row widget ────────────────────────────────────────────────────
class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: HfColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: HfColors.navy,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
