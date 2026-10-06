import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/provider_verification_model.dart';
import '../widgets/provider_verification_card.dart';
import 'admin_dashboard_screen.dart';
import 'provider_dossier_screen.dart';

class ProviderVerificationScreen extends StatelessWidget {
  const ProviderVerificationScreen({super.key});
  Future<void> _decide(
    BuildContext context,
    ProviderVerificationModel provider,
    String status,
  ) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('providers')
          .doc(provider.id);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) throw StateError('Provider no longer exists');
        transaction.update(ref, {
          'verificationStatus': status,
          'status': status,
          'verifiedAt': FieldValue.serverTimestamp(),
        });
      });
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Provider $status')));
    } catch (error) {
      if (context.mounted) showAdminError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => adminPage(
    'Provider operations',
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('providers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Text('Unable to load providers: ${snapshot.error}'),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return ListView(
          padding: const EdgeInsets.all(12),
          children: snapshot.data!.docs.map((doc) {
            final provider = ProviderVerificationModel.fromDocument(doc);
            return ProviderVerificationCard(
              provider: provider,
              onDecision: (status) => _decide(context, provider, status),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderDossierScreen(provider: provider),
                ),
              ),
            );
          }).toList(),
        );
      },
    ),
  );
}
