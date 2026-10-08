import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../admin/data/models/model_utils.dart';
import '../../../admin/data/models/provider_model.dart' show ProviderDocument;
import '../../core/provider_ui.dart';

class DaySchedule {
  const DaySchedule({this.enabled = true, this.start = '08:00', this.end = '17:00', this.maxJobs = 4});
  final bool enabled;
  final String start, end;
  final int maxJobs;

  DaySchedule copyWith({bool? enabled, String? start, String? end, int? maxJobs}) => DaySchedule(
        enabled: enabled ?? this.enabled,
        start: start ?? this.start,
        end: end ?? this.end,
        maxJobs: maxJobs ?? this.maxJobs,
      );

  Map<String, dynamic> toMap() =>
      {'enabled': enabled, 'start': start, 'end': end, 'maxJobs': maxJobs};

  factory DaySchedule.fromMap(Map<String, dynamic> m) => DaySchedule(
        enabled: asBool(m['enabled'], true),
        start: asString(m['start'], '08:00'),
        end: asString(m['end'], '17:00'),
        maxJobs: asInt(m['maxJobs']) == 0 ? 4 : asInt(m['maxJobs']),
      );

  static Map<String, DaySchedule> defaults() => {
        for (final d in ProviderConfig.days)
          d: d == 'sunday'
              ? const DaySchedule(enabled: false)
              : d == 'saturday'
                  ? const DaySchedule(start: '09:00', end: '14:00', maxJobs: 2)
                  : const DaySchedule(),
      };
}

class PricingItem {
  const PricingItem({required this.title, required this.subtitle, required this.price, this.badge});
  final String title, subtitle;
  final double price;
  final String? badge;

  Map<String, dynamic> toMap() =>
      {'title': title, 'subtitle': subtitle, 'price': price, 'badge': badge};

  factory PricingItem.fromMap(Map<String, dynamic> m) => PricingItem(
        title: asString(m['title'], 'Service'),
        subtitle: asString(m['subtitle']),
        price: asDouble(m['price']),
        badge: m['badge'] as String?,
      );
}

/// Firestore: providers/{uid} (same document the admin module verifies).
class ProviderProfile {
  const ProviderProfile({
    required this.id,
    required this.name,
    required this.headline,
    required this.trade,
    required this.trades,
    required this.email,
    required this.phone,
    required this.status,
    required this.isOnline,
    required this.acceptsSameDay,
    required this.catalogActive,
    required this.emergencyEnabled,
    required this.surgePct,
    required this.travelBufferMins,
    required this.coverageArea,
    required this.radiusMiles,
    required this.bio,
    required this.experienceYears,
    required this.rating,
    required this.reviewCount,
    required this.completedCount,
    required this.onTimePct,
    required this.appId,
    required this.licenseNo,
    required this.badges,
    required this.tags,
    required this.pricing,
    required this.documents,
    required this.schedule,
    this.photoUrl,
    this.vacationFrom,
    this.vacationTo,
  });

  final String id, name, headline, trade, email, phone, status, coverageArea, bio, appId, licenseNo;
  final List<String> trades, badges, tags;
  final bool isOnline, acceptsSameDay, catalogActive, emergencyEnabled;
  final int surgePct, travelBufferMins, radiusMiles, experienceYears, reviewCount, completedCount;
  final double rating, onTimePct;
  final List<PricingItem> pricing;
  final List<ProviderDocument> documents;
  final Map<String, DaySchedule> schedule;
  final String? photoUrl;
  final DateTime? vacationFrom, vacationTo;

  bool get isApproved => status == 'approved';

  factory ProviderProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final trade = asString(d['trade'], 'General');
    final rawSchedule = d['schedule'];
    final defaults = DaySchedule.defaults();
    final schedule = <String, DaySchedule>{
      for (final day in ProviderConfig.days)
        day: rawSchedule is Map && rawSchedule[day] is Map
            ? DaySchedule.fromMap(Map<String, dynamic>.from(rawSchedule[day] as Map))
            : defaults[day]!,
    };
    List<String> strings(Object? v) =>
        (v as List? ?? const []).map((e) => e.toString()).toList();
    return ProviderProfile(
      id: doc.id,
      name: asString(d['name'], 'Provider'),
      headline: asString(d['headline'], '$trade Specialist'),
      trade: trade,
      trades: strings(d['trades']).isEmpty ? [trade] : strings(d['trades']),
      email: asString(d['email']),
      phone: asString(d['phone'], '-'),
      status: asString(d['status'], 'pending'),
      isOnline: asBool(d['isOnline']),
      acceptsSameDay: asBool(d['acceptsSameDay']),
      catalogActive: asBool(d['catalogActive'], true),
      emergencyEnabled: asBool(d['emergencyEnabled'], true),
      surgePct: asInt(d['surgePct']) == 0 ? 35 : asInt(d['surgePct']),
      travelBufferMins: d['travelBufferMins'] is num ? asInt(d['travelBufferMins']) : 30,
      coverageArea: asString(d['coverageArea'], asString(d['location'], '-')),
      radiusMiles: asInt(d['radiusMiles']) == 0 ? 10 : asInt(d['radiusMiles']),
      bio: asString(d['bio']),
      experienceYears: asInt(d['experienceYears']),
      rating: asDouble(d['rating']),
      reviewCount: asInt(d['reviewCount']),
      completedCount: asInt(d['completedCount']),
      onTimePct: d['onTimePct'] is num ? asDouble(d['onTimePct']) : 100,
      appId: asString(d['appId'], shortId(doc.id)),
      licenseNo: asString(d['licenseNo'], '-'),
      badges: strings(d['badges']),
      tags: strings(d['tags']),
      pricing: (d['pricing'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => PricingItem.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      documents: (d['documents'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => ProviderDocument.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      schedule: schedule,
      photoUrl: d['photoUrl'] as String?,
      vacationFrom: asDate(d['vacationFrom']),
      vacationTo: asDate(d['vacationTo']),
    );
  }
}
