---
name: test-suite
description: "Use when creating, refining, or reviewing Flutter/Dart tests. Selects the correct test level, enforces deterministic testing practices, and produces maintainable unit, widget, and integration tests with stable widget IDs for reliable automation."
risk: medium
source: custom
date_added: "2026-03-23"
---

# Flutter Test Suite

## Purpose

Build a **well-structured Flutter/Dart test suite** by selecting the correct test level
and generating maintainable tests for:

- **Unit tests**
- **Widget tests**
- **Integration tests**

This skill exists to prevent:

- wrong test type selection
- duplicated coverage across test layers
- flaky integration tests
- untestable UI caused by missing widget IDs
- brittle tests coupled to implementation details

---

## Operating Mode

You are operating as a **test architect and Flutter QA-oriented engineer**.

Your job is to:

- identify the correct testing level
- keep coverage behavior-focused
- generate deterministic tests
- enforce stable widget identifiers for automation
- avoid unnecessary test files

Do not generate all test types by default.  
Only generate the layers the target actually needs.

---

## When to Use

Use this skill when:

- a Flutter/Dart feature needs tests
- a class, Cubit, Bloc, widget, or flow must be verified
- a user asks for unit, widget, or integration tests
- an existing test suite needs improvement or expansion
- integration reliability depends on adding stable widget IDs

This skill is applicable to execute the workflow or actions described in the overview.

---

## Test Layer Selection (Mandatory First Step)

Before writing any test:

### 1️⃣ Identify the target under test

Classify the target as one of:

- pure Dart logic
- state management logic
- widget/UI behavior
- full feature/app flow

### 2️⃣ Select the correct test type

#### Use **Unit Tests** for:
- use cases
- validators
- mappers
- utilities
- repositories with mocked/fake dependencies
- Cubit/Bloc state transitions
- error mapping
- pure Dart logic

#### Use **Widget Tests** for:
- widget rendering
- loading / success / empty / error UI states
- button taps
- text input
- widget-tree interactions
- Bloc/Cubit-driven UI updates

#### Use **Integration Tests** for:
- login flows
- checkout flows
- navigation across screens
- deep links
- session restore
- critical end-to-end user journeys

### 3️⃣ Hard rule

Do **not** use:

- widget tests for pure business logic
- integration tests for small isolated behavior
- unit tests for visual rendering

---

## Test Architecture

Follow this practical test pyramid:

- **Unit tests (70–90%)**
- **Integration tests (10–30%)**
- **Widget tests** used where UI behavior must be verified

Prefer an architecture that supports testability:

- dependency injection
- pure domain logic
- repository abstractions
- replaceable services/data sources

Recommended structure:

```text
test/
  features/
  helpers/
    fakes.dart
    mocks.dart
    fixtures/
    test_di.dart

integration_test/
  smoke_test.dart
  login_flow_test.dart
  checkout_flow_test.dart
```

These practices align with the uploaded testing guide's emphasis on DI, deterministic tests, and a practical test pyramid. fileciteturn0file0

---

## Core Test Rules

### Determinism (Non-Negotiable)

Tests must be deterministic.

Never rely on:

- real network
- real backend services
- uncontrolled timers
- system time
- arbitrary delays

Prefer:

- mocks
- fakes
- fixtures
- fake backend
- injected clock/time providers
- waiting for UI conditions instead of sleeping

These are core anti-flakiness requirements from the uploaded guide. fileciteturn0file0

### Structure

Use **AAA**:

```dart
// Arrange
// Act
// Assert
```

Use clear names:

```text
given X when Y then Z
```

### Scope

Test behavior, not internals.

Prefer:

- public APIs
- state outputs
- rendered outcomes
- visible user flows

Avoid over-testing:

- private methods
- framework internals
- incidental implementation details

---

## Unit Testing Rules

Generate unit tests when the target is logic-first and isolated.

### Priorities
1. use cases / interactors
2. validation and parsing
3. Cubit/Bloc transitions
4. repository orchestration
5. failure mapping

### Requirements
- isolate dependencies with mocks or fakes
- test success path
- test failure path
- test relevant edge cases

### Mock vs Fake

Use **Mock** when:
- verifying calls/parameters/order
- simulating precise failures
- asserting interactions

Use **Fake** when:
- deterministic behavior is enough
- stateful in-memory behavior is useful
- less brittle tests are preferred

This follows the mock-vs-fake guidance in the uploaded test guide. fileciteturn0file0

---

## Widget Testing Rules

Generate widget tests when UI behavior must be verified inside a widget tree.

### Cover:
- initial rendering
- loading state
- success state
- empty state
- error state
- taps
- text entry
- widget reactions to state changes

### Requirements
- use `testWidgets`
- use `pumpWidget`
- use `pumpAndSettle` when appropriate
- wrap the widget with required providers/material app scaffolding
- assert visible user-facing behavior

Do not turn widget tests into integration tests.  
Keep them focused on one widget/screen behavior at a time.

---

## Integration Testing Rules

Generate integration tests only for critical flows and real app wiring.

### Minimum scenarios to prefer
- app launch smoke test
- login success/failure
- browse → details → action → completion flow
- deep-link flow if supported
- session restore if required

### Requirements
- use `integration_test`
- use test DI or test bootstrap
- use fake backend or fixture-backed networking
- keep scenarios short and high-value
- wait for UI conditions, not arbitrary durations

These recommendations follow the uploaded guide's integration strategy. fileciteturn0file0

---

## Widget IDs / Keys (Mandatory for Testability)

Stable widget identifiers are required to make widget and integration testing reliable.

### The agent MUST add stable IDs/keys for:
- text fields
- buttons
- navigation targets
- important screens
- list items that may need direct selection
- critical action triggers
- high-value state containers

### Use meaningful names such as:

```dart
const Key('emailField')
const Key('passwordField')
const Key('loginButton')
const Key('homeScreen')
const Key('productItem_123')
const Key('checkoutButton')
```

### Rules
- keys must be stable
- keys must be predictable
- keys must be human-readable
- do not use random/generated values unless the feature identity itself is stable
- prefer explicit keys for integration-critical elements

The uploaded testing guide explicitly recommends stable keys for integration testing. fileciteturn0file0

---

## Coverage Rules

For any generated test suite, ensure the relevant cases are covered:

### Logic/state layers
- success
- failure
- edge cases
- state transitions

### UI layers
- loading
- success
- empty
- error
- user interaction outcomes

### End-to-end flows
- happy path
- failure path
- critical recovery path when relevant

Do not duplicate the same assertion across multiple test layers without reason.

---

## Output Requirements

When using this skill, the output must:

### 1️⃣ Identify the chosen test level
State clearly whether the target needs:
- unit test
- widget test
- integration test
- or a justified combination

### 2️⃣ Explain the choice briefly
Explain why that test layer is correct.

### 3️⃣ Generate the test file(s)
Produce clean, complete, maintainable test code.

### 4️⃣ Include testability improvements
If the target is a widget/flow, add or recommend stable widget keys where needed.

### 5️⃣ Keep the scope disciplined
Generate only the tests required for the target.

---

## Hard Constraints

The agent must NOT:

- generate all three test layers automatically
- rely on real APIs or external systems
- use fragile time-based waits when a UI condition can be awaited
- skip widget keys for integration-relevant elements
- test implementation details instead of behavior
- create bloated test suites with low-value coverage

---

## Final Instruction

The agent must always:

- choose the correct testing layer first
- prefer deterministic tests
- use mocks/fakes/fixtures appropriately
- add stable widget IDs for reliable automation
- generate maintainable Flutter/Dart tests
- keep the suite behavior-focused, scalable, and CI-friendly
