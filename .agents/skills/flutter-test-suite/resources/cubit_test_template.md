---
name: cubit-test-template
description: "Use when creating or refining Flutter Cubit unit tests. Provides a deterministic template for Cubit state transition testing using bloc_test and mocktail."
risk: low
source: custom
date_added: "2026-03-23"
---

# Cubit Test Template

## Purpose

Provide a **repeatable unit-test template** for Flutter Cubits.

Use this template to verify:

- state transitions
- success / empty / error behavior
- refresh behavior
- dependency interaction where relevant

This template is intentionally scoped to **unit testing** only.

---

## When to Use

Use this template when the target is:

- a `Cubit`
- state logic that can be tested in isolation
- a read-oriented feature using Cubit
- a Cubit with repository/service dependencies mocked or faked

Do **not** use this template for:

- widget rendering
- navigation flows
- end-to-end scenarios

This aligns with the testing guide's priority on unit-testing state logic in isolation. fileciteturn2file1

---

## Operating Rules

- Prefer `bloc_test` for readable Cubit transition tests. fileciteturn2file2
- Use `mocktail` or fakes for deterministic dependencies. fileciteturn2file4
- No real network
- No real disk I/O
- No arbitrary delays
- Test behavior, not internals. fileciteturn2file4

---

## File Path Convention

```text
test/
 └─ features/
     └─ feature/
         └─ cubit/
             └─ feature_cubit_test.dart
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
  late FeatureCubit cubit;

  setUp(() {
    repository = MockFeatureRepository();
    cubit = FeatureCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  group('FeatureCubit', () {
    blocTest<FeatureCubit, FeatureState>(
      'given successful response when loadData then emits loading then success',
      build: () {
        when(() => repository.fetchData())
            .thenAnswer((_) async => fakeItems);
        return cubit;
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        const FeatureLoading(),
        FeatureSuccess(fakeItems),
      ],
    );

    blocTest<FeatureCubit, FeatureState>(
      'given empty response when loadData then emits loading then empty',
      build: () {
        when(() => repository.fetchData())
            .thenAnswer((_) async => []);
        return cubit;
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        const FeatureLoading(),
        const FeatureEmpty(),
      ],
    );

    blocTest<FeatureCubit, FeatureState>(
      'given repository failure when loadData then emits loading then error',
      build: () {
        when(() => repository.fetchData())
            .thenThrow(Exception('failed to load'));
        return cubit;
      },
      act: (cubit) => cubit.loadData(),
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
- refresh path if implemented

---

## Naming Rules

Replace:

- `FeatureCubit`
- `FeatureState`
- `FeatureLoading`
- `FeatureSuccess`
- `FeatureEmpty`
- `FeatureError`
- `FeatureRepository`

With the actual feature names.

---

## Final Instruction

Keep Cubit tests:

- isolated
- deterministic
- state-focused
- easy to read
