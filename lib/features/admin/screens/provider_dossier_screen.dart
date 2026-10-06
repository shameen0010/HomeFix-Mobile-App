import 'package:flutter/material.dart';

import '../models/provider_verification_model.dart';

class ProviderDossierScreen extends StatelessWidget {
  final ProviderVerificationModel provider;
  const ProviderDossierScreen({super.key, required this.provider});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Provider dossier')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 36,
          child: Text(provider.name.isEmpty ? '?' : provider.name[0]),
        ),
        const SizedBox(height: 12),
        Text(provider.name, style: Theme.of(context).textTheme.headlineSmall),
        Text(provider.category),
        const Divider(height: 32),
        Text('Status: ${provider.status}'),
        Text(
          'Phone: ${provider.phone.isEmpty ? 'Not supplied' : provider.phone}',
        ),
        const SizedBox(height: 16),
        Text(provider.bio.isEmpty ? 'No biography supplied.' : provider.bio),
      ],
    ),
  );
}
