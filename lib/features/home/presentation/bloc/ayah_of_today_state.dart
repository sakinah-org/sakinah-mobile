import '../../domain/entities/ayah_of_today.dart';

sealed class AyahOfTodayState {
  const AyahOfTodayState();
}

class AyahOfTodayInitialState extends AyahOfTodayState {
  const AyahOfTodayInitialState();
}

class AyahOfTodayLoadingState extends AyahOfTodayState {
  const AyahOfTodayLoadingState();
}

/// [isFromToday] drives the "Cached" indicator (FR-013) when false.
class AyahOfTodayLoadedState extends AyahOfTodayState {
  final AyahOfToday ayah;
  final bool isFromToday;

  const AyahOfTodayLoadedState(this.ayah, {required this.isFromToday});
}

/// No ayah available at all — fresh or cached (FR-014).
class AyahOfTodayUnavailableState extends AyahOfTodayState {
  const AyahOfTodayUnavailableState();
}
