import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/customer_header.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  Future<void> _reset(BuildContext context) async {
    final ok = await confirmAction(context,
        title: 'Change password?', message: 'We will email you a secure link to set a new password.',
        confirmLabel: 'Send link');
    if (!ok || !context.mounted) return;
    await runAdminAction(context, CustomerRepository.instance.sendPasswordReset, success: 'Password reset link sent');
  }

  Widget _info(IconData icon, String title, String body) => AdminCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AdminColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: ts(13, w: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(body, style: ts(11.5, color: AdminColors.grey, height: 1.45)),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Privacy & Security', showBack: true),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            AdminButton('Change Password', kind: ButtonKind.filled, icon: Icons.password_rounded, height: 50,
                onPressed: () => _reset(context)),
            const SizedBox(height: 14),
            _info(Icons.visibility_outlined, 'Who sees your data',
                'Your name, address and notes are shared only with the provider on an active booking.'),
            const SizedBox(height: 10),
            _info(Icons.photo_camera_outlined, 'Photos',
                'Photos you send in chat or upload to your profile are stored securely and visible only to the people in that conversation.'),
            const SizedBox(height: 10),
            _info(Icons.payments_outlined, 'Payments',
                'HomeFix never stores card details. Jobs are paid in cash and confirmed by both parties.'),
          ]),
        ),
      ]),
    );
  }
}
