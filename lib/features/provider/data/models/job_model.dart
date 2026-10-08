import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../admin/data/models/model_utils.dart';

class ChecklistItem {
  const ChecklistItem({required this.title, required this.done, required this.mandatory});
  final String title;
  final bool done, mandatory;

  factory ChecklistItem.fromMap(Map<String, dynamic> m) => ChecklistItem(
        title: asString(m['title'], 'Task'),
        done: asBool(m['done']),
        mandatory: asBool(m['mandatory'], true),
      );
}

class JobPhoto {
  const JobPhoto({required this.url, required this.label});
  final String url, label;
}

/// Firestore: bookings/{id} (shared with customer + admin modules).
/// status: pending | confirmed | in_progress | completed | cancelled
/// stage (while in_progress): en_route | arrived | working | done
class JobModel {
  const JobModel({
    required this.id,
    required this.bookingNo,
    required this.title,
    required this.category,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.status,
    required this.stage,
    required this.isEmergency,
    required this.amount,
    required this.receiptConfirmed,
    required this.checklist,
    required this.photos,
    required this.notes,
    this.providerId,
    this.customerAttested = false,
    this.customerPhotoUrl,
    this.scheduledAt,
    this.expiresAt,
    this.finishedAt,
    this.completedAt,
    this.distanceKm,
    this.customerNotes,
    this.durationMin,
    this.description,
    this.accessInstructions,
    this.accessNote,
    this.customerRating,
    this.customerSince,
    this.customerRepairs,
    this.estMin,
    this.estMax,
    this.distanceMi,
    this.driveMins,
    this.customerPhotos = const [],
  });

  final String id, bookingNo, title, category, customerId, customerName, customerPhone, address, status, stage;
  final bool isEmergency, receiptConfirmed;
  final bool customerAttested;
  final String? providerId;
  final double amount;
  final List<ChecklistItem> checklist;
  final List<JobPhoto> photos;
  final List<String> notes;
  final String? customerPhotoUrl, customerNotes;
  final DateTime? scheduledAt, expiresAt, finishedAt, completedAt;
  final double? distanceKm;
  final int? durationMin;
  final String? description, accessInstructions, accessNote;
  final double? customerRating, distanceMi;
  final DateTime? customerSince;
  final int? customerRepairs, estMin, estMax, driveMins;
  final List<String> customerPhotos;

  String get durationLabel {
    if (estMin == null && estMax == null) return '';
    final a = estMin ?? estMax!, b = estMax ?? estMin!;
    return a == b ? '$a mins' : '$a-$b mins';
  }

  /// "1.2 miles away  |  ~8 min drive" (empty when the booking has no distance data).
  String get distanceLabel {
    final mi = distanceMi ?? (distanceKm == null ? null : distanceKm! * 0.621371);
    if (mi == null) return '';
    final drive = driveMins == null ? '' : '  |  ~$driveMins min drive';
    return '${mi.toStringAsFixed(1)} miles away$drive';
  }

  String get code => '#HF-$bookingNo';
  bool get isDone => stage == 'done';
  bool get isUpcoming => status == 'confirmed' || status == 'in_progress';
  bool get mandatoryDone => checklist.where((c) => c.mandatory).every((c) => c.done);
  DateTime? get earnedAt => completedAt ?? finishedAt ?? scheduledAt;

  factory JobModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return JobModel(
      id: doc.id,
      bookingNo: asString(d['bookingNo'], shortId(doc.id)),
      title: asString(d['title'], asString(d['service'], 'Service request')),
      category: asString(d['category'], 'General'),
      customerId: asString(d['customerId']),
      customerName: asString(d['customerName'], 'Customer'),
      customerPhone: asString(d['customerPhone']),
      providerId: d['providerId'] as String?,
      customerAttested: asBool(d['customerAttested']),
      customerPhotoUrl: d['customerPhotoUrl'] as String?,
      address: asString(d['address'], '-'),
      status: asString(d['status'], 'pending'),
      stage: asString(d['stage'], 'en_route'),
      isEmergency: asBool(d['isEmergency']),
      amount: asDouble(d['amount']),
      receiptConfirmed: asBool(d['receiptConfirmed']),
      checklist: (d['checklist'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => ChecklistItem.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      photos: (d['photos'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => JobPhoto(url: asString(m['url']), label: asString(m['label'], 'Photo')))
          .toList(),
      notes: (d['inspectionNotes'] as List? ?? const []).map((e) => e.toString()).toList(),
      customerNotes: d['notes'] as String?,
      scheduledAt: asDate(d['scheduledAt']),
      expiresAt: asDate(d['expiresAt']),
      finishedAt: asDate(d['finishedAt']),
      completedAt: asDate(d['completedAt']),
      distanceKm: d['distanceKm'] is num ? (d['distanceKm'] as num).toDouble() : null,
      durationMin: d['durationMin'] is num ? (d['durationMin'] as num).toInt() : null,
      description: d['description'] as String?,
      accessInstructions: d['accessInstructions'] as String?,
      accessNote: d['accessNote'] as String?,
      customerRating: d['customerRating'] is num ? (d['customerRating'] as num).toDouble() : null,
      customerSince: asDate(d['customerSince']),
      customerRepairs: d['customerRepairs'] is num ? (d['customerRepairs'] as num).toInt() : null,
      estMin: d['estimatedMin'] is num ? (d['estimatedMin'] as num).toInt() : null,
      estMax: d['estimatedMax'] is num ? (d['estimatedMax'] as num).toInt() : null,
      distanceMi: d['distanceMi'] is num ? (d['distanceMi'] as num).toDouble() : null,
      driveMins: d['driveMins'] is num ? (d['driveMins'] as num).toInt() : null,
      customerPhotos: (d['customerPhotos'] as List? ?? const []).map((e) => e.toString()).toList(),
    );
  }
}
