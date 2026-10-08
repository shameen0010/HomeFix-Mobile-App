import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

// Homefix state
class HomefixState {
  final User? session;
  final List<User> users;
  final List<ProviderProfile> providers;
  final List<Booking> bookings;
  final List<Service> services;
  final List<ChatMessage> messages;
  final bool alertsOn;
  final bool onboardingDone;

  HomefixState({
    this.session,
    this.users = const [],
    this.providers = const [],
    this.bookings = const [],
    this.services = const [],
    this.messages = const [],
    this.alertsOn = true,
    this.onboardingDone = false,
  });

  HomefixState copyWith({
    User? session,
    List<User>? users,
    List<ProviderProfile>? providers,
    List<Booking>? bookings,
    List<Service>? services,
    List<ChatMessage>? messages,
    bool? alertsOn,
    bool? onboardingDone,
  }) {
    return HomefixState(
      session: session ?? this.session,
      users: users ?? this.users,
      providers: providers ?? this.providers,
      bookings: bookings ?? this.bookings,
      services: services ?? this.services,
      messages: messages ?? this.messages,
      alertsOn: alertsOn ?? this.alertsOn,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }
}

// Homefix store notifier
class HomefixStore extends StateNotifier<HomefixState> {
  HomefixStore() : super(_initialState());

