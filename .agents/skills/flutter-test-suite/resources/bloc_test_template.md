---
name: bloc-test-template
description: "Use when creating or refining Flutter Bloc unit tests. Provides a deterministic template for event-driven Bloc testing with bloc_test and mocktail."
risk: low
source: custom
date_added: "2026-03-23"
---

# Bloc Test Template

## Purpose

Provide a **repeatable unit-test template** for Flutter Blocs.

Use this template to verify:

- event handling
- state transitions
- search / filter / sort behavior when applicable
- retry / refresh behavior
- dependency interaction where relevant

This template is intentionally scoped to **unit testing** only.

---

## When to Use

Use this template when the target is:

- a `Bloc`
- event-driven state logic
- a feature with explicit events
- a Bloc with repository/service dependencies mocked or faked

Do **not** use this template for:

- widget rendering
- navigation flows
- end-to-end scenarios

This matches the guide's recommendation to unit-test state logic in isolation. fileciteturn2file1

---

## Operating Rules

- Prefer `bloc_test` for readable transition assertions. fileciteturn2file2
- Use mocks/fakes for dependencies, not real services. fileciteturn2file4
- No real network
- No real backend
- No arbitrary sleeps
- Test public behavior only

---

## File Path Convention

```text
test/
 └─ features/
     └─ feature/
         └─ bloc/
             └─ feature_bloc_test.dart
```

---

## Template

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeatureRepository extends Mock implements FeatureRepository {}

void main() {
  late MockFeatureRepository repository;
  late FeatureBloc bloc;

  setUp(() {
    repository = MockFeatureRepository();
    bloc = FeatureBloc(repository);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('FeatureBloc', () {
    blocTest<FeatureBloc, FeatureState>(
      'given successful response when FeatureStarted is added then emits loading then success',
      build: () {
        when(() => repository.fetchData())
            .thenAnswer((_) async => fakeItems);
        return bloc;
      },
      act: (bloc) => bloc.add(const FeatureStarted()),
      expect: () => [
        const FeatureLoading(),
        FeatureSuccess(fakeItems),
      ],
    );

    blocTest<FeatureBloc, FeatureState>(
      'given empty response when FeatureStarted is added then emits loading then empty',
      build: () {
        when(() => repository.fetchData())
            .thenAnswer((_) async => []);
        return bloc;
      },
      act: (bloc) => bloc.add(const FeatureStarted()),
      expect: () => [
        const FeatureLoading(),
        const FeatureEmpty(),
      ],
    );

    blocTest<FeatureBloc, FeatureState>(
      'given repository failure when FeatureRetryRequested is added then emits loading then error',
      build: () {
        when(() => repository.fetchData())
            .thenThrow(Exception('failed to load'));
        return bloc;
      },
      act: (bloc) => bloc.add(const FeatureRetryRequested()),
      expect: () => [
        const FeatureLoading(),
        const FeatureError(message: 'Exception: failed to load'),
      ],
    );
  });
}
```

---

## Coverage Requirements

At minimum, cover:

- success path
- empty path
- error path
- retry / refresh path if implemented
- one test per important event

---

## Naming Rules

Replace:

- `FeatureBloc`
- `FeatureState`
- `FeatureStarted`
- `FeatureRetryRequested`
- `FeatureLoading`
- `FeatureSuccess`
- `FeatureEmpty`
- `FeatureError`
- `FeatureRepository`

With the actual feature names.

---

## Final Instruction

Keep Bloc tests:

- event-focused
- deterministic
- one behavior per test
- free from implementation-detail coupling
