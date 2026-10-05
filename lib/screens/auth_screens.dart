import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/hf_theme.dart';
import '../core/widgets/hf_widgets.dart';
import '../data/homefix_store.dart';
import '../data/models.dart';
import '../main.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final email = TextEditingController(text: 'sarah.j@example.com');
  final password = TextEditingController(text: 'HomeFix@2025!');
  final form = GlobalKey<FormState>();
  bool remember = true;
  bool hide = true;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const HfScreenHeader(title: 'HomeFix', onBack: null),
            const SizedBox(height: 12),
            const Center(child: HfLogo(size: 78)),
            const SizedBox(height: 12),
            Text('Welcome Back!', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800)),
            const Text('Sign in to manage your home services and bookings', textAlign: TextAlign.center, style: TextStyle(color: HfColors.muted)),
            const SizedBox(height: 20),
            HfCard(
              child: Form(
                key: form,
                child: Column(
                  children: [
                    HfField(
                      label: 'Email or Phone Number',
                      hint: 'name@example.com or phone',
                      icon: Icons.alternate_email,
                      controller: email,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    HfField(
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: Icons.lock_outline,
                      obscureText: hide,
                      controller: password,
                      suffix: IconButton(
                        onPressed: () => setState(() => hide = !hide),
                        icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(value: remember, onChanged: (v) => setState(() => remember = v ?? false)),
                        const Text('Remember me'),
                        const Spacer(),
                        TextButton(onPressed: () => context.push('/reset-password'), child: const Text('Forgot Password?')),
                      ],
                    ),
                    if (error != null) Text(error!, style: const TextStyle(color: HfColors.danger, fontSize: 12)),
                    HfPrimaryButton(
                      label: 'Log In  →',
                      onPressed: () {
                        if (!form.currentState!.validate()) return;
                        final err = ref.read(homefixStoreProvider.notifier).login(email.text.trim(), password.text, remember: remember);
                        if (err != null) {
                          setState(() => error = err);
                          return;
                        }
                        ref.read(homefixStoreProvider.notifier).completeOnboarding();
                        final user = ref.read(homefixStoreProvider).session!;
                        context.go(homeFor(user.role));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Center(child: Text('OR CONTINUE WITH', style: TextStyle(color: HfColors.muted, fontSize: 11, letterSpacing: 1))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _social('Google', Icons.g_mobiledata, () => hfSnack(context, 'Google sign-in is simulated in this build.'))),
                const SizedBox(width: 12),
                Expanded(child: _social('Apple', Icons.apple, () => hfSnack(context, 'Apple sign-in is simulated in this build.'))),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () => context.push('/register'),
                  child: const Text('Sign Up', style: TextStyle(color: HfColors.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(child: HfPill(label: '256-bit Secure Encryption • 100% Vetted Network', icon: Icons.lock_outline)),
            const SizedBox(height: 12),
            Text(
              'Demo: sarah.j@example.com  •  david.miller@example.com  •  admin@homefix.com\nPassword: HomeFix@2025!  (admin: Admin@2025!)',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: HfColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _social(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: HfColors.navy),
      label: Text(label, style: const TextStyle(color: HfColors.navy, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: Colors.white,
        side: const BorderSide(color: HfColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  UserRole role = UserRole.customer;
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  bool agreed = false;
  bool hide = true;
  String? error;

  bool get strong {
    final p = password.text;
    return p.length >= 8 && RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p) && RegExp(r'[0-9!@#\$%^&*]').hasMatch(p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            HfScreenHeader(title: 'HomeFix', onBack: () => context.pop()),
            Text('Create Account', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800)),
            const Text('Join thousands getting reliable home repairs and upkeep done right.', textAlign: TextAlign.center, style: TextStyle(color: HfColors.muted)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: HfColors.field, borderRadius: BorderRadius.circular(28)),
              child: Row(
                children: [
                  _roleTab('Customer', UserRole.customer),
                  _roleTab('Service Partner', UserRole.provider),
                  _roleTab('Admin', UserRole.admin),
                ],
              ),
            ),
            const SizedBox(height: 16),
            HfField(label: 'Full Name', hint: 'Sarah Jenkins', icon: Icons.person_outline, controller: name),
            const SizedBox(height: 12),
            HfField(label: 'Email Address', hint: 'sarah.j@example.com', icon: Icons.mail_outline, controller: email),
            const SizedBox(height: 12),
            HfField(label: 'Phone Number', hint: '(555) 382-9014', icon: Icons.phone_outlined, controller: phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            HfField(
              label: 'Password',
              hint: 'Create a strong password',
              icon: Icons.lock_outline,
              obscureText: hide,
              controller: password,
              onChanged: (_) => setState(() {}),
              suffix: IconButton(onPressed: () => setState(() => hide = !hide), icon: const Icon(Icons.visibility_outlined)),
            ),
            const SizedBox(height: 6),
            Text(strong ? 'Matches all criteria' : 'Min. 8 characters', style: TextStyle(color: strong ? HfColors.success : HfColors.muted, fontSize: 12)),
            CheckboxListTile(
              value: agreed,
              onChanged: (v) => setState(() => agreed = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('I agree to HomeFix\'s Terms of Service, Privacy Policy, and professional code of conduct.', style: TextStyle(fontSize: 12)),
            ),
            if (error != null) Text(error!, style: const TextStyle(color: HfColors.danger)),
            HfPrimaryButton(
              label: 'Create Account  →',
              onPressed: () {
                if (!agreed) {
                  setState(() => error = 'Please accept the terms to continue.');
                  return;
                }
                if (!strong) {
                  setState(() => error = 'Password does not meet security criteria.');
                  return;
                }
                final err = ref.read(homefixStoreProvider.notifier).register(
                      name: name.text.trim(),
                      email: email.text.trim(),
                      phone: phone.text.trim(),
                      password: password.text,
                      role: role,
                    );
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                if (role == UserRole.provider) {
                  context.go('/provider-onboard/category');
                } else {
                  context.go(homeFor(role));
                }
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                const Text('Already have an account? '),
                GestureDetector(onTap: () => context.go('/login'), child: const Text('Log In', style: TextStyle(color: HfColors.primary, fontWeight: FontWeight.w700))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleTab(String label, UserRole value) {
    final selected = role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? HfColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : HfColors.navy),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool hide = true;

  bool get longEnough => password.text.length >= 8;
  bool get mixedCase => RegExp(r'[A-Z]').hasMatch(password.text) && RegExp(r'[a-z]').hasMatch(password.text);
  bool get symbol => RegExp(r'[0-9!@#\$%^&*]').hasMatch(password.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            HfScreenHeader(title: 'HomeFix', onBack: () => context.pop()),
            const SizedBox(height: 12),
            const Center(child: CircleAvatar(radius: 36, backgroundColor: HfColors.primary, child: Icon(Icons.lock_reset, color: Colors.white, size: 32))),
            const SizedBox(height: 12),
            Text('Create New Password', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800)),
            const Text('Your new password must be different from previous passwords for security.', textAlign: TextAlign.center, style: TextStyle(color: HfColors.muted)),
            const SizedBox(height: 16),
            HfCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HfField(
                    label: 'New Password',
                    hint: 'Enter new strong password',
                    icon: Icons.lock_outline,
                    obscureText: hide,
                    controller: password,
                    onChanged: (_) => setState(() {}),
                    suffix: IconButton(onPressed: () => setState(() => hide = !hide), icon: const Icon(Icons.visibility_outlined)),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(longEnough ? 'LOOKS GOOD' : 'TOO SHORT', style: TextStyle(color: longEnough ? HfColors.success : HfColors.danger, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  HfField(label: 'Confirm New Password', hint: 'Re-enter password', icon: Icons.lock_outline, obscureText: true, controller: confirm),
                  const SizedBox(height: 12),
                  const Text('MUST INCLUDE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  _rule('At least 8 characters', longEnough),
                  _rule('Both uppercase & lowercase letters', mixedCase),
                  _rule('At least one number or symbol', symbol),
                  const SizedBox(height: 12),
                  HfPrimaryButton(
                    label: 'Reset Password & Log In  →',
                    onPressed: () {
                      if (password.text != confirm.text) {
                        hfSnack(context, 'Passwords do not match.');
                        return;
                      }
                      if (!(longEnough && mixedCase && symbol)) {
                        hfSnack(context, 'Password does not meet the rules.');
                        return;
                      }
                      ref.read(homefixStoreProvider.notifier).resetPassword('sarah.j@example.com', password.text);
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const HfCard(
              color: HfColors.primarySoft,
              child: Text('Your account credentials are fully encrypted and protected with HomeFix Security.'),
            ),
            TextButton(onPressed: () => context.go('/login'), child: const Text('← Cancel and return to Login')),
          ],
        ),
      ),
    );
  }

  Widget _rule(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: ok ? HfColors.success : const Color(0xFFCDD6DE)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: ok ? HfColors.navy : HfColors.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
