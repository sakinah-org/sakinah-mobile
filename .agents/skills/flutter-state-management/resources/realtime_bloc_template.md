# Realtime Bloc Template

Use for features that need **live updates, stream-driven data, sending actions, and reconnect handling**.

## File Structure

```text
feature/
 └─ bloc/
     ├─ feature_realtime_bloc.dart
     ├─ feature_realtime_event.dart
     └─ feature_realtime_state.dart
```

Replace `Feature` with the actual feature name (e.g. `Chat`, `Notifications`, `LiveFeed`).

---

## feature_realtime_event.dart

```dart
import 'package:equatable/equatable.dart';

abstract class FeatureRealtimeEvent extends Equatable {
  const FeatureRealtimeEvent();

  @override
  List<Object?> get props => [];
}

class FeatureRealtimeStarted extends FeatureRealtimeEvent {
  const FeatureRealtimeStarted();
}

class FeatureHistoryRequested extends FeatureRealtimeEvent {
  const FeatureHistoryRequested();
}

class FeatureItemReceived<T> extends FeatureRealtimeEvent {
  final T item;
  const FeatureItemReceived(this.item);

  @override
  List<Object?> get props => [item];
}

class FeatureItemSendRequested<T> extends FeatureRealtimeEvent {
  final T item;
  const FeatureItemSendRequested(this.item);

  @override
  List<Object?> get props => [item];
}

class FeatureReconnectRequested extends FeatureRealtimeEvent {
  const FeatureReconnectRequested();
}
```

---

## feature_realtime_state.dart

```dart
import 'package:equatable/equatable.dart';

abstract class FeatureRealtimeState extends Equatable {
  const FeatureRealtimeState();

  @override
  List<Object?> get props => [];
}

class FeatureRealtimeInitial extends FeatureRealtimeState {
  const FeatureRealtimeInitial();
}

class FeatureRealtimeLoading extends FeatureRealtimeState {
  const FeatureRealtimeLoading();
}

class FeatureRealtimeLoaded<T> extends FeatureRealtimeState {
  final List<T> items;
  final bool isConnected;

  const FeatureRealtimeLoaded({
    required this.items,
    required this.isConnected,
  });

  FeatureRealtimeLoaded<T> copyWith({
    List<T>? items,
    bool? isConnected,
  }) {
    return FeatureRealtimeLoaded<T>(
      items: items ?? this.items,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props => [items, isConnected];
}

class FeatureRealtimeSending<T> extends FeatureRealtimeState {
  final List<T> items;
  const FeatureRealtimeSending({required this.items});

  @override
  List<Object?> get props => [items];
}

class FeatureRealtimeError extends FeatureRealtimeState {
  final String message;
  final int? statusCode;

  const FeatureRealtimeError({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}
```

---

## feature_realtime_bloc.dart

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'feature_realtime_event.dart';
import 'feature_realtime_state.dart';

class FeatureRealtimeBloc<T>
    extends Bloc<FeatureRealtimeEvent, FeatureRealtimeState> {
  final Future<List<T>> Function() loadHistory;
  final Future<void> Function(T item) sendItem;
  final Stream<T> Function() connectStream;

  StreamSubscription<T>? _subscription;

  FeatureRealtimeBloc({
    required this.loadHistory,
    required this.sendItem,
    required this.connectStream,
  }) : super(const FeatureRealtimeInitial()) {
    on<FeatureRealtimeStarted>(_onStarted);
    on<FeatureHistoryRequested>(_onHistoryRequested);
    on<FeatureItemReceived<T>>(_onItemReceived);
    on<FeatureItemSendRequested<T>>(_onItemSendRequested);
    on<FeatureReconnectRequested>(_onReconnectRequested);
  }

  Future<void> _onStarted(
    FeatureRealtimeStarted event,
    Emitter<FeatureRealtimeState> emit,
  ) async {
    await _loadAndConnect(emit);
  }

  Future<void> _onHistoryRequested(
    FeatureHistoryRequested event,
    Emitter<FeatureRealtimeState> emit,
  ) async {
    await _loadHistoryOnly(emit);
  }

  Future<void> _onItemReceived(
    FeatureItemReceived<T> event,
    Emitter<FeatureRealtimeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FeatureRealtimeLoaded<T>) return;

    final updatedItems = List<T>.from(currentState.items)..add(event.item);
    emit(currentState.copyWith(items: updatedItems, isConnected: true));
  }

  Future<void> _onItemSendRequested(
    FeatureItemSendRequested<T> event,
    Emitter<FeatureRealtimeState> emit,
  ) async {
    final currentItems = state is FeatureRealtimeLoaded<T>
        ? (state as FeatureRealtimeLoaded<T>).items
        : <T>[];

    emit(FeatureRealtimeSending<T>(items: currentItems));

    try {
      await sendItem(event.item);
      emit(FeatureRealtimeLoaded<T>(items: currentItems, isConnected: true));
    } catch (e) {
      emit(FeatureRealtimeError(message: e.toString()));
      emit(FeatureRealtimeLoaded<T>(items: currentItems, isConnected: false));
    }
  }

  Future<void> _onReconnectRequested(
    FeatureReconnectRequested event,
    Emitter<FeatureRealtimeState> emit,
  ) async {
    await _disposeSubscription();
    await _loadAndConnect(emit);
  }

  Future<void> _loadAndConnect(Emitter<FeatureRealtimeState> emit) async {
    emit(const FeatureRealtimeLoading());

    try {
      final history = await loadHistory();

      emit(FeatureRealtimeLoaded<T>(items: history, isConnected: true));

      _subscription = connectStream().listen(
        (item) => add(FeatureItemReceived<T>(item)),
        onError: (_) => add(const FeatureReconnectRequested()),
      );
    } catch (e) {
      emit(FeatureRealtimeError(message: e.toString()));
    }
  }

  Future<void> _loadHistoryOnly(Emitter<FeatureRealtimeState> emit) async {
    emit(const FeatureRealtimeLoading());

    try {
      final history = await loadHistory();
      emit(FeatureRealtimeLoaded<T>(items: history, isConnected: false));
    } catch (e) {
      emit(FeatureRealtimeError(message: e.toString()));
    }
  }

  Future<void> _disposeSubscription() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<void> close() async {
    await _disposeSubscription();
    return super.close();
  }
}
```

---

## Item Modeling Note

The generic type `T` keeps the template reusable. Examples of what `T` becomes in real features: `Message`, `NotificationItem`, `LiveFeedItem`.

---

## State Flow

```text
Initial → Loading → Loaded
                  → Sending → Loaded
                  → Error
```

---

## When NOT to Use

Do not use for simple display-only features, non-realtime forms, or features with no stream/socket/live update requirement. Use the Cubit template, interactive Bloc template, or form Bloc template instead.
