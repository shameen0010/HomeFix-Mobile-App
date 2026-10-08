import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';

class Availability {
  const Availability(this.today, this.label);
  final bool today;
  final String label;
}

bool _onVacation(ProviderProfile p, DateTime d) {
  if (p.vacationFrom == null || p.vacationTo == null) return false;
  final day = DateUtils.dateOnly(d);
  return !day.isBefore(DateUtils.dateOnly(p.vacationFrom!)) && !day.isAfter(DateUtils.dateOnly(p.vacationTo!));
}

Availability availabilityOf(ProviderProfile p) {
  final now = DateTime.now();
  final todayKey = ProviderConfig.days[now.weekday - 1];
  if (p.isOnline && (p.schedule[todayKey]?.enabled ?? false) && !_onVacation(p, now)) {
    return const Availability(true, 'Available Today');
  }
  for (var i = 1; i <= 7; i++) {
    final d = now.add(Duration(days: i));
    final key = ProviderConfig.days[d.weekday - 1];
    if ((p.schedule[key]?.enabled ?? false) && !_onVacation(p, d)) {
      return Availability(false, i == 1 ? 'Next: Tomorrow' : 'Next: ${capitalize(key).substring(0, 3)}');
    }
  }
  return const Availability(false, 'Unavailable');
}

/// Returns an error message when [at] is outside the provider's working hours.
String? validateSlot(ProviderProfile p, DateTime at) {
  if (!at.isAfter(DateTime.now())) return 'Choose a time in the future.';
  if (_onVacation(p, at)) return '${p.name} is on vacation on that date.';
  final day = p.schedule[ProviderConfig.days[at.weekday - 1]];
  if (day == null || !day.enabled) return '${p.name} does not work on ${capitalize(ProviderConfig.days[at.weekday - 1])}s.';
  int mins(String s) {
    final x = s.split(':');
    return int.parse(x[0]) * 60 + int.parse(x[1]);
  }
  final t = at.hour * 60 + at.minute;
  if (t < mins(day.start) || t > mins(day.end)) {
    return 'Working hours that day are ${fmtHm(day.start)} - ${fmtHm(day.end)}.';
  }
  return null;
}

double? startingRate(ProviderProfile p) =>
    p.pricing.isEmpty ? null : p.pricing.map((e) => e.price).reduce((a, b) => a < b ? a : b);
