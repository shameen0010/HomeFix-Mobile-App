import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/homefix_store.dart';
import '../data/models.dart';
import '../widgets/auth_widgets.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pass = TextEditingController();
  bool _remember = false;
  bool _loading = false;

  @override
  void dispose() {
    _id.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    final router = GoRouter.of(context);
    setState(() => _loading = true);

    try {
      final email = _id.text.trim().toLowerCase();
      final password = _pass.text;
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      var role = 'customer';
      final user = credential.user;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = userDoc.data();
        final storedRole = data?['role'];
        if (storedRole is String && storedRole.trim().isNotEmpty) {
          role = _normalizeRole(storedRole);
        }
      }

      if (!mounted) return;
      if (role == 'admin') {
        router.go('/a/home');
      } else {
        final profile = await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid ?? email)
            .get();
        final data = profile.data() ?? <String, dynamic>{};
        final appRole = role == 'service_partner'
            ? UserRole.provider
            : UserRole.customer;
        if (!mounted) return;
        ProviderScope.containerOf(context, listen: false)
            .read(homefixStoreProvider.notifier)
            .setFirebaseSession(
              id: user?.uid ?? email,
              name: data['name'] as String? ?? user?.displayName ?? email,
              email: email,
              phone: data['phone'] as String? ?? '',
              location: data['location'] as String? ?? 'Nugegoda, Sri Lanka',
              role: appRole,
            );
        if (!mounted) return;
        if (appRole == UserRole.provider) {
          final provider = await FirebaseFirestore.instance
              .collection('providers')
              .doc(user?.uid)
              .get();
          if (!provider.exists) {
            router.go('/provider-onboard/category');
            return;
          }
          final verificationStatus =
              (provider.data()?['verificationStatus'] ?? provider.data()?['status'] ?? 'pending').toString();
          router.go(verificationStatus == 'approved'
              ? '/p/home'
              : '/provider-onboard/pending');
        } else {
          router.go('/c/home');
        }
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(_authErrorMessage(error)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Could not load your profile: ${error.message}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (error) {
      debugPrint('Login error: $error');
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _normalizeRole(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    switch (normalized) {
      case 'service_provider':
      case 'serviceprovider':
      case 'service_partner':
      case 'servicepartner':
      case 'provider':
        return 'service_partner';
      case 'admin':
        return 'admin';
      default:
        return 'customer';
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'The email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              AuthHeader(
                onBack: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  children: [
                    const HeroBadge(icon: Icons.home_rounded),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome Back!',
                      style: poppins(26, w: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to manage your home services and bookings',
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
                            const FieldLabel('Email or Phone Number'),
                            AppField(
                              controller: _id,
                              hint: 'name@example.com or phone',
                              icon: Icons.alternate_email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter your email or phone'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            const FieldLabel('Password'),
                            PasswordField(
                              controller: _pass,
                              hint: 'Enter your password',
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Enter your password'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _remember,
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        onChanged: (v) => setState(
                                          () => _remember = v ?? false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Remember me', style: poppins(12)),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      context.push('/reset-password'),
                                  child: Text(
                                    'Forgot Password?',
                                    style: poppins(
                                      12,
                                      color: AppColors.primary,
                                      w: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: 'Log In',
                              loading: _loading,
                              onPressed: _login,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const OrDivider('OR CONTINUE WITH'),
                    const SizedBox(height: 16),
                    SocialButtons(
                      onGoogle: () {}, // TODO: Google sign-in
                      onApple: () {}, // TODO: Apple sign-in
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?  ",
                          style: poppins(13, color: AppColors.grey),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/signup'),
                          child: Text(
                            'Sign Up',
                            style: poppins(
                              13,
                              color: AppColors.primary,
                              w: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Pill(
                      icon: Icons.lock_outline,
                      text: '256-bit Secure Encryption • 100% Vetted Network',
                      bg: Color(0xFFEAF2FF),
                      fg: AppColors.primary,
                      size: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