  static HomefixState _initialState() {
    // Mock users
    final users = [
      User(
        id: 'user1',
        firstName: 'Sarah',
        lastName: 'Jenkins',
        name: 'Sarah Jenkins',
        email: 'sarah.j@example.com',
        phone: '+94 77 123 4567',
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
        location: 'Nugegoda, Sri Lanka',
        role: UserRole.customer,
      ),
      User(
        id: 'user2',
        firstName: 'David',
        lastName: 'Miller',
        name: 'David Miller',
        email: 'david.miller@example.com',
        phone: '+94 77 234 5678',
        avatarUrl: 'https://i.pravatar.cc/150?img=11',
        location: 'Colombo',
        role: UserRole.customer,
      ),
      User(
        id: 'admin1',
        firstName: 'Admin',
        lastName: 'User',
        name: 'Admin User',
        email: 'admin@homefix.com',
        phone: '+94 77 999 9999',
        avatarUrl: null,
        location: 'Colombo',
        role: UserRole.admin,
      ),
      User(
        id: 'prov1',
        firstName: 'David',
        lastName: 'Smith',
        name: 'David Smith',
        email: 'david.smith@example.com',
        phone: '+94 77 345 6789',
        avatarUrl: 'https://i.pravatar.cc/150?img=11',
        location: 'Colombo',
        role: UserRole.provider,
      ),
      User(
        id: 'prov2',
        firstName: 'Sarah',
        lastName: 'Johnson',
        name: 'Sarah Johnson',
        email: 'sarah.johnson@example.com',
        phone: '+94 77 456 7890',
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
        location: 'Kandy',
        role: UserRole.provider,
      ),
      User(
        id: 'prov3',
        firstName: 'Michael',
        lastName: 'Brown',
        name: 'Michael Brown',
        email: 'michael.b@example.com',
        phone: '+94 77 567 8901',
        avatarUrl: 'https://i.pravatar.cc/150?img=3',
        location: 'Gampaha',
        role: UserRole.provider,
      ),
    ];

    // Mock providers
    final providers = [
      ProviderProfile(
        userId: 'prov1',
        specialty: 'Plumbing & Pipe Repair',
        area: 'Colombo',
        distanceMiles: 2.5,
        hourlyRate: 2500,
        rating: 4.9,
        reviewCount: 127,
        yearsExp: 8,
        jobsDone: 450,
        onTime: 98,
        availableToday: true,
        bio: 'Certified plumber with 8+ years of experience. Specialized in leak detection, pipe repair, and bathroom installations. Available 24/7 for emergency services.',
      ),
      ProviderProfile(
        userId: 'prov2',
        specialty: 'Professional Cleaning',
        area: 'Kandy',
        distanceMiles: 4.2,
        hourlyRate: 1800,
        rating: 4.8,
        reviewCount: 89,
        yearsExp: 5,
        jobsDone: 320,
        onTime: 95,
        availableToday: true,
        bio: 'Expert cleaning services for homes and offices. Deep cleaning, regular maintenance, and post-construction cleanup available.',
      ),
      ProviderProfile(
        userId: 'prov3',
        specialty: 'Electrical Services',
        area: 'Gampaha',
        distanceMiles: 3.8,
        hourlyRate: 3000,
        rating: 4.7,
        reviewCount: 64,
        yearsExp: 10,
        jobsDone: 280,
        onTime: 92,
        availableToday: false,
        bio: 'Licensed electrician specializing in residential and commercial electrical work. Wiring, repairs, and installations.',
      ),
    ];

    // Mock bookings
    final bookings = [
      Booking(
        id: 'booking1',
        customerId: 'user1',
        providerId: 'prov1',
        serviceTitle: 'Pipe Leak Repair',
        scheduledLabel: 'Today, 2:00 PM',
        status: BookingStatus.inProgress,
        scheduledDate: DateTime.now(),
        amount: 2500,
        address: '123 Main St, Nugegoda',
        contactPhone: '+94 77 123 4567',
      ),
      Booking(
        id: 'booking2',
        customerId: 'user1',
        providerId: 'prov2',
        serviceTitle: 'Deep Home Cleaning',
        scheduledLabel: 'Yesterday, 10:00 AM',
        status: BookingStatus.completed,
        scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
        amount: 1800,
        address: '45 Oak Avenue, Colombo',
        contactPhone: '+94 77 123 4567',
      ),
    ];

    // Mock services
    final services = [
      Service(
        id: 'svc1',
        providerId: 'prov1',
        title: 'Pipe Leak Repair',
        subtitle: 'Diagnosis & rapid fix',
        category: 'Plumbing',
        price: 2500,
        unit: '/job',
      ),
      Service(
        id: 'svc2',
        providerId: 'prov1',
        title: 'Bathroom Installation',
        subtitle: 'Full fixture setup',
        category: 'Plumbing',
        price: 15000,
        unit: '/project',
      ),
      Service(
        id: 'svc3',
        providerId: 'prov2',
        title: 'Deep Home Cleaning',
        subtitle: 'Full sanitization & dusting',
        category: 'Cleaning',
        price: 1800,
        unit: '/hour',
      ),
      Service(
        id: 'svc4',
        providerId: 'prov2',
        title: 'Regular Maintenance',
        subtitle: 'Weekly cleaning service',
        category: 'Cleaning',
        price: 1200,
        unit: '/hour',
      ),
    ];

    // Mock messages
    final messages = [
      ChatMessage(
        id: 'msg1',
        bookingId: 'booking1',
        fromId: 'prov1',
        text: 'Hello! I\'m on my way to your location. ETA: 15 minutes.',
        time: '10:30 AM',
        system: false,
      ),
      ChatMessage(
        id: 'msg2',
        bookingId: 'booking1',
        fromId: 'user1',
        text: 'Great, thank you! I\'ll keep the gate unlocked.',
        time: '10:32 AM',
        system: false,
      ),
      ChatMessage(
        id: 'msg3',
        bookingId: 'booking1',
        fromId: 'system',
        text: 'Provider has arrived at your location',
        time: '10:45 AM',
        system: true,
      ),
    ];

    return HomefixState(
      session: null,
      users: users,
      providers: providers,
      bookings: bookings,
      services: services,
      messages: messages,
      alertsOn: true,
      onboardingDone: false,
    );
  }

  void logout() {
    state = HomefixState(
      users: state.users,
      providers: state.providers,
      bookings: state.bookings,
      services: state.services,
      messages: state.messages,
      alertsOn: state.alertsOn,
      onboardingDone: state.onboardingDone,
    );
  }

