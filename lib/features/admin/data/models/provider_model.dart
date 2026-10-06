import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_utils.dart';

class ProviderDocument {
  const ProviderDocument({
    required this.title,
    required this.detail,
    required this.type,
    required this.verified,
    this.url,
  });
  final String title, detail, type;
  final bool verified;
  final String? url;

  factory ProviderDocument.fromMap(Map<String, dynamic> m) => ProviderDocument(
        title: asString(m['title'], 'Document'),
        detail: asString(m['detail']),
        type: asString(m['type'], 'other'),
        verified: asBool(m['verified']),
        url: m['url'] as String?,
      );
}

class AuditEntry {
  const AuditEntry({required this.action, this.reason, this.by, this.at});
  final String action;
  final String? reason, by;
  final DateTime? at;

  factory AuditEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return AuditEntry(
      action: asString(d['action'], 'updated'),
      reason: d['reason'] as String?,
      by: d['by'] as String?,
      at: asDate(d['at']),
    );
  }
}

/// Firestore: providers/{uid}. status: pending | approved | rejected | suspended.
class ProviderModel {
  const ProviderModel({
    required this.id,
    required this.name,
    required this.trade,
    required this.licenseNo,
    required this.appId,
    required this.location,
    required this.coverageArea,
    required this.phone,
    required this.status,
    required this.isOnline,
    required this.rating,
    required this.reviewCount,
    required this.experienceYears,
    required this.services,
    required this.documents,
    this.photoUrl,
    this.statusReason,
    this.infoRequest,
    this.submittedAt,
  });

  final String id, name, trade, licenseNo, appId, location, coverageArea, phone, status;
  final bool isOnline;
  final double rating;
  final int reviewCount, experienceYears;
  final List<String> services;
  final List<ProviderDocument> documents;
  final String? photoUrl, statusReason, infoRequest;
  final DateTime? submittedAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  int get checksCleared => documents.where((d) => d.verified).length;

  factory ProviderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final info = d['infoRequest'];
    return ProviderModel(
      id: doc.id,
      name: asString(d['name'], 'Unnamed provider'),
      trade: asString(d['trade'], 'General'),
      licenseNo: asString(d['licenseNo'], '-'),
      appId: asString(d['appId'], shortId(doc.id)),
      location: asString(d['location'], '-'),
      coverageArea: asString(d['coverageArea'], asString(d['location'], '-')),
      phone: asString(d['phone'], '-'),
      status: asString(d['status'], 'pending'),
      isOnline: asBool(d['isOnline']),
      rating: asDouble(d['rating']),
      reviewCount: asInt(d['reviewCount']),
      experienceYears: asInt(d['experienceYears']),
      services: (d['services'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      documents: (d['documents'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => ProviderDocument.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      photoUrl: d['photoUrl'] as String?,
      statusReason: d['statusReason'] as String?,
      infoRequest: info is Map ? info['message'] as String? : null,
      submittedAt: asDate(d['submittedAt']),
    );
  }
}
