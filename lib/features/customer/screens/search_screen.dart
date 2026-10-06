import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/hf_theme.dart';
import '../../../core/widgets/hf_widgets.dart';

class FirestoreSearchScreen extends StatefulWidget {
  const FirestoreSearchScreen({super.key, this.initial});
  final String? initial;

  @override
  State<FirestoreSearchScreen> createState() => _FirestoreSearchScreenState();
}

class _FirestoreSearchScreenState extends State<FirestoreSearchScreen> {
  late final TextEditingController _search =
      TextEditingController(text: widget.initial ?? '');
  String _category = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('providers')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Unable to load providers: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final query = _search.text.trim().toLowerCase();
          final providers = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final name = (data['name'] ?? '').toString().toLowerCase();
            final service = (data['serviceType'] ?? '').toString().toLowerCase();
            final category = _category.toLowerCase();
            final matchesCategory = _category == 'All' ||
                service.contains(category) ||
                (data['category'] ?? '').toString().toLowerCase().contains(category);
            return matchesCategory &&
                (query.isEmpty || name.contains(query) || service.contains(query));
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const HfScreenHeader(title: 'HomeFix'),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search plumber, electrician, cleaner',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final category in ['All', 'Plumber', 'Electrician', 'Cleaner'])
                    HfPill(
                      label: category,
                      selected: _category == category,
                      onTap: () => setState(() => _category = category),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Approved providers (${providers.length})',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              if (providers.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('No approved providers found.')),
                ),
              for (final provider in providers) _providerCard(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _providerCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final name = (data['name'] ?? data['displayName'] ?? 'Provider').toString();
    final service = (data['serviceType'] ?? data['category'] ?? 'Home service').toString();
    final rating = (data['rating'] as num?)?.toDouble() ?? 0;
    final reviews = (data['reviewCount'] as num?)?.toInt() ?? 0;
    final hourlyRate = (data['hourlyRate'] as num?)?.toDouble() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HfAvatar(
                  url: data['avatarUrl'] as String?,
                  fallback: name,
                  size: 52,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(service, style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                      Row(
                        children: [
                          HfStars(value: rating),
                          Text(' ($reviews reviews)', style: const TextStyle(fontSize: 12, color: HfColors.muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Rs. ${hourlyRate.toStringAsFixed(0)} / service'),
            const SizedBox(height: 10),
            HfPrimaryButton(
              label: 'View Profile  →',
              onPressed: () => context.push('/provider/${document.id}'),
            ),
          ],
        ),
      ),
    );
  }
}
