import 'package:flutter/material.dart';

import '../../../admin/data/models/service_category.dart';
import '../../../admin/presentation/widgets/category_style.dart';
import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/availability.dart';
import '../widgets/customer_header.dart';
import '../widgets/provider_cards.dart';

enum _Chip { all, topRated, availableToday, lowestPrice }

enum _Sort { rating, price, experience }

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final _repo = CustomerRepository.instance;
  final _controller = TextEditingController();
  late final Stream<List<ProviderProfile>> _providers = _repo.watchProviders();
  late final Stream<List<ServiceCategory>> _cats = _repo.watchCategories();
  late final Stream<Set<String>> _favorites = _repo.watchFavorites();
  _Chip _chip = _Chip.all;
  _Sort _sort = _Sort.rating;
  String? _category;
  bool _emergency = false;

  @override
  void initState() {
    super.initState();
    CustomerNav.search.addListener(_applyIntent);
    _applyIntent();
  }

  @override
  void dispose() {
    CustomerNav.search.removeListener(_applyIntent);
    _controller.dispose();
    super.dispose();
  }

  void _applyIntent() {
    final i = CustomerNav.search.value;
    if (i.token == 0 && !mounted) return;
    setState(() {
      _controller.text = i.query;
      _category = i.category;
      _emergency = i.emergency;
      _chip = i.availableToday ? _Chip.availableToday : _Chip.all;
    });
  }

  bool _inCategory(ProviderProfile p, String cat) {
    final c = cat.toLowerCase();
    return p.trade.toLowerCase() == c || p.trades.any((t) => t.toLowerCase() == c);
  }

  List<ProviderProfile> _filter(List<ProviderProfile> all) {
    final q = _controller.text.trim().toLowerCase();
    var list = all.where((p) {
      if (_category != null && !_inCategory(p, _category!)) return false;
      if (q.isNotEmpty &&
          !(p.name.toLowerCase().contains(q) ||
              p.trade.toLowerCase().contains(q) ||
              p.headline.toLowerCase().contains(q) ||
              p.trades.any((t) => t.toLowerCase().contains(q)))) {
        return false;
      }
      switch (_chip) {
        case _Chip.topRated:
          return p.rating >= 4.5;
        case _Chip.availableToday:
          return availabilityOf(p).today;
        default:
          return true;
      }
    }).toList();
    int cmpPrice(ProviderProfile a, ProviderProfile b) =>
        (startingRate(a) ?? 1e9).compareTo(startingRate(b) ?? 1e9);
    if (_chip == _Chip.lowestPrice || _sort == _Sort.price) {
      list.sort(cmpPrice);
    } else if (_sort == _Sort.experience) {
      list.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
    } else {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(),
        Expanded(
          child: StreamBuilder<List<ProviderProfile>>(
            stream: _providers,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load providers.\n${snap.error}');
              if (!snap.hasData) return const LoadingView();
              final all = snap.data!;
              final shown = _filter(all);
              final availableCount = shown.where((p) => availabilityOf(p).today).length;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    style: ts(13.5),
                    decoration: InputDecoration(
                      hintText: 'Search plumber, electrician, cleaning...',
                      hintStyle: ts(12.5, color: AdminColors.grey),
                      prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.primary),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => setState(_controller.clear),
                              icon: const Icon(Icons.close_rounded)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AdminColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AdminColors.primary)),
                    ),
                  ),
                  if (_emergency) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AdminColors.redBg, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.crisis_alert_rounded, color: AdminColors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Emergency booking: pick an available provider for fast dispatch.',
                              style: ts(11.5, color: const Color(0xFF7F1D1D))),
                        ),
                        InkWell(
                          onTap: () => setState(() => _emergency = false),
                          child: const Icon(Icons.close_rounded, size: 18, color: AdminColors.red),
                        ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      AdminChoiceChip(label: 'All', selected: _chip == _Chip.all, onTap: () => setState(() => _chip = _Chip.all)),
                      AdminChoiceChip(label: 'Top Rated', selected: _chip == _Chip.topRated, onTap: () => setState(() => _chip = _Chip.topRated)),
                      AdminChoiceChip(label: 'Available Today', selected: _chip == _Chip.availableToday, onTap: () => setState(() => _chip = _Chip.availableToday)),
                      AdminChoiceChip(label: 'Lowest Price', selected: _chip == _Chip.lowestPrice, onTap: () => setState(() => _chip = _Chip.lowestPrice)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  SectionTitle('Categories',
                      trailing: TextButton(
                          onPressed: () => setState(() => _category = null), child: const Text('See All'))),
                  _categoryRow(all),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: Text(
                          _category == null ? 'Vetted Providers' : 'Vetted ${_category}s',
                          style: ts(16, w: FontWeight.w700)),
                    ),
                    Text('($availableCount available)', style: ts(11, color: AdminColors.grey)),
                  ]),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 190,
                      child: AdminDropdown<_Sort>(
                        label: 'Sort',
                        value: _sort,
                        items: const {
                          _Sort.rating: 'Rating',
                          _Sort.price: 'Price (low to high)',
                          _Sort.experience: 'Experience',
                        },
                        onChanged: (v) => setState(() => _sort = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (shown.isEmpty)
                    const EmptyView(message: 'No providers match your search', icon: Icons.search_off_rounded)
                  else
                    StreamBuilder<Set<String>>(
                      stream: _favorites,
                      builder: (context, fav) {
                        final favs = fav.data ?? <String>{};
                        return Column(children: [
                          for (final p in shown)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ProviderListCard(
                                provider: p,
                                emergency: _emergency,
                                isFavorite: favs.contains(p.id),
                                onFavorite: () => runAdminAction(
                                    context, () => _repo.toggleFavorite(p.id, !favs.contains(p.id)),
                                    success: favs.contains(p.id) ? 'Removed from favourites' : 'Saved to favourites',
                                    showLoader: false),
                              ),
                            ),
                        ]);
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _categoryRow(List<ProviderProfile> all) => StreamBuilder<List<ServiceCategory>>(
        stream: _cats,
        builder: (context, snap) {
          final cats = snap.data ?? const <ServiceCategory>[];
          if (cats.isEmpty) return Text('No categories yet.', style: ts(12, color: AdminColors.grey));
          return SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in cats)
                  Builder(builder: (context) {
                    final selected = _category?.toLowerCase() == c.name.toLowerCase();
                    final inCat = all.where((p) => _inCategory(p, c.name)).toList();
                    return GestureDetector(
                      onTap: () => setState(() => _category = selected ? null : c.name),
                      child: Container(
                        width: 92,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: selected ? AdminColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selected ? AdminColors.primary : AdminColors.border),
                        ),
                        child: Stack(children: [
                          Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: selected ? Colors.white24 : AdminColors.chipBg,
                                child: Icon(categoryStyle(c.icon).icon, size: 18,
                                    color: selected ? Colors.white : AdminColors.primary),
                              ),
                              const SizedBox(height: 6),
                              Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: ts(11.5, w: FontWeight.w600, color: selected ? Colors.white : AdminColors.dark)),
                              if (selected)
                                Text('${inCat.where((p) => availabilityOf(p).today).length} available',
                                    style: ts(9.5, color: Colors.white70)),
                            ]),
                          ),
                          Positioned(
                            right: 6, top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                  color: selected ? AdminColors.orange : AdminColors.field,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('${inCat.length}',
                                  style: ts(9.5, w: FontWeight.w700,
                                      color: selected ? Colors.white : AdminColors.grey)),
                            ),
                          ),
                        ]),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      );
}
