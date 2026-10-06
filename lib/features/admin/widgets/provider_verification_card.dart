import 'package:flutter/material.dart';

import '../models/provider_verification_model.dart';
import 'status_badge_chip.dart';

class ProviderVerificationCard extends StatelessWidget {
  final ProviderVerificationModel provider;
  final VoidCallback? onTap;
  final Future<void> Function(String status)? onDecision;
  const ProviderVerificationCard({
    super.key,
    required this.provider,
    this.onTap,
    this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(
            provider.name.isEmpty ? '?' : provider.name[0].toUpperCase(),
          ),
        ),
        title: Text(
          provider.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(provider.category),
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusBadgeChip(status: provider.status),
            if (onDecision != null &&
                provider.status.toLowerCase() == 'pending')
              PopupMenuButton<String>(
                onSelected: onDecision,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'approved', child: Text('Approve')),
                  PopupMenuItem(value: 'rejected', child: Text('Reject')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
