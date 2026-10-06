import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/admin_user_model.dart';
import 'admin_dashboard_screen.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => adminPage(
    'User management',
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('Unable to load users: ${snapshot.error}'));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return ListView(
          padding: const EdgeInsets.all(12),
          children: snapshot.data!.docs.map((doc) {
            final user = AdminUserModel.fromDocument(doc);
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(user.name),
                subtitle: Text('${user.email}\n${user.role}'),
                isThreeLine: true,
                trailing: Text(user.status),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserDetailScreen(user: user),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    ),
  );
}
