/// The next prayer relative to "now" — code is one of
/// `fajr|dhuhr|asr|maghrib|isha` (PRAYERS.code).
class NextPrayer {
  final String code;
  final DateTime time;

  const NextPrayer({required this.code, required this.time});
}

/// The five daily prayer times for one Gregorian date + location.
class PrayerTimes {
  final DateTime date;
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const PrayerTimes({
    required this.date,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  List<MapEntry<String, DateTime>> get _ordered => [
        MapEntry('fajr', fajr),
        MapEntry('dhuhr', dhuhr),
        MapEntry('asr', asr),
        MapEntry('maghrib', maghrib),
        MapEntry('isha', isha),
      ];

  /// The next prayer relative to [now]. Rolls to tomorrow's Fajr once Isha
  /// has passed — approximated as today's Fajr time +1 day (prayer times
  /// shift by only a minute or two day-to-day) rather than requiring a
  /// second network fetch, per data-model.md's "derived, not stored" rule.
  NextPrayer nextPrayer(DateTime now) {
    for (final entry in _ordered) {
      if (entry.value.isAfter(now)) {
        return NextPrayer(code: entry.key, time: entry.value);
      }
    }
    return NextPrayer(code: 'fajr', time: fajr.add(const Duration(days: 1)));
  }
}
