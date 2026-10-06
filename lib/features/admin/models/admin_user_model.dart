import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime? createdAt;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'Customer',
    this.status = 'Active',
    this.createdAt,
  });

  factory AdminUserModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final timestamp = data['createdAt'];
    return AdminUserModel(
      id: doc.id,
      name: (data['name'] ?? data['displayName'] ?? 'Unnamed user').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? 'Customer').toString(),
      status: (data['status'] ?? 'Active').toString(),
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
