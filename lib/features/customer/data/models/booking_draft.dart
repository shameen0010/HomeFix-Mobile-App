import 'dart:typed_data';

import 'package:flutter/material.dart' show IconData, Icons;

import '../../../provider/data/models/provider_profile.dart';
import '../../../provider/data/models/service_item.dart';

/// Cash price quote shown on checkout / summary and stored on the booking.
class PriceQuote {
  const PriceQuote({required this.service, required this.fee, required this.label});
  final double service, fee;
  final String label;
  double get total => service + fee;

  /// Standard bookings: first hour (or fixed price) + flat HomeFix guarantee fee.
  static const double guaranteeFee = 3.0;

  factory PriceQuote.scheduled(ServiceItem s) => PriceQuote(
        service: s.price,
        fee: guaranteeFee,
        label: s.priceType == 'hourly' ? 'Initial service estimate (1 hr)' : 'Fixed service price',
      );

  /// Emergency: diagnostic fee = service price + the provider's emergency surge, no extra fee.
  factory PriceQuote.emergency(ServiceItem s, ProviderProfile p) => PriceQuote(
        service: double.parse((s.price * (1 + p.surgePct / 100)).toStringAsFixed(2)),
        fee: 0,
        label: 'Estimated diagnostic fee',
      );
}

String _p2(int n) => n.toString().padLeft(2, '0');

/// Firestore doc id of the per-provider-per-day slot document.
String slotDayIdOf(String providerId, DateTime d) => '${providerId}_${dayStrOf(d)}';

/// yyyyMMdd of a date.
String dayStrOf(DateTime d) => '${d.year}${_p2(d.month)}${_p2(d.day)}';

/// Map key inside booking_slots/{day}.slots, e.g. 1130.
String slotKeyOf(DateTime d) => '${_p2(d.hour)}${_p2(d.minute)}';

/// Everything the customer entered before the booking is written.
class BookingDraft {
  BookingDraft({
    required this.provider,
    required this.service,
    this.emergency = false,
    this.scheduledAt,
    this.address = '',
    this.area = '',
    this.unit = '',
    this.problem = '',
    this.saveAddress = false,
    List<Uint8List>? photos,
  }) : photos = photos ?? <Uint8List>[];

  final ProviderProfile provider;
  final ServiceItem service;
  final bool emergency;
  DateTime? scheduledAt;
  String address, area, unit, problem;
  bool saveAddress;
  final List<Uint8List> photos;

  PriceQuote get quote => emergency ? PriceQuote.emergency(service, provider) : PriceQuote.scheduled(service);

  /// Full one-line address stored on the booking.
  String get fullAddress {
    final parts = <String>[
      address.trim(),
      if (unit.trim().isNotEmpty) unit.trim(),
      if (area.trim().isNotEmpty) area.trim(),
    ];
    return parts.join(', ');
  }
}

/// Emergency flow state before a technician has been chosen (steps 1-3).
/// [provider] + [service] are pre-set when the customer came from a provider's
/// profile; then the flow skips the provider list.
class EmergencyRequest {
  EmergencyRequest({
    required this.type,
    this.provider,
    this.service,
    this.address = '',
    this.area = '',
    this.unit = '',
    this.problem = '',
    List<Uint8List>? photos,
  }) : photos = photos ?? <Uint8List>[];

  EmergencyType type;
  ProviderProfile? provider;
  ServiceItem? service;
  String address, area, unit, problem;
  final List<Uint8List> photos;

  BookingDraft toDraft(ProviderProfile p, ServiceItem s) => BookingDraft(
        provider: p,
        service: s,
        emergency: true,
        address: address,
        area: area,
        unit: unit,
        problem: problem,
        photos: photos,
      );

  String get fullAddress => [
        address.trim(),
        if (unit.trim().isNotEmpty) unit.trim(),
        if (area.trim().isNotEmpty) area.trim(),
      ].join(', ');
}

/// Live load of one provider day (booking_slots/{providerId}_{yyyyMMdd}).
class DayLoad {
  const DayLoad({this.taken = const <String>{}});
  final Set<String> taken;
  int get count => taken.length;
}

/// Static emergency categories (Figma "Emergency Booking" step 1).
class EmergencyType {
  const EmergencyType({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.keyword,
    required this.icon,
  });
  final String id, title, description, keyword;
  final List<String> tags;
  final IconData icon;

  bool matches(ProviderProfile p) {
    if (keyword.isEmpty) return true;
    final k = keyword.toLowerCase();
    return p.trade.toLowerCase().contains(k) || p.trades.any((t) => t.toLowerCase().contains(k));
  }

  bool matchesService(ServiceItem s) =>
      keyword.isEmpty || s.category.toLowerCase().contains(keyword.toLowerCase()) ||
      s.name.toLowerCase().contains(keyword.toLowerCase());

  /// Best service of a provider for this emergency (cheapest matching, else cheapest).
  ServiceItem? pick(List<ServiceItem> list) {
    if (list.isEmpty) return null;
    final sorted = [...list]..sort((a, b) => a.price.compareTo(b.price));
    for (final s in sorted) {
      if (matchesService(s)) return s;
    }
    return sorted.first;
  }

  static const all = <EmergencyType>[
    EmergencyType(
        id: 'plumbing', title: 'Emergency Plumbing',
        description: 'Burst pipes, severe leaks, water shutoff failure, overflowing drains',
        tags: ['Avg. response 15 min', 'Certified Techs'], keyword: 'plumb', icon: Icons.water_drop_outlined),
    EmergencyType(
        id: 'electrical', title: 'Emergency Electrical',
        description: 'Power outage, sparking outlet, breaker failure, burning wire odor',
        tags: ['Critical safety hazard', 'Licensed Electricians'], keyword: 'electr', icon: Icons.bolt_rounded),
    EmergencyType(
        id: 'appliance', title: 'Appliance Repair',
        description: 'Refrigerator cooling failure, gas oven leak, urgent breakdown',
        tags: ['Same-day parts', 'All Major Brands'], keyword: 'appliance', icon: Icons.kitchen_outlined),
    EmergencyType(
        id: 'other', title: 'Other Home Emergency',
        description: 'Door lockout, urgent structural issue, storm leak, broken window',
        tags: ['24/7 dispatch', 'Vetted Pros'], keyword: '', icon: Icons.home_repair_service_outlined),
  ];
}
