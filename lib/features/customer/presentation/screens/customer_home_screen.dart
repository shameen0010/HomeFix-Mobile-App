import 'package:flutter/material.dart';

import '../../../admin/data/models/service_category.dart';
import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/models/customer_profile.dart';
import '../../data/repositories/customer_repository.dart';
import '../../../admin/presentation/widgets/category_style.dart';
import '../widgets/customer_header.dart';
import '../widgets/provider_cards.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _repo = CustomerRepository.instance;
  late final Stream<CustomerProfile?> _me = _repo.watchMe();
  late final Stream<List<BookingInfo>> _bookings = _repo.watchMyBookings();
  late final Stream<List<ServiceCategory>> _cats = _repo.watchCategories();
  late final Stream<List<FeaturedService>> _featured = _repo.watchFeatured();
  late final Stream<List<ProviderProfile>> _providers = _repo.watchProviders();

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
  }

  Future<void> _editLocation(CustomerProfile me) async {
    final v = await promptText(context,
        title: 'Your location',
        hint: 'e.g. Nugegoda, Sri Lanka',
        initial: me.location,
        confirmLabel: 'Save');
    if (v == null || !mounted) return;
    await runAdminAction(context, () => _repo.updateLocation(v), success: 'Location updated');
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              StreamBuilder<CustomerProfile?>(
                stream: _me,
                builder: (context, snap) {
                  final me = snap.data;
                  return Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${_greeting()}, ${me?.firstName ?? ''}', style: ts(21, w: FontWeight.w700)),
                        GestureDetector(
                          onTap: me == null ? null : () => _editLocation(me),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.location_on_outlined, size: 15, color: AdminColors.primary),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                  (me?.location.isEmpty ?? true) ? 'Set your location' : me!.location,
                                  style: ts(12, w: FontWeight.w600, color: AdminColors.primary)),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AdminColors.primary),
                          ]),
                        ),
                      ]),
                    ),
                    const CustomerBell(),
                  ]);
                },
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => CustomerNav.goSearch(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AdminColors.border)),
                      child: Row(children: [
                        const Icon(Icons.search_rounded, color: AdminColors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Search plumber, electrician, cleaning...',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: ts(12.5, color: AdminColors.grey)),
                        ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AdminColors.border)),
                  child: IconButton(
                      onPressed: () => CustomerNav.goSearch(availableToday: true),
                      icon: const Icon(Icons.tune_rounded)),
                ),
              ]),
              const SizedBox(height: 14),
              _emergencyBanner(),
              const SizedBox(height: 12),
              _activeBooking(),
              const SizedBox(height: 18),
              SectionTitle('Categories',
                  trailing: TextButton(onPressed: () => CustomerNav.goSearch(), child: const Text('See all'))),
              _categories(),
              const SizedBox(height: 14),
              Text('Popular Services', style: ts(16, w: FontWeight.w700)),
              const SizedBox(height: 10),
              _featuredList(),
              const SizedBox(height: 18),
              Text('Top Service Provider', style: ts(16, w: FontWeight.w700)),
              Text('Verified background & instant confirmation', style: ts(11.5, color: AdminColors.grey)),
              const SizedBox(height: 10),
              _topProviders(),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _emergencyBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AdminColors.redBg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AdminColors.orange, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Need Help Now?', style: ts(15, w: FontWeight.w700, color: const Color(0xFFB91C1C))),
                  const SizedBox(width: 6),
                  const StatusPill('15-30 MIN', tone: Tone.orange, size: 9.5),
                ]),
                Text('Book an available service provider immediately',
                    style: ts(11, color: const Color(0xFFB91C1C))),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFB45309)),
            Expanded(child: Text('Fast dispatch on duty', style: ts(11, w: FontWeight.w600, color: const Color(0xFF92400E)))),
            AdminButton('Emergency Booking',
                kind: ButtonKind.filled, icon: Icons.arrow_forward_rounded, height: 38,
                onPressed: () => CustomerNav.goSearch(availableToday: true, emergency: true)),
          ]),
        ]),
      );

  Widget _activeBooking() => StreamBuilder<List<BookingInfo>>(
        stream: _bookings,
        builder: (context, snap) {
          final active = (snap.data ?? const <BookingInfo>[])
              .where((b) => b.status == 'confirmed' || b.status == 'in_progress')
              .toList();
          if (active.isEmpty) return const SizedBox.shrink();
          active.sort((a, b) => (a.scheduledAt ?? DateTime(2100)).compareTo(b.scheduledAt ?? DateTime(2100)));
          final b = active.first;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AdminColors.primary, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.build_circle_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.circle, size: 8, color: AdminColors.orange),
                    const SizedBox(width: 5),
                    Text('ACTIVE BOOKING', style: ts(9.5, w: FontWeight.w700, color: Colors.white70)),
                  ]),
                  Text(b.title, style: ts(16, w: FontWeight.w700, color: Colors.white)),
                  Text(formatDate(b.scheduledAt, 'EEE, h:mm a'), style: ts(11, color: Colors.white70)),
                ]),
              ),
              GestureDetector(
                onTap: () => CustomerNav.goTab(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Text('View Status', style: ts(11.5, w: FontWeight.w700, color: AdminColors.primary)),
                ),
              ),
            ]),
          );
        },
      );

  Widget _categories() => StreamBuilder<List<ServiceCategory>>(
        stream: _cats,
        builder: (context, snap) {
          if (snap.hasError) return Text('Could not load categories.', style: ts(12, color: AdminColors.red));
          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(20), child: LoadingView());
          final list = snap.data!.take(6).toList();
          if (list.isEmpty) return Text('No categories yet.', style: ts(12, color: AdminColors.grey));
          return GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              for (final c in list)
                GestureDetector(
                  onTap: () => CustomerNav.goSearch(category: c.name),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AdminColors.border)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircleAvatar(
                          radius: 20, backgroundColor: AdminColors.chipBg,
                          child: Icon(categoryStyle(c.icon).icon, color: AdminColors.primary, size: 20)),
                      const SizedBox(height: 6),
                      Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: ts(11.5, w: FontWeight.w600)),
                    ]),
                  ),
                ),
            ],
          );
        },
      );

  Widget _featuredList() => StreamBuilder<List<FeaturedService>>(
        stream: _featured,
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.isEmpty) {
            return Text('Popular services will appear here.', style: ts(12, color: AdminColors.grey));
          }
          return SizedBox(
            height: 190,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in snap.data!)
                  GestureDetector(
                    onTap: () => CustomerNav.goSearch(category: f.category.isEmpty ? null : f.category),
                    child: Container(
                      width: 210,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AdminColors.border)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: SizedBox(
                            height: 110, width: double.infinity,
                            child: (f.imageUrl == null || f.imageUrl!.isEmpty)
                                ? Container(color: AdminColors.chipBg,
                                    child: const Icon(Icons.home_repair_service_rounded, color: AdminColors.primary, size: 36))
                                : Image.network(f.imageUrl!, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: AdminColors.field)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(f.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: ts(13.5, w: FontWeight.w700)),
                            Text(f.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: ts(11, color: AdminColors.grey)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          );
        },
      );

  Widget _topProviders() => StreamBuilder<List<ProviderProfile>>(
        stream: _providers,
        builder: (context, snap) {
          if (snap.hasError) return Text('Could not load providers.', style: ts(12, color: AdminColors.red));
          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(20), child: LoadingView());
          final list = [...snap.data!]..sort((a, b) => b.rating.compareTo(a.rating));
          if (list.isEmpty) {
            return const EmptyView(message: 'No verified providers yet', icon: Icons.engineering_outlined);
          }
          return Column(children: [
            for (final p in list.take(5))
              Padding(padding: const EdgeInsets.only(bottom: 12), child: TopProviderCard(provider: p)),
          ]);
        },
      );
}