  void setFirebaseSession({
    required String id,
    required String name,
    required String email,
    String phone = '',
    String location = 'Nugegoda, Sri Lanka',
    required UserRole role,
  }) {
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final displayName = name.trim().isEmpty ? email : name.trim();
    final user = User(
      id: id,
      firstName: nameParts.isEmpty ? displayName : nameParts.first,
      lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      name: displayName,
      email: email,
      phone: phone,
      location: location,
      role: role,
    );
    state = state.copyWith(session: user);
  }

  void toggleAlerts() {
    state = state.copyWith(alertsOn: !state.alertsOn);
  }

  void sendMessage(String bookingId, String fromId, String text) {
    final newMessage = ChatMessage(
      id: 'msg${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      fromId: fromId,
      text: text,
      time: DateTime.now().toString().substring(11, 16),
      system: false,
    );
    state = state.copyWith(messages: [...state.messages, newMessage]);
  }

  String? login(String emailOrPhone, String password, {bool remember = false}) {
    // Mock login - check against demo users
    final user = state.users.firstWhere(
      (u) => u.email.toLowerCase() == emailOrPhone.toLowerCase() || u.phone == emailOrPhone,
      orElse: () => User(
        id: '',
        firstName: '',
        lastName: '',
        name: '',
        email: '',
        phone: '',
        location: '',
        role: UserRole.customer,
      ),
    );

    if (user.id.isEmpty) {
      return 'User not found. Please check your email/phone or create an account.';
    }

    // Mock password check (in real app, use proper hashing)
    if (password != 'HomeFix@2025!' && password != 'Admin@2025!') {
      return 'Incorrect password. Please try again.';
    }

    state = state.copyWith(session: user);
    return null;
  }

  String? register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) {
    // Check if user already exists
    final existing = state.users.any(
      (u) => u.email.toLowerCase() == email.toLowerCase() || u.phone == phone,
    );

    if (existing) {
      return 'An account with this email or phone already exists.';
    }

    // Create new user
    final nameParts = name.split(' ');
    final newUser = User(
      id: 'user${DateTime.now().millisecondsSinceEpoch}',
      firstName: nameParts.first,
      lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      name: name,
      email: email,
      phone: phone,
      location: 'Nugegoda, Sri Lanka',
      role: role,
    );

    state = state.copyWith(
      users: [...state.users, newUser],
      session: newUser,
    );

    return null;
  }

  void resetPassword(String email, String newPassword) {
    // Mock password reset
    final userIndex = state.users.indexWhere((u) => u.email.toLowerCase() == email.toLowerCase());
    if (userIndex != -1) {
      // In real app, this would update the password in a secure way
      // For now, we just mark onboarding as done
      state = state.copyWith(onboardingDone: true);
    }
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingDone: true);
  }

  void createBooking(Booking booking) {
    state = state.copyWith(bookings: [...state.bookings, booking]);
  }

  void updateBookingStatus(String bookingId, BookingStatus newStatus) {
    final updatedBookings = state.bookings.map((b) {
      if (b.id == bookingId) {
        return Booking(
          id: b.id,
          customerId: b.customerId,
          providerId: b.providerId,
          serviceTitle: b.serviceTitle,
          scheduledLabel: b.scheduledLabel,
          status: newStatus,
          scheduledDate: b.scheduledDate,
          amount: b.amount,
          address: b.address,
          notes: b.notes,
          imageUrls: b.imageUrls,
          contactPhone: b.contactPhone,
        );
      }
      return b;
    }).toList();
    state = state.copyWith(bookings: updatedBookings);
  }

  void cancelBooking(String bookingId) {
    updateBookingStatus(bookingId, BookingStatus.cancelled);
  }
}

// Provider for the store
final homefixStoreProvider = StateNotifierProvider<HomefixStore, HomefixState>((ref) {
  return HomefixStore();
});

// Draft booking notifier
class DraftBookingNotifier extends StateNotifier<DraftBooking> {
  DraftBookingNotifier() : super(DraftBooking());

  void set(DraftBooking draft) {
    state = draft;
  }
}

// Draft booking provider
final draftProvider = StateNotifierProvider<DraftBookingNotifier, DraftBooking>((ref) {
  return DraftBookingNotifier();
});
