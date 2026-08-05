# Form Bloc Template

Use for features that include **field input handling, validation, and submission flow**.

## File Structure

```text
feature/
 └─ bloc/
     ├─ feature_form_bloc.dart
     ├─ feature_form_event.dart
     └─ feature_form_state.dart
```

Replace `Feature` with the actual feature name (e.g. `Login`, `Register`, `ProfileEdit`).

---

## feature_form_event.dart

```dart
import 'package:equatable/equatable.dart';

abstract class FeatureFormEvent extends Equatable {
  const FeatureFormEvent();

  @override
  List<Object?> get props => [];
}

class FeatureFormInitialized extends FeatureFormEvent {
  const FeatureFormInitialized();
}

class FeatureFieldChanged extends FeatureFormEvent {
  final String fieldKey;
  final dynamic value;

  const FeatureFieldChanged({
    required this.fieldKey,
    required this.value,
  });

  @override
  List<Object?> get props => [fieldKey, value];
}

class FeatureFormSubmitted extends FeatureFormEvent {
  const FeatureFormSubmitted();
}

class FeatureFormResetRequested extends FeatureFormEvent {
  const FeatureFormResetRequested();
}
```

---

## feature_form_state.dart

```dart
import 'package:equatable/equatable.dart';

abstract class FeatureFormState extends Equatable {
  const FeatureFormState();

  @override
  List<Object?> get props => [];
}

class FeatureFormInitial extends FeatureFormState {
  const FeatureFormInitial();
}

class FeatureFormEditing extends FeatureFormState {
  final Map<String, dynamic> values;
  final Map<String, String?> fieldErrors;
  final bool isValid;

  const FeatureFormEditing({
    required this.values,
    required this.fieldErrors,
    required this.isValid,
  });

  FeatureFormEditing copyWith({
    Map<String, dynamic>? values,
    Map<String, String?>? fieldErrors,
    bool? isValid,
  }) {
    return FeatureFormEditing(
      values: values ?? this.values,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  List<Object?> get props => [values, fieldErrors, isValid];
}

class FeatureFormSubmitting extends FeatureFormState {
  final Map<String, dynamic> values;

  const FeatureFormSubmitting({required this.values});

  @override
  List<Object?> get props => [values];
}

class FeatureFormSuccess extends FeatureFormState {
  const FeatureFormSuccess();
}

class FeatureFormError extends FeatureFormState {
  final String message;
  final int? statusCode;

  const FeatureFormError({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}
```

---

## feature_form_bloc.dart

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'feature_form_event.dart';
import 'feature_form_state.dart';

class FeatureFormBloc extends Bloc<FeatureFormEvent, FeatureFormState> {
  final Future<void> Function(Map<String, dynamic> values) submitHandler;
  final Map<String, String?> Function(Map<String, dynamic> values) validate;

  FeatureFormBloc({
    required this.submitHandler,
    required this.validate,
  }) : super(const FeatureFormInitial()) {
    on<FeatureFormInitialized>(_onInitialized);
    on<FeatureFieldChanged>(_onFieldChanged);
    on<FeatureFormSubmitted>(_onSubmitted);
    on<FeatureFormResetRequested>(_onResetRequested);
  }

  Future<void> _onInitialized(
    FeatureFormInitialized event,
    Emitter<FeatureFormState> emit,
  ) async {
    emit(
      const FeatureFormEditing(
        values: {},
        fieldErrors: {},
        isValid: false,
      ),
    );
  }

  Future<void> _onFieldChanged(
    FeatureFieldChanged event,
    Emitter<FeatureFormState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FeatureFormEditing) return;

    final updatedValues = Map<String, dynamic>.from(currentState.values)
      ..[event.fieldKey] = event.value;

    final updatedErrors = validate(updatedValues);
    final isValid = !updatedErrors.values.any((error) => error != null);

    emit(
      currentState.copyWith(
        values: updatedValues,
        fieldErrors: updatedErrors,
        isValid: isValid,
      ),
    );
  }

  Future<void> _onSubmitted(
    FeatureFormSubmitted event,
    Emitter<FeatureFormState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FeatureFormEditing) return;

    final validationErrors = validate(currentState.values);
    final isValid = !validationErrors.values.any((error) => error != null);

    if (!isValid) {
      emit(currentState.copyWith(fieldErrors: validationErrors, isValid: false));
      return;
    }

    emit(FeatureFormSubmitting(values: currentState.values));

    try {
      await submitHandler(currentState.values);
      emit(const FeatureFormSuccess());
    } catch (e) {
      emit(FeatureFormError(message: e.toString()));
      emit(
        FeatureFormEditing(
          values: currentState.values,
          fieldErrors: validationErrors,
          isValid: true,
        ),
      );
    }
  }

  Future<void> _onResetRequested(
    FeatureFormResetRequested event,
    Emitter<FeatureFormState> emit,
  ) async {
    emit(
      const FeatureFormEditing(
        values: {},
        fieldErrors: {},
        isValid: false,
      ),
    );
  }
}
```

---

## Field Modeling Note

Fields are modeled as generic maps to keep the template reusable:

```dart
Map<String, dynamic> values
Map<String, String?> fieldErrors
```

When applying to a real feature, these may be replaced with strongly typed fields if project conventions require it.

---

## State Flow

```text
Initial → Editing → Submitting → Success
                 └──────────────→ Error → Editing
```

---

## When NOT to Use

Do not use for display-only features, features with no form input, or features that only load and render data. Use the Cubit template or the interactive Bloc template instead.
