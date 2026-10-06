import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderProfileService {
  ProviderProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> saveProviderProfile({
    required String providerId,
    required String name,
    required String email,
    required String phone,
    required List<String> categories,
  }) async {
    final primaryCategory = categories.isEmpty ? 'service_provider' : categories.first;
    await _firestore.collection('providers').doc(providerId).set({
      'userId': providerId,
      'name': name,
      'email': email,
      'phone': phone,
      'category': primaryCategory,
      'serviceType': primaryCategory,
      'specialty': primaryCategory,
      'area': '',
      'hourlyRate': 0,
      'rating': 0,
      'reviewCount': 0,
      'yearsExp': 0,
      'jobsDone': 0,
      'onTime': 0,
      'availableToday': true,
      'bio': '',
      'verificationStatus': 'pending',
      'status': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final services = _firestore.collection('services');
    for (final category in categories) {
      final reference = services.doc('${providerId}_$category');
      await reference.set({
        'providerId': providerId,
        'title': _serviceTitle(category),
        'subtitle': _serviceSubtitle(category),
        'category': category,
        'price': 0,
        'unit': '/job',
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  String _serviceTitle(String category) {
    switch (category) {
      case 'plumber':
        return 'Plumbing Service';
      case 'electrician':
        return 'Electrical Service';
      case 'cleaner':
        return 'Home Cleaning';
      case 'carpenter':
        return 'Carpentry Service';
      case 'painter':
        return 'Painting Service';
      case 'appliance_repair':
        return 'Appliance Repair';
      default:
        return 'Home Service';
    }
  }

  String _serviceSubtitle(String category) {
    switch (category) {
      case 'plumber':
        return 'Pipes, leaks and drains';
      case 'electrician':
        return 'Wiring, fixtures and panels';
      case 'cleaner':
        return 'Deep cleaning and turnover';
      default:
        return 'Professional home service';
    }
  }
}
