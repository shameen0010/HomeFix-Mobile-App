import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/hf_theme.dart';
import 'data/models.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'firebase_options.dart';
import 'features/customer/booking_screens.dart';
import 'features/customer/customer_additional_screens.dart';
import 'features/customer/customer_screens.dart';
import 'features/customer/screens/my_bookings_screen.dart';
import 'features/customer/screens/search_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'features/provider/provider_onboard_screens.dart';
import 'features/provider/provider_screens.dart';
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
            return CustomerShell(index: 1, child: FirestoreSearchScreen(initial: initial));
          },
        ),
        GoRoute(
          path: 'bookings',
          builder: (context, state) => const CustomerShell(index: 2, child: MyBookingsScreen()),
        ),
        GoRoute(
          path: 'messages',
          builder: (context, state) => const CustomerShell(index: 3, child: MessagesInboxScreen()),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const CustomerShell(index: 4, child: LiveCustomerProfileScreen()),
        ),
        GoRoute(
          path: 'notifications',
          builder: (context, state) => const CustomerShell(index: 4, child: LiveCustomerNotificationsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/provider/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return LiveProviderPublicProfile(userId: userId);
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
      builder: (context, state) => FirestorePaymentConfirmationScreen(
        bookingId: state.uri.queryParameters['bookingId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/service-complete',
      builder: (context, state) => FirestoreServiceCompleteScreen(
        bookingId: state.uri.queryParameters['bookingId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/rate-review',
      builder: (context, state) => FirestoreRateReviewScreen(
        bookingId: state.uri.queryParameters['bookingId'] ?? '',
      ),
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
      builder: (context, state) => const FirestoreBookingSuccessScreen(),
    ),
    GoRoute(
      path: '/booking-checkout/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId']!;
        return FirestoreBookingCheckoutScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: '/cancel-booking/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId']!;
        return FirestoreCancelBookingScreen(bookingId: bookingId);
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
      builder: (context, state) {
        final bookingId = state.uri.queryParameters['bookingId'];
        return bookingId == null || bookingId.isEmpty
            ? const EmergencyStatusScreen()
            : FirestoreEmergencyStatusScreen(bookingId: bookingId);
      },
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
    GoRoute(
      path: '/provider-onboard/credentials',
      builder: (context, state) => ProviderCredentialsScreen(
        categories: (state.extra as List<String>?) ?? const [],
      ),
    ),
    GoRoute(
      path: '/provider-onboard/pending',
      builder: (context, state) => const ProviderVerificationPendingScreen(),
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
          builder: (context, state) => const ProviderShell(index: 1, child: ProviderRequestsScreen()),
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
          builder: (context, state) => const ProviderShell(index: 0, child: LiveProviderServicesScreen()),
        ),
        GoRoute(
          path: 'availability',
          builder: (context, state) => const ProviderShell(index: 0, child: LiveProviderAvailabilityScreen()),
        ),
        GoRoute(
          path: 'chat',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final bookingId = extra?['bookingId'] as String?;
            return bookingId == null || bookingId.isEmpty
                ? const ProviderChatScreen(
                    customerName: 'Customer',
                    customerAvatar: '',
                    customerAddress: 'Booking chat',
                    bookingId: '',
                    serviceTitle: 'Home service',
                  )
                : ChatScreen(bookingId: bookingId);
          },
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProviderShell(index: 4, child: LiveProviderProfileScreen()),
        ),
        GoRoute(
          path: 'ratings',
          builder: (context, state) => const LiveProviderRatingsScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const ProviderShell(index: 4, child: ProviderSettingsScreen()),
        ),
        GoRoute(
          path: 'notifications',
          builder: (context, state) => const LiveProviderNotificationsScreen(),
        ),
        GoRoute(
          path: 'active-service',
          builder: (context, state) => const LiveProviderActiveServiceScreen(),
        ),
        GoRoute(
          path: 'job-receipt',
          builder: (context, state) => const LiveProviderReceiptScreen(),
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