# Simple Cubit Template

Use for features that only **load and display data** with no complex user interactions.

## File Structure

```text
feature/
 └─ presentation/cubit/
     ├─ feature_cubit.dart
     └─ feature_state.dart
```

Replace `Feature` with the actual feature name (e.g. `Product`, `News`, `Orders`).

---

## feature_state.dart

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

---

## feature_cubit.dart

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'feature_state.dart';

class FeatureCubit<T> extends Cubit<FeatureState> {
  FeatureCubit() : super(FeatureInitial());

  Future<void> loadData(Future<List<T>> Function() fetcher) async {
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

  Future<void> refresh(Future<List<T>> Function() fetcher) async {
    await loadData(fetcher);
  }
}
```

---

## State Flow

```text
Initial → Loading → Success
                    Empty
                    Error
```

---

## When NOT to Use

Do not use if the feature contains search, filters, form inputs, multi-step workflows, or real-time interactions. Use a Bloc template instead.
