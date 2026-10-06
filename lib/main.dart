import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/hf_theme.dart';
import 'data/models.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'firebase_options.dart';
import 'screens/booking_screens.dart';
import 'screens/customer_additional_screens.dart';
import 'screens/customer_screens.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/provider_onboard_screens.dart';
import 'screens/provider_screens.dart';
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
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
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
      builder: (context, state) => const CustomerShell(index: 0, child: CustomerDashboard()),
      routes: [
        GoRoute(
          path: 'home',
          builder: (context, state) => const CustomerShell(index: 0, child: CustomerDashboard()),
        ),
        GoRoute(
          path: 'search',
          builder: (context, state) {
            final initial = state.uri.queryParameters['q'];
            return CustomerShell(index: 1, child: SearchScreen(initial: initial));
          },
        ),
        GoRoute(
          path: 'bookings',
          builder: (context, state) => const CustomerShell(index: 2, child: CustomerBookingsScreen()),
        ),
        GoRoute(
          path: 'messages',
          builder: (context, state) => const CustomerShell(index: 3, child: MessagesInboxScreen()),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const CustomerShell(index: 4, child: ProfileScreen()),
        ),
        GoRoute(
          path: 'notifications',
          builder: (context, state) => const CustomerShell(index: 4, child: NotificationsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/provider/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ProviderPublicProfile(userId: userId);
      },
    ),
    GoRoute(
      path: '/chat/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId']!;
        return ChatScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: '/payment-confirmation',
      builder: (context, state) => const PaymentConfirmationScreen(),
    ),
    GoRoute(
      path: '/service-complete',
      builder: (context, state) => const ServiceCompleteScreen(),
    ),
    GoRoute(
      path: '/rate-review',
      builder: (context, state) => const RateReviewScreen(),
    ),
    GoRoute(
      path: '/service/:serviceId',
      builder: (context, state) {
        final serviceId = state.pathParameters['serviceId']!;
        return ServiceDetailsScreen(serviceId: serviceId);
      },
    ),
    GoRoute(
      path: '/booking-schedule',
      builder: (context, state) => const BookingScheduleScreen(),
    ),
    GoRoute(
      path: '/booking-confirmation',
      builder: (context, state) => const BookingConfirmationScreen(),
    ),
    GoRoute(
      path: '/booking-success',
      builder: (context, state) => const BookingSuccessScreen(),
    ),
    GoRoute(
      path: '/booking-checkout/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId']!;
        return BookingCheckoutScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: '/cancel-booking/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId']!;
        return CancelBookingScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const EmergencyServiceSelectionScreen(),
    ),
    GoRoute(
      path: '/emergency-details',
      builder: (context, state) => const EmergencyDetailsScreen(),
    ),
    GoRoute(
      path: '/emergency-providers',
      builder: (context, state) => const EmergencyProvidersScreen(),
    ),
    GoRoute(
      path: '/emergency-confirm',
      builder: (context, state) => const EmergencyConfirmScreen(),
    ),
    GoRoute(
      path: '/emergency-status',
      builder: (context, state) => const EmergencyStatusScreen(),
    ),
    // Provider onboarding flow
    GoRoute(
      path: '/provider-onboard/category',
      builder: (context, state) => const SelectCategoryScreen(),
    ),
    GoRoute(
      path: '/provider-onboard/complete',
      builder: (context, state) {
        final categories = state.extra as List<String>?;
        return RegistrationCompleteScreen(selectedCategories: categories);
      },
    ),
    // Provider main routes
    GoRoute(
      path: '/p',
      builder: (context, state) => const ProviderShell(index: 0, child: ProviderDashboard()),
      routes: [
        GoRoute(
          path: 'home',
          builder: (context, state) => const ProviderShell(index: 0, child: ProviderDashboard()),
        ),
        GoRoute(
          path: 'requests',
          builder: (context, state) => const ProviderShell(index: 1, child: ProviderRequestsPlaceholder()),
        ),
        GoRoute(
          path: 'schedule',
          builder: (context, state) => const ProviderShell(index: 2, child: ProviderSchedulePlaceholder()),
        ),
        GoRoute(
          path: 'messages',
          builder: (context, state) => const ProviderShell(index: 3, child: ProviderMessagesScreen()),
        ),
        GoRoute(
          path: 'more',
          builder: (context, state) => const ProviderShell(index: 4, child: ProviderMorePlaceholder()),
        ),
        GoRoute(
          path: 'services',
          builder: (context, state) => const ProviderShell(index: 0, child: ManageServicesScreen()),
        ),
        GoRoute(
          path: 'availability',
          builder: (context, state) => const ProviderShell(index: 0, child: ProviderAvailabilityScreen()),
        ),
        GoRoute(
          path: 'chat',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ProviderChatScreen(
              customerName: extra?['customerName'] as String? ?? 'Sarah Jenkins',
              customerAvatar: extra?['customerAvatar'] as String? ?? '',
              customerAddress: extra?['customerAddress'] as String? ?? 'Customer • Oakridge Lane',
              bookingId: extra?['bookingId'] as String? ?? '#HF-8921',
              serviceTitle: extra?['serviceTitle'] as String? ?? 'Pipe Leakage Repair',
            );
          },
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProviderShell(index: 4, child: ProviderProfileScreen()),
        ),
        GoRoute(
          path: 'ratings',
          builder: (context, state) => const ProviderRatingsScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const ProviderShell(index: 4, child: ProviderSettingsScreen()),
        ),
        GoRoute(
          path: 'notifications',
          builder: (context, state) => const ProviderNotificationsScreen(),
        ),
        GoRoute(
          path: 'active-service',
          builder: (context, state) => const ProviderActiveServiceScreen(),
        ),
        GoRoute(
          path: 'job-receipt',
          builder: (context, state) => const ProviderJobDetailsReceiptScreen(),
        ),
        GoRoute(
          path: 'customer-details',
          builder: (context, state) => const ProviderCustomerDetailsScreen(),
        ),
        GoRoute(
          path: 'history',
          builder: (context, state) => const ProviderBookingHistoryScreen(),
        ),
        GoRoute(
          path: 'booking-request',
          builder: (context, state) => const ProviderBookingRequestDetailScreen(),
        ),
      ],
    ),
  ],
);

class HomeFixApp extends StatelessWidget {
  const HomeFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'HomeFix',
      theme: HfTheme.lightTheme,
      routerConfig: router,
    );
  }
}

String homeFor(UserRole role) {
  return switch (role) {
    UserRole.customer => '/c/home',
    UserRole.provider => '/p/home',
    UserRole.admin => '/a/home',
  };
}