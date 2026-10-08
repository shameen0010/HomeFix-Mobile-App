import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/admin/presentation/screens/admin_shell.dart';
import 'features/customer/presentation/screens/customer_shell.dart';
import 'features/customer/presentation/screens/provider_detail_screen.dart';
import 'features/provider/presentation/screens/provider_chat_screen.dart';
import 'features/provider/presentation/screens/provider_shell.dart';
import 'features/provider/presentation/screens/registration_complete_screen.dart';
import 'features/provider/presentation/screens/trade_credentials_screen.dart';
import 'features/provider/data/models/chat_models.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: HomeFixApp()));
}

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/a/home',
      builder: (context, state) => const AdminShell(),
    ),
    GoRoute(
      path: '/c',
      builder: (context, state) => const CustomerShell(),
    ),
    GoRoute(
      path: '/c/home',
      builder: (context, state) => const CustomerShell(),
    ),
    GoRoute(
      path: '/c/search',
      builder: (context, state) => const CustomerShell(),
    ),
    GoRoute(
      path: '/c/bookings',
      builder: (context, state) => const CustomerShell(),
    ),
    GoRoute(
      path: '/c/messages',
      builder: (context, state) => const CustomerShell(),
    ),
    GoRoute(
      path: '/c/profile',
      builder: (context, state) => const CustomerShell(),
    ),
    GoRoute(
      path: '/c/notifications',
      builder: (context, state) => const CustomerShell(),
    ),
    GoRoute(
      path: '/provider/:userId',
      builder: (context, state) => ProviderDetailScreen(
        providerId: state.pathParameters['userId']!,
      ),
    ),
    GoRoute(
      path: '/p',
      builder: (context, state) => const ProviderShell(),
    ),
    GoRoute(
      path: '/p/home',
      builder: (context, state) => const ProviderShell(),
    ),
    GoRoute(
      path: '/p/requests',
      builder: (context, state) => const ProviderShell(),
    ),
    GoRoute(
      path: '/p/schedule',
      builder: (context, state) => const ProviderShell(),
    ),
    GoRoute(
      path: '/p/messages',
      builder: (context, state) => const ProviderShell(),
    ),
    GoRoute(
      path: '/p/more',
      builder: (context, state) => const ProviderShell(),
    ),
    GoRoute(
      path: '/provider-onboard/complete',
      builder: (context, state) => const RegistrationCompleteScreen(),
    ),
    GoRoute(
      path: '/provider-onboard/category',
      builder: (context, state) => const TradeCredentialsScreen(),
    ),
    GoRoute(
      path: '/provider-onboard/pending',
      builder: (context, state) => const RegistrationCompleteScreen(),
    ),
    GoRoute(
      path: '/provider/chat',
      builder: (context, state) {
        final thread = state.extra;
        if (thread is! ChatThread) {
          return const ProviderShell();
        }
        return ProviderChatScreen(thread: thread);
      },
    ),
  ],
);

class HomeFixApp extends StatelessWidget {
  const HomeFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HomeFix',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
