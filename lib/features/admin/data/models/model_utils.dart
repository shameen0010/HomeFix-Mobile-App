import 'package:cloud_firestore/cloud_firestore.dart';

int asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

double asDouble(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String asString(Object? v, [String fallback = '']) {
  if (v == null) return fallback;
  final s = v.toString();
  return s.isEmpty ? fallback : s;
}

bool asBool(Object? v, [bool fallback = false]) => v is bool ? v : fallback;

DateTime? asDate(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return null;
}

String shortId(String id, [int len = 6]) =>
    (id.length > len ? id.substring(0, len) : id).toUpperCase();
