import '../../domain/entities/qibla_reading.dart';

/// data-model.md §4 — Qibla's genuinely distinct view branches justify
/// typed `[Feature][Status]State` classes (Constitution Principle II)
/// rather than the shared `AppStates` hierarchy.
sealed class QiblaCompassState {
  const QiblaCompassState();
}

class QiblaInitialState extends QiblaCompassState {
  const QiblaInitialState();
}

class QiblaLoadingState extends QiblaCompassState {
  const QiblaLoadingState();
}

class QiblaLiveState extends QiblaCompassState {
  const QiblaLiveState(this.reading);
  final QiblaLiveReading reading;
}

class QiblaStaticState extends QiblaCompassState {
  const QiblaStaticState(this.reading);
  final QiblaStaticReading reading;
}

class QiblaLocationRequiredState extends QiblaCompassState {
  const QiblaLocationRequiredState();
}
