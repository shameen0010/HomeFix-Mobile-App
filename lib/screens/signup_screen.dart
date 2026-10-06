import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_widgets.dart';
import 'onboarding_screen.dart';

/// Only these two roles can self-register.
/// Admin accounts are created from the database side.
enum SignupRole {
  customer('Customer', 'customer'),
  servicePartner('Service Partner', 'service_partner');

  final String label;
  final String value; // stored in Firestore users/{uid}.role
  const SignupRole(this.label, this.value);
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();

  SignupRole _role = SignupRole.customer;
  bool _agreed = false;
  bool _loading = false;

  bool get _emailOk =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());
  int get _score => passwordRules(_pass.text).where((e) => e).length;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms to continue')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final email = _email.text.trim().toLowerCase();
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: email, password: _pass.text);
      final user = credential.user;
      if (user == null) {
        throw StateError('Account creation returned no user.');
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _name.text.trim(),
        'email': email,
        'phone': '+94${_phone.text.replaceAll(RegExp(r'\D'), '')}',
        'role': _role.value,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. You can now log in.')),
      );
      context.go('/login');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_signupErrorMessage(error)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save your profile: ${error.message}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (error) {
      debugPrint('Signup error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _signupErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return error.message ?? 'Could not create your account.';
    }
  }

  Widget _strengthLabel() {
    if (_pass.text.isEmpty) return const SizedBox.shrink();
    final (text, color) = switch (_score) {
      4 => ('Strong Password', AppColors.primary),
      3 => ('Good Password', AppColors.primary),
      2 => ('Fair Password', AppColors.orange),
      _ => ('Weak Password', Colors.redAccent),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.shield_outlined, size: 12, color: color),
      const SizedBox(width: 4),
      Text(text, style: poppins(10, color: color, w: FontWeight.w600)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            AuthHeader(
              onBack: () => context.go('/login'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(children: [
                          Text('Create Account',
                              style: poppins(26, w: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(
                            'Join thousands getting reliable home repairs and upkeep done right.',
                            textAlign: TextAlign.center,
                            style: poppins(13, color: AppColors.grey),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      _RoleTabs(
                        selected: _role,
                        onChanged: (r) => setState(() => _role = r),
                      ),
                      const SizedBox(height: 18),

                      const FieldLabel('Full Name'),
                      AppField(
                        controller: _name,
                        hint: 'Your full name',
                        icon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      const FieldLabel('Email Address'),
                      AppField(
                        controller: _email,
                        hint: 'name@example.com',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(() {}),
                        suffix: _emailOk
                            ? const Icon(Icons.check_circle_outline,
                                color: AppColors.primary, size: 20)
                            : null,
                        validator: (v) =>
                            _emailOk ? null : 'Enter a valid email',
                      ),
                      const SizedBox(height: 14),

                      const FieldLabel('Phone Number'),
                      Row(children: [
                        Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: kFieldBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(children: [
                            Text('SL',
                                style: poppins(13, w: FontWeight.w700)),
                            const SizedBox(width: 6),
                            Text('+94',
                                style: poppins(12, color: AppColors.grey)),
                            const Icon(Icons.keyboard_arrow_down,
                                size: 18, color: AppColors.grey),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppField(
                            controller: _phone,
                            hint: '7X XXX XXXX',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                              return d.length >= 9 ? null : 'Enter a valid number';
                            },
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),

                      FieldLabel('Password', trailing: _strengthLabel()),
                      PasswordField(
                        controller: _pass,
                        hint: 'Create a password',
                        onChanged: (_) => setState(() {}),
                        validator: (v) => passwordRules(v ?? '')[0]
                            ? null
                            : 'Minimum 8 characters',
                      ),
                      const SizedBox(height: 10),
                      StrengthBar(filled: _score, total: 4),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Min. 8 characters',
                              style: poppins(10, color: AppColors.grey)),
                          Text(
                            _score == 4
                                ? 'Matches all criteria'
                                : '$_score/4 criteria',
                            style: poppins(10,
                                color: _score == 4
                                    ? AppColors.primary
                                    : AppColors.grey,
                                w: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _agreed,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              onChanged: (v) =>
                                  setState(() => _agreed = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: poppins(11, color: AppColors.grey),
                                children: [
                                  const TextSpan(text: "I agree to HomeFix's "),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: poppins(11,
                                        w: FontWeight.w600,
                                        color: AppColors.primary),
                                  ),
                                  const TextSpan(text: ', '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: poppins(11,
                                        w: FontWeight.w600,
                                        color: AppColors.primary),
                                  ),
                                  const TextSpan(
                                      text:
                                          ', and professional code of conduct.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      PrimaryButton(
                        label: 'Create Account',
                        loading: _loading,
                        color: kDeepTeal,
                        onPressed: _create,
                      ),
                      const SizedBox(height: 18),
                      const OrDivider('OR SIGN UP WITH'),
                      const SizedBox(height: 14),
                      SocialButtons(
                        onGoogle: () {}, // TODO
                        onApple: () {}, // TODO
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Already have an account?  ',
                                style: poppins(13, color: AppColors.grey)),
                            GestureDetector(
                              onTap: () =>                               context.go('/login'),
                              child: Text('Log In',
                                  style: poppins(13,
                                      color: AppColors.primary,
                                      w: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _RoleTabs extends StatelessWidget {
  final SignupRole selected;
  final ValueChanged<SignupRole> onChanged;
  const _RoleTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEBFA),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          for (final r in SignupRole.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: r == selected ? kDeepTeal : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    r.label,
                    style: poppins(
                      13,
                      w: FontWeight.w600,
                      color: r == selected ? Colors.white : AppColors.dark,
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