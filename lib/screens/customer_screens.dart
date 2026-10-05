import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/hf_theme.dart';
import '../../core/widgets/hf_widgets.dart';
import '../../data/homefix_store.dart';
import '../../data/models.dart';
import 'booking_screens.dart';

const customerNav = [
  HfNavItem(Icons.home_outlined, 'Home'),
  HfNavItem(Icons.search_rounded, 'Search'),
  HfNavItem(Icons.calendar_month_outlined, 'Bookings'),
  HfNavItem(Icons.chat_bubble_outline_rounded, 'Messages'),
  HfNavItem(Icons.person_outline_rounded, 'Profile'),
];

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: HfBottomNav(
        items: customerNav,
        index: index,
        onTap: (i) {
          context.go(['/c/home', '/c/search', '/c/bookings', '/c/messages', '/c/profile'][i]);
        },
      ),
    );
  }
}

class CustomerDashboard extends ConsumerWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.session;
    final active = state.bookings.where((b) => b.status == BookingStatus.inProgress).toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              const HfBrandMark(compact: true),
              const Spacer(),
              IconButton(onPressed: () => context.push('/c/notifications'), icon: const Icon(Icons.notifications_none_rounded)),
              const CircleAvatar(backgroundColor: HfColors.primary, radius: 16, child: Icon(Icons.person, color: Colors.white, size: 18)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Good morning, ${user?.firstName ?? 'there'} 👋', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800)),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: HfColors.success),
              Text(user?.location.isEmpty == false ? user!.location : 'Nugegoda, Sri Lanka', style: const TextStyle(color: HfColors.muted, fontSize: 13)),
              const Icon(Icons.expand_more, size: 16, color: HfColors.muted),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.go('/c/search'),
            child: const AbsorbPointer(
              child: HfField(label: '', hint: 'Search plumber, electrician, cleaning', icon: Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFF3E6), Color(0xFFFFE1C4)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.wb_sunny_outlined, color: HfColors.emergency), SizedBox(width: 6), HfBadge(label: '15–30 MIN', tone: BadgeTone.orange)]),
                      const SizedBox(height: 6),
                      Text('Need Help Now?', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
                      const Text('Book an available service provider immediately.', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      const Text('⚡ Fast dispatch on duty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/emergency'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HfColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Emergency\nBooking', textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: HfColors.primary, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.ac_unit, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ACTIVE BOOKING', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.6)),
                        Text(active.first.serviceTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        Text(active.first.scheduledLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  HfSoftButton(
                    label: 'View Status',
                    onPressed: () => context.push('/booking/${active.first.id}'),
                    color: Colors.white,
                    foreground: HfColors.primary,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Categories', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
              const Spacer(),
              TextButton(onPressed: () => context.go('/c/search'), child: const Text('See all')),
            ],
          ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              _cat(context, ref, Icons.plumbing, 'Plumbing'),
              _cat(context, ref, Icons.bolt_outlined, 'Electrical'),
              _cat(context, ref, Icons.cleaning_services_outlined, 'Cleaning'),
              _cat(context, ref, Icons.carpenter_outlined, 'Carpenter'),
              _cat(context, ref, Icons.format_paint_outlined, 'Painter'),
              _cat(context, ref, Icons.kitchen_outlined, 'Appliance'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Popular Services', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _PromoCard(title: 'Deep Home Cleaning', subtitle: 'Full sanitization & dusting', image: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400'),
                _PromoCard(title: 'Pipe Leak Repair', subtitle: 'Diagnosis & rapid fix', image: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Top Service Provider', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
          const Text('Verified background & instant confirmation', style: TextStyle(color: HfColors.muted, fontSize: 12)),
          const SizedBox(height: 8),
          for (final p in state.providers.take(2)) _providerRow(context, ref, state, p),
        ],
      ),
    );
  }

  Widget _cat(BuildContext context, WidgetRef ref, IconData icon, String name) {
    return HfCard(
      onTap: () {
        context.go('/c/search?q=$name');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(backgroundColor: HfColors.primarySoft, child: Icon(icon, color: HfColors.primary)),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _providerRow(BuildContext context, WidgetRef ref, HomefixState state, ProviderProfile p) {
    final user = state.users.firstWhere((u) => u.id == p.userId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HfCard(
        child: Column(
          children: [
            Row(
              children: [
                HfAvatar(url: user.avatarUrl, fallback: user.name),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(p.specialty, style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                      Text('${p.distanceMiles} mi away  •  Rs.${p.hourlyRate.toStringAsFixed(0)}00/day', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                HfStars(value: p.rating),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: HfSoftButton(label: 'View Profile', onPressed: () => context.push('/provider/${p.userId}'))),
                const SizedBox(width: 8),
                Expanded(
                  child: HfPrimaryButton(
                    label: 'Book Now',
                    onPressed: () {
                      final d = ref.read(draftProvider).copy();
                      d.providerId = p.userId;
                      d.amount = p.hourlyRate;
                      d.serviceTitle = p.specialty.contains('Clean') ? 'Deep Home Cleaning' : 'Pipe Leakage Repair';
                      ref.read(draftProvider.notifier).set(d);
                      context.push('/book/schedule');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.title, required this.subtitle, required this.image});
  final String title;
  final String subtitle;
  final String image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)]),
        ),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initial});
  final String? initial;
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final controller = TextEditingController(text: widget.initial ?? 'Plumber');
  String filter = 'Top Rated';
  String sort = 'Nearest';

  @override
  Widget build(BuildContext context) {
    final q = controller.text.toLowerCase();
    final state = ref.watch(homefixStoreProvider);
    final results = state.providers.where((p) {
      final user = state.users.firstWhere((u) => u.id == p.userId);
      return user.name.toLowerCase().contains(q) || p.specialty.toLowerCase().contains(q) || q.contains('plumb') || q.isEmpty;
    }).toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const HfScreenHeader(title: 'HomeFix'),
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Plumber',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(onPressed: () => controller.clear(), icon: const Icon(Icons.close)),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in ['All', 'Top Rated', 'Available Today', 'Nearby'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: HfPill(label: f, selected: filter == f, icon: f == 'Top Rated' ? Icons.star : null, onTap: () => setState(() => filter = f)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Categories', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _miniCat('Plumber', '28', true),
                _miniCat('Electrician', '19', false),
                _miniCat('Cleaner', '14', false),
                _miniCat('Carpenter', '12', false),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Vetted Plumbers (${results.length} available)', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final p in results)
            _result(context, ref, state, p),
        ],
      ),
    );
  }

  Widget _miniCat(String name, String count, bool selected) {
    return Container(
      width: 92,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? HfColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HfColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count, style: TextStyle(color: selected ? Colors.white70 : HfColors.muted, fontSize: 11)),
          const Spacer(),
          Text(name, style: TextStyle(color: selected ? Colors.white : HfColors.navy, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _result(BuildContext context, WidgetRef ref, HomefixState state, ProviderProfile p) {
    final user = state.users.firstWhere((u) => u.id == p.userId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HfAvatar(url: user.avatarUrl, fallback: user.name, size: 52),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(p.specialty, style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                      Row(children: [HfStars(value: p.rating), Text(' (${p.reviewCount} reviews)', style: const TextStyle(fontSize: 12, color: HfColors.muted))]),
                    ],
                  ),
                ),
                const Icon(Icons.favorite_border),
              ],
            ),
            const SizedBox(height: 8),
            Text('📍 ${p.distanceMiles} miles away   \$${p.hourlyRate.toStringAsFixed(0)} /hr   ${p.availableToday ? 'Available Today' : 'Next: Tomorrow'}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: HfPrimaryButton(
                    label: 'View Profile  →',
                    onPressed: () => context.push('/provider/${p.userId}'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => context.go('/c/messages'),
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesInboxScreen extends ConsumerWidget {
  const MessagesInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homefixStoreProvider);
    final bookings = state.bookings;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const HfScreenHeader(title: 'Messages'),
          for (final b in bookings)
            ListTile(
              onTap: () => context.push('/chat/${b.id}'),
              leading: HfAvatar(url: state.users.firstWhere((u) => u.id == b.providerId).avatarUrl, fallback: 'P'),
              title: Text(state.users.firstWhere((u) => u.id == b.providerId).name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(b.serviceTitle),
              trailing: const HfBadge(label: 'Active', tone: BadgeTone.green),
            ),
        ],
      ),
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.bookingId});
  final String bookingId;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final text = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final booking = state.bookings.firstWhere((b) => b.id == widget.bookingId, orElse: () => state.bookings.first);
    final provider = state.users.firstWhere((u) => u.id == booking.providerId);
    final me = state.session!;
    final msgs = state.messages.where((m) => m.bookingId == booking.id).toList();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HfScreenHeader(title: 'Chat Conversation', onBack: () => context.pop()),
            HfCard(
              child: Row(
                children: [
                  HfAvatar(url: provider.avatarUrl, fallback: provider.name),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${provider.name} ✓', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const Text('ACTIVE NOW  •  ★ 4.9', style: TextStyle(color: HfColors.success, fontSize: 11)),
                      ],
                    ),
                  ),
                  const CircleAvatar(backgroundColor: HfColors.field, child: Icon(Icons.call_outlined, color: HfColors.primary)),
                  const SizedBox(width: 8),
                  const CircleAvatar(backgroundColor: HfColors.field, child: Icon(Icons.near_me_outlined, color: HfColors.primary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: HfCard(
                color: HfColors.primarySoft,
                child: Row(
                  children: [
                    const Icon(Icons.plumbing, color: HfColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${booking.serviceTitle}\n${booking.scheduledLabel}')),
                    const HfBadge(label: 'EN ROUTE', tone: BadgeTone.orange),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final m in msgs) _bubble(m, me.id),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.photo_outlined, color: HfColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: text,
                      decoration: const InputDecoration(hintText: 'Type a message...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: HfColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () {
                        if (text.text.trim().isEmpty) return;
                        ref.read(homefixStoreProvider.notifier).sendMessage(booking.id, me.id, text.text.trim());
                        text.clear();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage m, String meId) {
    if (m.system) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: HfColors.primarySoft, borderRadius: BorderRadius.circular(16)),
          child: Text(m.text),
        ),
      );
    }
    final mine = m.fromId == meId;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine ? HfColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.text, style: TextStyle(color: mine ? Colors.white : HfColors.navy)),
            if (m.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(m.imageUrl!, height: 90, fit: BoxFit.cover),
                ),
              ),
            Text(m.time, style: TextStyle(color: mine ? Colors.white70 : HfColors.muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.session!;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const HfScreenHeader(title: 'Profile'),
          HfCard(
            child: Column(
              children: [
                HfAvatar(url: user.avatarUrl, size: 84, fallback: user.name),
                const SizedBox(height: 8),
                Text(user.name, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20)),
                const HfBadge(label: 'VERIFIED MEMBER', tone: BadgeTone.teal),
                Text(user.email, style: const TextStyle(color: HfColors.muted)),
                Text(user.phone, style: const TextStyle(color: HfColors.muted)),
                const SizedBox(height: 10),
                HfPrimaryButton(label: 'Edit Profile', icon: Icons.edit_outlined, onPressed: () => hfSnack(context, 'Profile editor saved locally.')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat('14', 'Completed'),
              _stat('1', 'In Progress'),
              _stat('2', 'Locations'),
            ],
          ),
          const SizedBox(height: 12),
          _row(Icons.location_on_outlined, 'My Addresses', 'Home (Oak Crest), Office (Downtown)'),
          _row(Icons.payments_outlined, 'Payment Methods', 'Visa ending in 8842 • Cash default'),
          _row(Icons.emergency_outlined, 'Emergency Contacts & Notes', 'Gate codes, pet safety, secondary phone'),
          SwitchListTile(
            value: state.alertsOn,
            onChanged: (_) => ref.read(homefixStoreProvider.notifier).toggleAlerts(),
            title: const Text('Service Status Alerts'),
            subtitle: const Text('SMS and live technician push updates'),
          ),
          _row(Icons.help_outline, 'Help & Support / FAQs', '24/7 HomeFix customer care helpline'),
          _row(Icons.shield_outlined, 'Privacy & Security', 'Data permissions, biometric login'),
          const SizedBox(height: 8),
          HfSoftButton(
            label: 'Log Out',
            icon: Icons.logout,
            color: HfColors.primarySoft,
            onPressed: () {
              ref.read(homefixStoreProvider.notifier).logout();
              context.go('/login');
            },
          ),
          const SizedBox(height: 8),
          const Center(child: Text('HomeFix v2.4.1 • Safe Home Guarantee', style: TextStyle(color: HfColors.muted, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _stat(String n, String l) {
    return Expanded(
      child: HfCard(
        child: Column(
          children: [
            Text(n, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20)),
            Text(l, style: const TextStyle(fontSize: 11, color: HfColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String title, String sub) {
    return HfCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: HfColors.field, child: Icon(icon, color: HfColors.primary)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class ProviderPublicProfile extends ConsumerWidget {
  const ProviderPublicProfile({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homefixStoreProvider);
    final user = state.users.firstWhere((u) => u.id == userId);
    final p = state.providers.firstWhere((x) => x.userId == userId);
    final offerings = state.services.where((s) => s.providerId == userId).toList();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            HfScreenHeader(title: 'Service Detail', onBack: () => context.pop()),
            HfCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      HfAvatar(url: user.avatarUrl, size: 64, fallback: user.name),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                            Text(p.specialty, style: const TextStyle(color: HfColors.muted)),
                            Text('📍 ${p.area} • ${p.distanceMiles} mi away', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      HfBadge(label: '${p.yearsExp} Yrs Exp', tone: BadgeTone.orange),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(children: [HfStars(value: p.rating), Text(' (${p.reviewCount} verified reviews)  '), const HfBadge(label: 'Top Rated Pro', tone: BadgeTone.orange)]),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _m('${p.jobsDone}+', 'Jobs Done'),
                _m('${p.onTime}%', 'On-time'),
                _m(p.rating.toStringAsFixed(1), 'Avg Rating'),
              ],
            ),
            const SizedBox(height: 12),
            Text('Select Service', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
            for (final s in offerings)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: HfCard(
                  color: s == offerings.first ? HfColors.primarySoft : Colors.white,
                  onTap: () {
                    final d = ref.read(draftProvider).copy();
                    d.providerId = userId;
                    d.serviceTitle = s.title;
                    d.amount = s.price;
                    d.category = s.category;
                    ref.read(draftProvider.notifier).set(d);
                  },
                  child: Row(
                    children: [
                      const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.home_repair_service_outlined, color: HfColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(s.subtitle, style: const TextStyle(fontSize: 12, color: HfColors.muted))])),
                      Text('\$${s.price.toStringAsFixed(0)}${s.unit}', style: const TextStyle(fontWeight: FontWeight.w800, color: HfColors.primary)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text('About ${user.firstName}', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
            Text(p.bio, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 12),
            const Text('Customer Reviews', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            const HfCard(
              child: Text('Sarah Jenkins  •  2 days ago • Cobble Hill\nDavid fixed our kitchen leak in under 30 minutes! Very professional.'),
            ),
            const SizedBox(height: 16),
            HfPrimaryButton(
              label: 'Book this provider  →',
              onPressed: () => context.push('/booking-schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _m(String n, String l) {
    return Expanded(
      child: HfCard(
        child: Column(children: [Text(n, style: const TextStyle(fontWeight: FontWeight.w800)), Text(l, style: const TextStyle(fontSize: 11, color: HfColors.muted))]),
      ),
    );
  }
}

class CustomerBookingsScreen extends ConsumerStatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  ConsumerState<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends ConsumerState<CustomerBookingsScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Upcoming', 'Active', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final bookings = state.bookings.where((b) => b.customerId == state.session?.id).toList();

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const HfBrandMark(compact: true),
                const Spacer(),
                CircleAvatar(
                  backgroundColor: HfColors.primary,
                  radius: 20,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ],
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Bookings', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Manage your service bookings', style: TextStyle(color: HfColors.muted, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedTab == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: HfPill(
                    label: _tabs[index],
                    selected: isSelected,
                    onTap: () => setState(() => _selectedTab = index),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Booking list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (bookings.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: HfColors.muted),
                        const SizedBox(height: 16),
                        Text('No bookings yet', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('Book your first service to get started', style: TextStyle(color: HfColors.muted)),
                        const SizedBox(height: 16),
                        HfPrimaryButton(
                          label: 'Book a Service',
                          onPressed: () => context.go('/c/search'),
                        ),
                      ],
                    ),
                  )
                else
                  for (final booking in bookings) _BookingCard(context, ref, booking),
                const SizedBox(height: 80),
              ],
            ),
          ),
          // Bottom navigation
          HfBottomNav(
            items: customerNav,
            index: 2,
            onTap: (i) {
              context.go(['/c/home', '/c/search', '/c/bookings', '/c/messages', '/c/profile'][i]);
            },
          ),
        ],
      ),
    );
  }

  Widget _BookingCard(BuildContext context, WidgetRef ref, Booking booking) {
    final statusColor = switch (booking.status) {
      BookingStatus.pending => HfColors.orange,
      BookingStatus.accepted => HfColors.info,
      BookingStatus.scheduled => HfColors.primary,
      BookingStatus.inProgress => HfColors.success,
      BookingStatus.completed => HfColors.grey,
      BookingStatus.cancelled => HfColors.danger,
    };

    final statusLabel = switch (booking.status) {
      BookingStatus.pending => 'PENDING',
      BookingStatus.accepted => 'ACCEPTED',
      BookingStatus.scheduled => 'SCHEDULED',
      BookingStatus.inProgress => 'IN PROGRESS',
      BookingStatus.completed => 'COMPLETED',
      BookingStatus.cancelled => 'CANCELLED',
    };

    return HfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: HfColors.primarySoft,
                radius: 28,
                child: const Icon(Icons.home_repair_service_outlined, color: HfColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.serviceTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('David Smith', style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              HfBadge(label: statusLabel, tone: BadgeTone.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: HfColors.muted),
              const SizedBox(width: 4),
              Text(booking.scheduledLabel, style: const TextStyle(fontSize: 12, color: HfColors.muted)),
              const Spacer(),
              Text('Rs. ${booking.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HfSoftButton(
                  label: 'View Details',
                  onPressed: () {
                    context.push('/booking-checkout/${booking.id}');
                  },
                ),
              ),
              if (booking.status == BookingStatus.pending || booking.status == BookingStatus.accepted) ...[
                const SizedBox(width: 8),
                HfSoftButton(
                  label: 'Cancel',
                  color: HfColors.danger.withValues(alpha: 0.1),
                  foreground: HfColors.danger,
                  onPressed: () {
                    context.push('/cancel-booking/${booking.id}');
                  },
                ),
              ],
            ],
          ),
          if (booking.status == BookingStatus.inProgress || booking.status == BookingStatus.scheduled) ...[
            const SizedBox(height: 8),
            HfPrimaryButton(
              label: 'Track Status',
              onPressed: () {
                context.push('/booking-checkout/${booking.id}');
              },
            ),
          ],
        ],
      ),
    );
  }
}
