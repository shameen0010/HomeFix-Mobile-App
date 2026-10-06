import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/admin_user_model.dart';
import 'admin_dashboard_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final AdminUserModel user;
  const UserDetailScreen({super.key, required this.user});
  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool saving = false;
  Future<void> _setStatus(String status) async {
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'status': status});
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('User $status')));
    } catch (error) {
      if (mounted) showAdminError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('User details')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(widget.user.name),
          subtitle: Text(widget.user.email),
        ),
        const Divider(),
        Text('Role: ${widget.user.role}'),
        Text('Status: ${widget.user.status}'),
        const SizedBox(height: 24),
        if (saving) const LinearProgressIndicator(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : () => _setStatus('Suspended'),
                child: const Text('Suspend'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: saving ? null : () => _setStatus('Active'),
                child: const Text('Activate'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
