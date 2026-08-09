import '../../domain/entities/prayer_times.dart';

sealed class PrayerTimesState {
  const PrayerTimesState();
}

class PrayerTimesInitialState extends PrayerTimesState {
  const PrayerTimesInitialState();
}

class PrayerTimesLoadingState extends PrayerTimesState {
  const PrayerTimesLoadingState();
}

/// [isFallback] is true when [times] came from cache rather than a fresh
/// fetch (FR-007). Not surfaced as a distinct Home visual per spec.md scope,
/// but threaded through for future use (e.g. the Prayers screen).
class PrayerTimesLoadedState extends PrayerTimesState {
  final PrayerTimes times;
  final bool isFallback;

  const PrayerTimesLoadedState(this.times, {required this.isFallback});
}

/// No location resolvable at all (FR-009).
class PrayerTimesLocationRequiredState extends PrayerTimesState {
  const PrayerTimesLocationRequiredState();
}

/// Location known, but no fresh or cached times exist at all (FR-008).
class PrayerTimesUnavailableState extends PrayerTimesState {
  final String? message;

  const PrayerTimesUnavailableState({this.message});
}
