import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/hf_theme.dart';
import '../data/homefix_store.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 38 — ACTIVE SERVICE TRACKER
// ═══════════════════════════════════════════════════════════════════════════

class ProviderActiveServiceScreen extends ConsumerStatefulWidget {
  const ProviderActiveServiceScreen({super.key});

  @override
  ConsumerState<ProviderActiveServiceScreen> createState() =>
      _ProviderActiveServiceScreenState();
}

class _ProviderActiveServiceScreenState
    extends ConsumerState<ProviderActiveServiceScreen> {
  // Checklist states
  bool step1 = true;
  bool step2 = true;
  bool step3 = false;
  bool step4 = false;

  int get doneCount =>
      (step1 ? 1 : 0) + (step2 ? 1 : 0) + (step3 ? 1 : 0) + (step4 ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.session;

    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // ── Top Bar ──────────────────────────────────────────
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
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: HfColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.home_repair_service_outlined,
                                color: HfColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Active Service Time',
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
                  const SizedBox(height: 14),

                  // ── Active Job Tag ───────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live Job: #HF-8921',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: HfColors.navy,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBCE1F2)),
                        ),
                        child: Text(
                          '⚡ IN REAL-TIME',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: HfColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Progress Stepper Tracker ─────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HfColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStepItem(
                          icon: Icons.check,
                          label: 'En Route',
                          isDone: true,
                          isActive: false,
                        ),
                        _buildStepConnector(isDone: true),
                        _buildStepItem(
                          icon: Icons.check,
                          label: 'Arrived',
                          isDone: true,
                          isActive: false,
                        ),
                        _buildStepConnector(isDone: true),
                        _buildStepItem(
                          icon: Icons.build_rounded,
                          label: 'Working',
                          isDone: false,
                          isActive: true,
                        ),
                        _buildStepConnector(isDone: false),
                        _buildStepItem(
                          icon: Icons.flag_outlined,
                          label: 'Done',
                          isDone: false,
                          isActive: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Customer Info Card ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HfColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 22,
                              backgroundColor: HfColors.primarySoft,
                              backgroundImage: NetworkImage(
                                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100'),
                            ),
                            const SizedBox(width: 12),
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F4FD),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Verified',
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
                                    'Pipe Leakage Repair',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: HfColors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: HfColors.primary, size: 13),
                                      const SizedBox(width: 3),
                                      Text(
                                        '742 Evergreen Terrace, Apt 4B',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: HfColors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Calling +1 (555) 234-5678...')),
                                  );
                                },
                                icon: const Icon(Icons.phone_outlined,
                                    size: 16, color: HfColors.navy),
                                label: Text(
                                  'Call Customer',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: HfColors.navy,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side:
                                      const BorderSide(color: HfColors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => context.push('/p/chat'),
                                icon: const Icon(Icons.chat_bubble_outline,
                                    size: 16, color: Colors.white),
                                label: Text(
                                  'In-App Chat',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HfColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Service Checklist Card ───────────────────────────
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
                              'Service Checklist',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: HfColors.navy,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4FD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$doneCount/4 Done',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: HfColors.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Mandatory Protocol',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: HfColors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCheckItem(
                          title: 'Shut off main water valve',
                          isChecked: step1,
                          onChanged: (v) => setState(() => step1 = v!),
                        ),
                        _buildCheckItem(
                          title: 'Inspect cracked pipe joint',
                          isChecked: step2,
                          onChanged: (v) => setState(() => step2 = v!),
                        ),
                        _buildCheckItem(
                          title: 'Replace rubber gasket & tighten fitting',
                          isChecked: step3,
                          onChanged: (v) => setState(() => step3 = v!),
                        ),
                        _buildCheckItem(
                          title: 'Pressure test & check for leaks',
                          isChecked: step4,
                          onChanged: (v) => setState(() => step4 = v!),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Camera & inspection note photo sheet opened')),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4FD),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFBCE1F2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_outlined,
                                    size: 16, color: HfColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Add Inspection Note / Photo',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: HfColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Attached Documentation ───────────────────────────
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
                              'Attached Documentation',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: HfColors.navy,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4FD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '2 Uploaded',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: HfColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildThumbItem(
                                imageUrl:
                                    'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=250',
                                label: 'Before fix',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildThumbItem(
                                imageUrl:
                                    'https://images.unsplash.com/photo-1542013936693-884638332954?w=250',
                                label: 'Part replacement',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Cash Collection Notice Banner ────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet_outlined,
                              color: Color(0xFFD97706), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cash Collection Required',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Collect exactly \$48.00 in cash from Sarah Jenkins upon finishing inspection.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFFB45309),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Sticky Bottom Action Area ──────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: HfColors.border),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Settlement total due:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: HfColors.grey,
                        ),
                      ),
                      Text(
                        '\$48.00 USD',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: HfColors.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/p/job-receipt');
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
                    child: Text(
                      '✓ Complete Job & Collect Cash',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildStepItem({
    required IconData icon,
    required String label,
    required bool isDone,
    required bool isActive,
  }) {
    Color bg = isDone
        ? const Color(0xFF11768F)
        : (isActive ? const Color(0xFFF59E0B) : const Color(0xFFF1F5F9));
    Color iconColor =
        isDone || isActive ? Colors.white : const Color(0xFF94A3B8);

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    width: 3)
                : null,
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight:
                isDone || isActive ? FontWeight.w700 : FontWeight.w500,
            color: isDone || isActive ? HfColors.navy : HfColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 16),
        color: isDone ? const Color(0xFF11768F) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildCheckItem({
    required String title,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isChecked,
              onChanged: onChanged,
              activeColor: HfColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
                color: isChecked ? HfColors.navy : const Color(0xFF475569),
                decoration:
                    isChecked ? TextDecoration.none : TextDecoration.none,
              ),
            ),
          ),
          Icon(
            isChecked ? Icons.check_circle : Icons.remove_circle_outline,
            size: 16,
            color: isChecked ? HfColors.primary : HfColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildThumbItem({required String imageUrl, required String label}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Image.network(
            imageUrl,
            height: 90,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 39 — JOB DETAILS (POST-JOB CASH RECEIPT)
// ═══════════════════════════════════════════════════════════════════════════

class ProviderJobDetailsReceiptScreen extends ConsumerStatefulWidget {
  const ProviderJobDetailsReceiptScreen({super.key});

  @override
  ConsumerState<ProviderJobDetailsReceiptScreen> createState() =>
      _ProviderJobDetailsReceiptScreenState();
}

class _ProviderJobDetailsReceiptScreenState
    extends ConsumerState<ProviderJobDetailsReceiptScreen> {
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
                      const Icon(Icons.receipt_long_outlined,
                          color: HfColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Job Details',
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

            // ── Settlement Summary Hero Box ──────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F4FD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_outlined,
                        color: HfColors.primary, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total Direct Settlement',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HfColors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$48.00',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: HfColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      '💵 Cash Payment on Site',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Customer Brief Card ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HfColors.border),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: HfColors.primarySoft,
                    backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sarah Jenkins',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: HfColors.navy,
                          ),
                        ),
                        Text(
                          'Verified Homeowner • 742 Evergreen Way',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: HfColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Job Breakdown Section ────────────────────────────────
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pipe Leakage Repair',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: HfColors.navy,
                        ),
                      ),
                      Text(
                        'Job #HF-8921',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: HfColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: HfColors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Completed Today at 12:15 PM (45m)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: HfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Inspection Proof Gallery ─────────────────────────────
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
                        '📷 Inspection Proof',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: HfColors.navy,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '2 Photos Attached',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: HfColors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Image.network(
                                'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=250',
                                height: 95,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Repaired Valve',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Image.network(
                                'https://images.unsplash.com/photo-1542013936693-884638332954?w=250',
                                height: 95,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Pressure Test OK',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Workmanship Guarantee Banner ─────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HomeFix 30-Day Guarantee',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Full workmanship warranty automatically issued to customer upon receipt submission.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFFB45309),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Provider Confirmation Box ────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBCE1F2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'I, $displayName, confirm that I have physically received \$48.00 cash from Sarah Jenkins for completed repair work.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HfColors.navy,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This entry will reconcile your daily cash register and close the service ticket.',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: HfColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Action Buttons Area ──────────────────────────────────
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      'Receipt Confirmed',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                    content: Text(
                      'Job #HF-8921 has been marked settled and closed. \$48.00 cash logged into your register.',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/p/home');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HfColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
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
              child: Text(
                '✓ Confirm Receipt & Close Job',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Digital receipt sent to customer via email/SMS')),
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
              child: Text(
                '✉ Send Digital Receipt to Customer',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/p/home'),
              child: Text(
                'Back to Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HfColors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 40 — ACCEPT BOOKING REQUEST
// ═══════════════════════════════════════════════════════════════════════════

class ProviderRequestsScreen extends ConsumerStatefulWidget {
  const ProviderRequestsScreen({super.key});

  @override
  ConsumerState<ProviderRequestsScreen> createState() =>
      _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState
    extends ConsumerState<ProviderRequestsScreen> {
  String selectedFilter = 'Pending';
  bool card1Declined = false;
  bool card2Declined = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.session;

    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // ── Top Bar ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      const SizedBox(width: 4),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                IconButton(
                  onPressed: () => context.push('/p/notifications'),
                  icon: const Icon(Icons.notifications_outlined,
                      color: HfColors.navy, size: 22),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.push('/p/profile'),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: HfColors.primarySoft,
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : const NetworkImage(
                            'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Review and dispatch incoming customer orders',
                  style: GoogleFonts.inter(fontSize: 12, color: HfColors.grey),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⚡ STREAM',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: HfColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Filter Tabs ──────────────────────────────────────────
            Row(
              children: [
                _buildFilterTab(
                    label: 'Pending (2)', value: 'Pending', count: 2),
                const SizedBox(width: 8),
                _buildFilterTab(
                    label: 'Accepted (4)', value: 'Accepted', count: 4),
                const SizedBox(width: 8),
                _buildFilterTab(
                    label: 'Declined (1)', value: 'Declined', count: 1),
              ],
            ),
            const SizedBox(height: 14),

            // ── Alert Header Banner ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBCE1F2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: HfColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Immediate attention requested - Fast responses boost your pro acceptance rank by +15%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: HfColors.primary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Pending Request Card 1 (Urgent) ──────────────────────
            if (!card1Declined && selectedFilter == 'Pending')
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '❗ URGENT JOB',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: HfColors.field,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'In 45 mins',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: HfColors.grey,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$48.00',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: HfColors.navy,
                              ),
                            ),
                            Text(
                              'Cash on completion',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                color: HfColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Customer Row
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: HfColors.primarySoft,
                          backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sarah Jenkins ★ 5.0',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: HfColors.navy,
                                ),
                              ),
                              Text(
                                'Verified Homeowner • 3 past bookings',
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
                    const SizedBox(height: 10),

                    // Job Title
                    Text(
                      '🔧 Pipe Leakage Repair • Diagnostic & Repair',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: HfColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 13, color: HfColors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Today, Oct 16 • 11:30 AM',
                          style: GoogleFonts.inter(
                              fontSize: 11.5, color: HfColors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: HfColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '742 Evergreen Terrace, Apt 4B, Brooklyn • 1.2 miles away • ~5 min drive',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: HfColors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Customer Note Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        '"Under-sink leak near valve, water pooling quickly since this morning..."',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Action buttons
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => card1Declined = true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            '✕ Decline',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.push('/p/booking-request');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF11768F),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              '✓ Accept Job',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // ── Pending Request Card 2 (Tomorrow) ────────────────────
            if (!card2Declined && selectedFilter == 'Pending')
              Container(
                margin: const EdgeInsets.only(bottom: 14),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F4FD),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TOMORROW',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: HfColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$65.00',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: HfColors.navy,
                              ),
                            ),
                            Text(
                              'Cash on completion',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                color: HfColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: HfColors.primarySoft,
                          backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Carlos Mendez ★ 4.8',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: HfColors.navy,
                                ),
                              ),
                              Text(
                                '215 Atlantic Ave, Brooklyn • 2.4 miles away • ~15 min drive',
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => card2Declined = true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            '✕ Decline',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Job accepted! Added to tomorrow schedule.')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF11768F),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              '✓ Accept Job',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
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
    );
  }

  Widget _buildFilterTab({
    required String label,
    required String value,
    required int count,
  }) {
    final isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F2A43) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F2A43) : HfColors.border,
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
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 41 — SCHEDULED BOOKINGS
// ═══════════════════════════════════════════════════════════════════════════

class ProviderScheduleScreen extends ConsumerStatefulWidget {
  const ProviderScheduleScreen({super.key});

  @override
  ConsumerState<ProviderScheduleScreen> createState() =>
      _ProviderScheduleScreenState();
}

class _ProviderScheduleScreenState
    extends ConsumerState<ProviderScheduleScreen> {
  int viewMode = 0; // 0: Schedule, 1: Calendar
  String dateFilter = 'Today';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.session;

    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // ── Top Bar ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B8FB5), Color(0xFF0B5F7A)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month,
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
                      const SizedBox(width: 4),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                IconButton(
                  onPressed: () => context.push('/p/notifications'),
                  icon: const Icon(Icons.notifications_outlined,
                      color: HfColors.navy, size: 22),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.push('/p/profile'),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: HfColors.primarySoft,
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : const NetworkImage(
                            'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Section Title & Badge ────────────────────────────────
            Row(
              children: [
                Text(
                  'Upcoming Bookings',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: HfColors.navy,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    '5 Confirmed',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.tune_rounded, color: HfColors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 14),

            // ── View Mode Switcher Buttons ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => viewMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: viewMode == 0
                            ? const Color(0xFF11768F)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: viewMode == 0
                              ? const Color(0xFF11768F)
                              : HfColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.format_list_bulleted,
                              size: 16,
                              color: viewMode == 0
                                  ? Colors.white
                                  : HfColors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Schedule (5)',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: viewMode == 0
                                  ? Colors.white
                                  : HfColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => viewMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: viewMode == 1
                            ? const Color(0xFF11768F)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: viewMode == 1
                              ? const Color(0xFF11768F)
                              : HfColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 16,
                              color: viewMode == 1
                                  ? Colors.white
                                  : HfColors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Calendar View',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: viewMode == 1
                                  ? Colors.white
                                  : HfColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Date Filter Chips ────────────────────────────────────
            Row(
              children: [
                _buildDateChip('✓ Today (2)', 'Today'),
                const SizedBox(width: 8),
                _buildDateChip('Tomorrow (1)', 'Tomorrow'),
                const SizedBox(width: 8),
                _buildDateChip('This Week (2)', 'Week'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: HfColors.border),
                  ),
                  child: const Icon(Icons.date_range,
                      size: 18, color: HfColors.navy),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Date Header Banner ───────────────────────────────────
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'TODAY • WEDNESDAY, OCT 16',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: HfColors.grey,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '2 Jobs',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: HfColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Scheduled Booking Card 1 (NEXT UP) ───────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Time
                SizedBox(
                  width: 60,
                  child: Column(
                    children: [
                      Text(
                        '11:30',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: HfColors.navy,
                        ),
                      ),
                      Text(
                        'AM',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: HfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HfColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
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
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4FD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Next Up',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: HfColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Confirmed • Starts in 45m',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: HfColors.primarySoft,
                              backgroundImage: NetworkImage(
                                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sarah Jenkins ✓',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: HfColors.navy,
                                    ),
                                  ),
                                  Text(
                                    'Homeowner • Verified',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: HfColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.phone_outlined,
                                  size: 18, color: HfColors.primary),
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              onPressed: () => context.push('/p/chat'),
                              icon: const Icon(Icons.chat_bubble_outline,
                                  size: 18, color: HfColors.primary),
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '🔧 Pipe Leakage Repair',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: HfColors.navy,
                          ),
                        ),
                        Text(
                          'Under-sink leak in main kitchen',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: HfColors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: HfColors.primary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '742 Evergreen Terrace, Apt 4B • 1.2 mi away • Approx. 7 mins drive',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: HfColors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '💵 Cash on completion',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: HfColors.grey,
                              ),
                            ),
                            Text(
                              '\$48.00',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: HfColors.navy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  context.push('/p/active-service');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF11768F),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: Text(
                                  'Start Job',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                context.push('/p/customer-details');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: HfColors.navy,
                                side: const BorderSide(color: HfColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: Text(
                                'Job Details',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Scheduled Booking Card 2 ─────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60,
                  child: Column(
                    children: [
                      Text(
                        '2:30',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: HfColors.navy,
                        ),
                      ),
                      Text(
                        'PM',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: HfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HfColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '✓ Confirmed',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: HfColors.primarySoft,
                              backgroundImage: NetworkImage(
                                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Michael Chang ✓',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: HfColors.navy,
                                    ),
                                  ),
                                  Text(
                                    'Verified Resident',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: HfColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.phone_outlined,
                                  size: 18, color: HfColors.primary),
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              onPressed: () => context.push('/p/chat'),
                              icon: const Icon(Icons.chat_bubble_outline,
                                  size: 18, color: HfColors.primary),
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '2.4 mi away • Approx. 14 mins drive',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: HfColors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cash on completion',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: HfColors.grey,
                              ),
                            ),
                            Text(
                              '\$65.00',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: HfColors.navy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                context.push('/p/booking-request'),
                            child: Text(
                              'View Details >',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: HfColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, String value) {
    final isSelected = dateFilter == value;
    return GestureDetector(
      onTap: () => setState(() => dateFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F2A43) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F2A43) : HfColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : HfColors.grey,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 42 — CUSTOMER DETAILS
// ═══════════════════════════════════════════════════════════════════════════

class ProviderCustomerDetailsScreen extends ConsumerStatefulWidget {
  const ProviderCustomerDetailsScreen({super.key});

  @override
  ConsumerState<ProviderCustomerDetailsScreen> createState() =>
      _ProviderCustomerDetailsScreenState();
}

class _ProviderCustomerDetailsScreenState
    extends ConsumerState<ProviderCustomerDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.session;

    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // ── Top Bar ──────────────────────────────────────────
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
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Customer Details',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: HfColors.navy,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => context.go('/p/home'),
                        icon: const Icon(Icons.home_outlined,
                            color: HfColors.navy, size: 22),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      const SizedBox(width: 4),
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

                  // ── Customer Profile Hero Card ───────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HfColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 26,
                              backgroundColor: HfColors.primarySoft,
                              backgroundImage: NetworkImage(
                                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120'),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Sarah Jenkins',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: HfColors.navy,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F4FD),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Homeowner',
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
                                    'Verified Homeowner since 2022',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: HfColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/p/chat'),
                          icon: const Icon(Icons.chat_bubble_outline,
                              size: 16, color: Colors.white),
                          label: Text(
                            'Message Sarah',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF11768F),
                            minimumSize: const Size.fromHeight(42),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Booking Reference Container ──────────────────────
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'BOOKING ID #HF-8921',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: HfColors.grey,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '• CONFIRMED',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF047857),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '🔧 Pipe Leakage Repair',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: HfColors.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Today, Oct 16 • 11:30 AM (45–60 mins)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: HfColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Service Location Card ────────────────────────────
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
                            const Icon(Icons.location_on_outlined,
                                color: HfColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Service Location',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: HfColors.navy,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '1.2 mi • ~8 min',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: HfColors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '742 Evergreen Terrace, Apt 4B, Brooklyn, NY 11201',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF334155),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Access & Entry Instructions ──────────────────────
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
                        Text(
                          '🔑 ACCESS & ENTRY INSTRUCTIONS',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: HfColors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            '"Ring bell 4B, apartment is on 4th floor. Main shutoff valve is under the sink or in basement."',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF92400E),
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ⓘ Building has service elevator in rear alley if needed.',
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
            ),

            // ── Bottom Sticky Action Button ────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: HfColors.border),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  context.push('/p/active-service');
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
                child: Text(
                  '🏃‍♂️ Start Trip to Customer',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 43 — PROVIDER BOOKING HISTORY
// ═══════════════════════════════════════════════════════════════════════════

class ProviderBookingHistoryScreen extends ConsumerStatefulWidget {
  const ProviderBookingHistoryScreen({super.key});

  @override
  ConsumerState<ProviderBookingHistoryScreen> createState() =>
      _ProviderBookingHistoryScreenState();
}

class _ProviderBookingHistoryScreenState
    extends ConsumerState<ProviderBookingHistoryScreen> {
  String selectedFilter = 'All';

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
                      const Icon(Icons.history_outlined,
                          color: HfColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Booking History',
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

            // ── Filter Category Chips ────────────────────────────────
            Row(
              children: [
                _buildFilterChip('All (184)', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('This Month (18)', 'Month'),
                const SizedBox(width: 8),
                _buildFilterChip('Plumbing (142)', 'Plumbing'),
              ],
            ),
            const SizedBox(height: 18),

            // ── Section Header ───────────────────────────────────────
            Row(
              children: [
                Text(
                  'Recent Services',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HfColors.navy,
                  ),
                ),
                const Spacer(),
                Text(
                  'SORTED BY DATE',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: HfColors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── History Item 1 ───────────────────────────────────────
            _buildHistoryCard(
              customerName: 'Sarah Jenkins #HF-8921',
              status: 'Settled & Closed',
              avatarUrl:
                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
              address: '742 Evergreen Terrace, Brooklyn',
              jobTitle: 'Pipe Leakage Repair',
              price: '\$48.00',
              date: 'Today, Oct 16 • 12:15 PM',
              paymentTag: '💵 Cash Collected',
              review: '5.0 ★ "Super fast and clean work!"',
              onViewReceipt: () => context.push('/p/job-receipt'),
              hasRepeatNote: true,
            ),
            const SizedBox(height: 14),

            // ── History Item 2 ───────────────────────────────────────
            _buildHistoryCard(
              customerName: 'Marcus Vance #HF-8910',
              status: 'Settled',
              avatarUrl:
                  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
              address: '318 Atlantic Ave, Brooklyn',
              jobTitle: 'Drain Unclogging & Snaking',
              price: '\$65.00',
              date: 'Yesterday, Oct 15 • 03:30 PM',
              paymentTag: '💵 Cash Collected',
              review: '5.0 ★ "Saved my kitchen sink before dinner."',
              onViewReceipt: () => context.push('/p/job-receipt'),
              hasRepeatNote: false,
            ),
            const SizedBox(height: 14),

            // ── History Item 3 ───────────────────────────────────────
            _buildHistoryCard(
              customerName: 'Lisa Wong #HF-8894',
              status: 'Settled',
              avatarUrl:
                  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100',
              address: '55 Court St, Brooklyn',
              jobTitle: 'Faucet & Fixture Replacement',
              price: '\$55.00',
              date: 'Oct 14 • 10:00 AM',
              paymentTag: '💵 Cash Collected',
              review: '4.8 ★ "Great service and punctuality"',
              onViewReceipt: () => context.push('/p/job-receipt'),
              hasRepeatNote: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F2A43) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F2A43) : HfColors.border,
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

  Widget _buildHistoryCard({
    required String customerName,
    required String status,
    required String avatarUrl,
    required String address,
    required String jobTitle,
    required String price,
    required String date,
    required String paymentTag,
    required String review,
    required VoidCallback onViewReceipt,
    required bool hasRepeatNote,
  }) {
    return Container(
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
                    Text(
                      customerName,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: HfColors.navy,
                      ),
                    ),
                    Text(
                      address,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: HfColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                jobTitle,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: HfColors.navy,
                ),
              ),
              Text(
                price,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: HfColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 13, color: HfColors.grey),
              const SizedBox(width: 4),
              Text(
                date,
                style: GoogleFonts.inter(fontSize: 11.5, color: HfColors.grey),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  paymentTag,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: HfColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HfColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    review,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
                const Icon(Icons.verified_outlined,
                    size: 14, color: HfColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewReceipt,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HfColors.primary,
                    side: const BorderSide(color: HfColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'View Cash Receipt',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (hasRepeatNote) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Viewing job notes')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HfColors.navy,
                      side: const BorderSide(color: HfColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Repeat Job Note',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN 44 — BOOKING REQUEST (JOB DETAILS REVIEW)
// ═══════════════════════════════════════════════════════════════════════════

class ProviderBookingRequestDetailScreen extends ConsumerStatefulWidget {
  const ProviderBookingRequestDetailScreen({super.key});

  @override
  ConsumerState<ProviderBookingRequestDetailScreen> createState() =>
      _ProviderBookingRequestDetailScreenState();
}

class _ProviderBookingRequestDetailScreenState
    extends ConsumerState<ProviderBookingRequestDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.session;

    return Scaffold(
      backgroundColor: HfColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // ── Top Bar ──────────────────────────────────────────
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
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Job Details',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: HfColors.navy,
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

                  // ── Request Status Header Card ───────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HfColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Request ID #HF-8921',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: HfColors.navy,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '• Pending',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Timer Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_top_rounded,
                                  color: Color(0xFFD97706), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pending Acceptance',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF92400E),
                                      ),
                                    ),
                                    Text(
                                      'Expires in 02:53',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFDE68A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bolt,
                                    color: Color(0xFFD97706), size: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Client Profile Card ──────────────────────────────
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
                              'CLIENT PROFILE',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: HfColors.grey,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Verified Resident',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF047857),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: HfColors.primarySoft,
                              backgroundImage: NetworkImage(
                                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sarah Jenkins',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: HfColors.navy,
                                    ),
                                  ),
                                  Text(
                                    'Member since 2022 • ★ 4.9 (18 repairs)',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: HfColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.push('/p/chat'),
                              icon: const Icon(Icons.chat_bubble_outline,
                                  color: HfColors.primary, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Service Overview Card ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HfColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F4FD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.build_rounded,
                              color: HfColors.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Pipe Leakage Repair',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: HfColors.navy,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F4FD),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Standard Task',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: HfColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Residential plumbing diagnostic & fix',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: HfColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Appointment Time Card ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HfColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month,
                            color: HfColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wednesday, Oct 16 • 11:30 AM',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: HfColors.navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Estimated duration: 45–60 mins',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: HfColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.access_time_rounded,
                            size: 18, color: HfColors.grey),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Location Card ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HfColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: HfColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '742 Evergreen Terrace, Apt 4B, Brooklyn, NY 11201',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: HfColors.navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '1.2 miles away • ~8 min drive',
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
                            color: const Color(0xFFE8F4FD),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Map',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: HfColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Access Instructions Card ─────────────────────────
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
                            const Icon(Icons.vpn_key_outlined,
                                color: HfColors.primary, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'ACCESS INSTRUCTIONS',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: HfColors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            '"Ring bell 4B, under kitchen sink. Main shutoff valve is accessible in basement if needed."',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF92400E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Customer Attached Photos Section ─────────────────
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Customer Photos (2)',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: HfColors.navy,
                              ),
                            ),
                            Text(
                              'Tap to inspect',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: HfColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=250',
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  'https://images.unsplash.com/photo-1542013936693-884638332954?w=250',
                                  height: 90,
                                  fit: BoxFit.cover,
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

            // ── Sticky Bottom Action Bar ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: HfColors.border),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/p/requests');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      '✕ Decline',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/p/active-service');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF11768F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        '🚀 Start Job',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
