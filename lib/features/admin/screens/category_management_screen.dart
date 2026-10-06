import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});
  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final controller = TextEditingController();
  bool saving = false;
  Future<void> addCategory() async {
    if (controller.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('categories').add({
        'name': controller.text.trim(),
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      controller.clear();
    } catch (error) {
      if (mounted) showAdminError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => adminPage(
    'Category management',
    Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'New category'),
                ),
              ),
              IconButton(
                onPressed: saving ? null : addCategory,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('categories')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return ListView(
                children: snapshot.data!.docs
                    .map(
                      (doc) => ListTile(
                        title: Text((doc.data()['name'] ?? '').toString()),
                        trailing: Switch(
                          value: doc.data()['active'] != false,
                          onChanged: (value) async {
                            try {
                              await doc.reference.update({'active': value});
                            } catch (error) {
                              if (context.mounted)
                                showAdminError(context, error);
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    ),
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
