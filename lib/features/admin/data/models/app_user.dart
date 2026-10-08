import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_utils.dart';

/// Firestore: users/{uid}. Customers have role == 'customer'.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.location,
    required this.status,
    required this.role,
    required this.customerNo,
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalSpend,
    required this.emailVerified,
    required this.phoneVerified,
    this.photoUrl,
    this.suspendReason,
    this.createdAt,
  });

  final String id, name, email, phone, address, location, status, role, customerNo;
  final int totalBookings, completedBookings, cancelledBookings;
  final double totalSpend;
  final bool emailVerified, phoneVerified;
  final String? photoUrl, suspendReason;
  final DateTime? createdAt;

  bool get isActive => status != 'suspended';
  String get code => '#CUST-$customerNo';
  double get completionRate =>
      totalBookings == 0 ? 0 : completedBookings / totalBookings;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return AppUser(
      id: doc.id,
      name: asString(d['name'], 'Unnamed user'),
      email: asString(d['email']),
      phone: asString(d['phone'], '-'),
      address: asString(d['address'], '-'),
      location: asString(d['location'], '-'),
      status: asString(d['status'], 'active'),
      role: asString(d['role'], 'customer'),
      customerNo: asString(d['customerNo'], shortId(doc.id, 4)),
      totalBookings: asInt(d['totalBookings']),
      completedBookings: asInt(d['completedBookings']),
      cancelledBookings: asInt(d['cancelledBookings']),
      totalSpend: asDouble(d['totalSpend']),
      emailVerified: asBool(d['emailVerified']),
      phoneVerified: asBool(d['phoneVerified']),
      photoUrl: d['photoUrl'] as String?,
      suspendReason: d['suspendReason'] as String?,
      createdAt: asDate(d['createdAt']),
    );
  }
}
