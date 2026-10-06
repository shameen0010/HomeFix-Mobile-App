import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderVerificationModel {
  final String id;
  final String name;
  final String category;
  final String status;
  final String phone;
  final String bio;
  final DateTime? submittedAt;

  const ProviderVerificationModel({
    required this.id,
    required this.name,
    this.category = 'Service provider',
    this.status = 'pending',
    this.phone = '',
    this.bio = '',
    this.submittedAt,
  });

  factory ProviderVerificationModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final timestamp = data['submittedAt'] ?? data['createdAt'];
    return ProviderVerificationModel(
      id: doc.id,
      name: (data['name'] ?? data['displayName'] ?? 'Unnamed provider')
          .toString(),
      category: (data['category'] ?? data['serviceType'] ?? 'Service provider')
          .toString(),
      status: (data['verificationStatus'] ?? data['status'] ?? 'pending')
          .toString(),
      phone: (data['phone'] ?? '').toString(),
      bio: (data['bio'] ?? '').toString(),
      submittedAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
