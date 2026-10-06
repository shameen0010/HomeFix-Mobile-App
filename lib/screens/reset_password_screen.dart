import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/auth_widgets.dart';
import 'onboarding_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  // 3 checklist rules: length, upper+lower, number or symbol
  List<bool> get _checks {
    final r = passwordRules(_new.text);
    return [r[0], r[1], r[2] || r[3]];
  }

  int get _filled => _checks.where((e) => e).length;

  @override
  void dispose() {
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // TODO: FirebaseAuth.instance.confirmPasswordReset(
      //   code: oobCode, newPassword: _new.text);
      // (oobCode comes from the reset email link / deep link)
      await Future.delayed(const Duration(seconds: 1)); // remove later
      if (!mounted) return;
      context.go('/login');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _strengthLabel() {
    if (_new.text.isEmpty) return const SizedBox.shrink();
    final (text, color) = !_checks[0]
        ? ('TOO SHORT', AppColors.grey)
        : switch (_filled) {
            3 => ('STRONG', AppColors.green),
            2 => ('GOOD', AppColors.primary),
            _ => ('WEAK', AppColors.orange),
          };
    return Text(text, style: poppins(10, color: color, w: FontWeight.w600));
  }

  @override
  Widget build(BuildContext context) {
    const labels = [
      'At least 8 characters',
      'Both uppercase & lowercase letters',
      'At least one number or symbol',
    ];
    final checks = _checks;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AuthHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    const HeroBadge(icon: Icons.lock_reset, circle: true),
                    const SizedBox(height: 8),
                    Text('Create New Password',
                        style: poppins(24, w: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'Your new password must be different from previous passwords for security.',
                      textAlign: TextAlign.center,
                      style: poppins(13, color: AppColors.grey),
                    ),
                    const SizedBox(height: 20),
                    AuthCard(
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FieldLabel('New Password',
                                trailing: _strengthLabel()),
                            PasswordField(
                              controller: _new,
                              hint: 'Enter new strong password',
                              onChanged: (_) => setState(() {}),
                              validator: (v) =>
                                  _checks.every((e) => e)
                                      ? null
                                      : 'Password does not meet the rules',
                            ),
                            const SizedBox(height: 10),
                            StrengthBar(filled: _filled, total: 3),
                            const SizedBox(height: 16),
                            const FieldLabel('Confirm New Password'),
                            PasswordField(
                              controller: _confirm,
                              hint: 'Re-enter password',
                              validator: (v) => v == _new.text
                                  ? null
                                  : 'Passwords do not match',
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: kFieldBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('MUST INCLUDE',
                                      style: poppins(10,
                                          color: AppColors.grey,
                                          w: FontWeight.w600)),
                                  const SizedBox(height: 10),
                                  for (var i = 0; i < labels.length; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: checks[i]
                                                ? AppColors.green
                                                : kSegOff,
                                          ),
                                          child: Icon(Icons.check,
                                              size: 12,
                                              color: checks[i]
                                                  ? Colors.white
                                                  : AppColors.primary),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(labels[i], style: poppins(12)),
                                      ]),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: 'Reset Password & Log In',
                              loading: _loading,
                              color: kDeepTeal,
                              onPressed: _reset,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCEBFA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFBFE3EE),
                          child: Icon(Icons.verified_outlined,
                              size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your account credentials are fully encrypted and protected with HomeFix Security.',
                            style: poppins(11, color: AppColors.dark),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back,
                              size: 16, color: AppColors.dark),
                          const SizedBox(width: 8),
                          Text('Cancel and return to Login',
                              style: poppins(12)),
                        ],
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