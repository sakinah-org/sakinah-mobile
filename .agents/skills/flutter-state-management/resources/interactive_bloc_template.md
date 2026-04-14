# Interactive Bloc Template

Use for features that have **meaningful user interactions** modeled as explicit events (e.g. refresh, retry, search, filters, sort).

## File Structure

```text
feature/
 └─ bloc/
     ├─ feature_bloc.dart
     ├─ feature_event.dart
     └─ feature_state.dart
```

Replace `Feature` with the actual feature name (e.g. `Product`, `Orders`, `News`).

---

## Base Template

### feature_event.dart

```dart
import 'package:equatable/equatable.dart';

abstract class FeatureEvent extends Equatable {
  const FeatureEvent();

  @override
  List<Object?> get props => [];
}

class FeatureStarted extends FeatureEvent {}

class FeatureRefreshRequested extends FeatureEvent {}

class FeatureRetryRequested extends FeatureEvent {}
```

### feature_state.dart

```dart
import 'package:equatable/equatable.dart';

abstract class FeatureState extends Equatable {
  const FeatureState();

  @override
  List<Object?> get props => [];
}

class FeatureInitial extends FeatureState {}

class FeatureLoading extends FeatureState {}

class FeatureSuccess<T> extends FeatureState {
  final List<T> data;

  const FeatureSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

class FeatureEmpty extends FeatureState {}

class FeatureError extends FeatureState {
  final String message;
  final int? statusCode;

  const FeatureError({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}
```

### feature_bloc.dart

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'feature_event.dart';
import 'feature_state.dart';

class FeatureBloc<T> extends Bloc<FeatureEvent, FeatureState> {
  final Future<List<T>> Function() fetcher;

  FeatureBloc({
    required this.fetcher,
  }) : super(FeatureInitial()) {
    on<FeatureStarted>(_onStarted);
    on<FeatureRefreshRequested>(_onRefreshRequested);
    on<FeatureRetryRequested>(_onRetryRequested);
  }

  Future<void> _onStarted(
    FeatureStarted event,
    Emitter<FeatureState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onRefreshRequested(
    FeatureRefreshRequested event,
    Emitter<FeatureState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onRetryRequested(
    FeatureRetryRequested event,
    Emitter<FeatureState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<FeatureState> emit) async {
    emit(FeatureLoading());

    try {
      final result = await fetcher();

      if (result.isEmpty) {
        emit(FeatureEmpty());
      } else {
        emit(FeatureSuccess<T>(result));
      }
    } catch (e) {
      emit(
        FeatureError(
          message: e.toString(),
        ),
      );
    }
  }
}
```

---

## Optional Extensions

Add only the extensions the feature actually needs.

### Search

**Event:**
```dart
class FeatureSearchRequested extends FeatureEvent {
  final String query;
  const FeatureSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}
```

**State:**
```dart
class FeatureSearchSuccess<T> extends FeatureState {
  final List<T> data;
  final String query;

  const FeatureSearchSuccess({required this.data, required this.query});

  @override
  List<Object?> get props => [data, query];
}
```

**Bloc handler:**
```dart
on<FeatureSearchRequested>(_onSearchRequested);

Future<void> _onSearchRequested(
  FeatureSearchRequested event,
  Emitter<FeatureState> emit,
) async {
  emit(FeatureLoading());
  try {
    final result = await searchFetcher(event.query);
    if (result.isEmpty) {
      emit(FeatureEmpty());
    } else {
      emit(FeatureSearchSuccess<T>(data: result, query: event.query));
    }
  } catch (e) {
    emit(FeatureError(message: e.toString()));
  }
}
```

---

### Filters

**Event:**
```dart
class FeatureFiltersApplied extends FeatureEvent {
  final Map<String, dynamic> filters;
  const FeatureFiltersApplied(this.filters);

  @override
  List<Object?> get props => [filters];
}
```

**State:**
```dart
class FeatureFiltersSuccess<T> extends FeatureState {
  final List<T> data;
  final Map<String, dynamic> filters;

  const FeatureFiltersSuccess({required this.data, required this.filters});

  @override
  List<Object?> get props => [data, filters];
}
```

**Bloc handler:**
```dart
on<FeatureFiltersApplied>(_onFiltersApplied);

Future<void> _onFiltersApplied(
  FeatureFiltersApplied event,
  Emitter<FeatureState> emit,
) async {
  emit(FeatureLoading());
  try {
    final result = await filtersFetcher(event.filters);
    if (result.isEmpty) {
      emit(FeatureEmpty());
    } else {
      emit(FeatureFiltersSuccess<T>(data: result, filters: event.filters));
    }
  } catch (e) {
    emit(FeatureError(message: e.toString()));
  }
}
```

---

### Sort

**Event:**
```dart
class FeatureSortRequested extends FeatureEvent {
  final String sortBy;
  const FeatureSortRequested(this.sortBy);

  @override
  List<Object?> get props => [sortBy];
}
```

**State:**
```dart
class FeatureSortSuccess<T> extends FeatureState {
  final List<T> data;
  final String sortBy;

  const FeatureSortSuccess({required this.data, required this.sortBy});

  @override
  List<Object?> get props => [data, sortBy];
}
```

**Bloc handler:**
```dart
on<FeatureSortRequested>(_onSortRequested);

Future<void> _onSortRequested(
  FeatureSortRequested event,
  Emitter<FeatureState> emit,
) async {
  emit(FeatureLoading());
  try {
    final result = await sortFetcher(event.sortBy);
    if (result.isEmpty) {
      emit(FeatureEmpty());
    } else {
      emit(FeatureSortSuccess<T>(data: result, sortBy: event.sortBy));
    }
  } catch (e) {
    emit(FeatureError(message: e.toString()));
  }
}
```

---

## State Flow

Base flow:
```text
Initial → Loading → Success
                    Empty
                    Error
```

Extended flows added only when needed: search, filters, sort.

---

## When NOT to Use

Do not use for simple display-only features with no meaningful user-driven event flow — use the Cubit template instead.
