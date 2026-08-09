import '../../domain/entities/prayer_times.dart';

/// Maps the AlAdhan `/timings` (or `/timingsByCity`) response onto
/// [PrayerTimes]. Only the 5 named prayers + the Gregorian date are read —
/// Sunrise/Imsak/Midnight/Firstthird/Lastthird/hijri/meta are ignored per
/// contracts/prayer_times_api.md.
class PrayerTimesModel {
  static PrayerTimes fromAlAdhanJson(
    Map<String, dynamic> json,
    DateTime requestedDate,
  ) {
    final data = json['data'] as Map<String, dynamic>;
    final timings = Map<String, dynamic>.from(data['timings'] as Map);

    DateTime timeFor(String key) {
      final raw =
          (timings[key] as String).split(' ').first; // strip "(EET)" etc.
      final parts = raw.split(':');
      return DateTime(
        requestedDate.year,
        requestedDate.month,
        requestedDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    return PrayerTimes(
      date:
          DateTime(requestedDate.year, requestedDate.month, requestedDate.day),
      fajr: timeFor('Fajr'),
      dhuhr: timeFor('Dhuhr'),
      asr: timeFor('Asr'),
      maghrib: timeFor('Maghrib'),
      isha: timeFor('Isha'),
    );
  }
}

/// Persisted envelope (data-model.md `CachedPrayerTimes`) — the single-slot
/// "most recently successful" fallback for FR-007.
class CachedPrayerTimes {
  final PrayerTimes prayerTimes;
  final String locationSignature;
  final DateTime fetchedAt;

  const CachedPrayerTimes({
    required this.prayerTimes,
    required this.locationSignature,
    required this.fetchedAt,
  });

  Map<String, dynamic> toJson() => {
        'date': prayerTimes.date.toIso8601String(),
        'fajr': prayerTimes.fajr.toIso8601String(),
        'dhuhr': prayerTimes.dhuhr.toIso8601String(),
        'asr': prayerTimes.asr.toIso8601String(),
        'maghrib': prayerTimes.maghrib.toIso8601String(),
        'isha': prayerTimes.isha.toIso8601String(),
        'locationSignature': locationSignature,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  static CachedPrayerTimes fromJson(Map json) {
    return CachedPrayerTimes(
      prayerTimes: PrayerTimes(
        date: DateTime.parse(json['date'] as String),
        fajr: DateTime.parse(json['fajr'] as String),
        dhuhr: DateTime.parse(json['dhuhr'] as String),
        asr: DateTime.parse(json['asr'] as String),
        maghrib: DateTime.parse(json['maghrib'] as String),
        isha: DateTime.parse(json['isha'] as String),
      ),
      locationSignature: json['locationSignature'] as String,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }
}
