// User role enum
enum UserRole {
  customer,
  provider,
  admin,
}

// User model
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String location;
  final UserRole role;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.location,
    required this.role,
  });

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? location,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      location: location ?? this.location,
      role: role ?? this.role,
    );
  }
}

// Provider profile model
class ProviderProfile {
  final String userId;
  final String specialty;
  final String area;
  final double distanceMiles;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final int yearsExp;
  final int jobsDone;
  final int onTime;
  final bool availableToday;
  final String bio;

  ProviderProfile({
    required this.userId,
    required this.specialty,
    required this.area,
    required this.distanceMiles,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    required this.yearsExp,
    required this.jobsDone,
    required this.onTime,
    required this.availableToday,
    required this.bio,
  });
}

// Booking status enum
enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
}

// Booking model
class Booking {
  final String id;
  final String customerId;
  final String providerId;
  final String serviceTitle;
  final String scheduledLabel;
  final BookingStatus status;
  final DateTime scheduledDate;
  final double amount;

  Booking({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.serviceTitle,
    required this.scheduledLabel,
    required this.status,
    required this.scheduledDate,
    required this.amount,
  });
}

// Service model
class Service {
  final String id;
  final String providerId;
  final String title;
  final String subtitle;
  final String category;
  final double price;
  final String unit;

  Service({
    required this.id,
    required this.providerId,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.price,
    required this.unit,
  });
}

// Chat message model
class ChatMessage {
  final String id;
  final String bookingId;
  final String fromId;
  final String text;
  final String? imageUrl;
  final String time;
  final bool system;

  ChatMessage({
    required this.id,
    required this.bookingId,
    required this.fromId,
    required this.text,
    this.imageUrl,
    required this.time,
    required this.system,
  });
}

// Draft booking model (for booking flow)
class DraftBooking {
  String? providerId;
  String? serviceTitle;
  double? amount;
  String? category;
  DateTime? scheduledDate;
  String? timeSlot;
  String? notes;

  DraftBooking();

  DraftBooking copy() {
    return DraftBooking()
      ..providerId = providerId
      ..serviceTitle = serviceTitle
      ..amount = amount
      ..category = category
      ..scheduledDate = scheduledDate
      ..timeSlot = timeSlot
      ..notes = notes;
  }
}
