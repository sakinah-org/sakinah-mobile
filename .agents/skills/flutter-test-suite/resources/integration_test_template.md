---
name: integration-test-template
description: "Use when creating or refining Flutter integration tests for critical user journeys. Provides a deterministic scenario-based template using integration_test and stable widget keys."
risk: medium
source: custom
date_added: "2026-03-23"
---

# Integration Test Template

## Purpose

Provide a **repeatable integration-test template** for Flutter critical user flows.

Use this template to verify:

- app launch
- full user journeys
- navigation across screens
- runtime wiring
- critical flow success/failure

This template is intentionally scoped to **integration testing** only.

---

## When to Use

Use this template when the target is:

- a critical user journey
- a login / checkout / onboarding flow
- navigation across multiple screens
- a real app wiring scenario

Do **not** use this template for:

- small isolated state logic
- single-widget behavior
- tiny unit-level assertions

This matches the uploaded guide's recommendation to keep integration tests few, high-value, and scenario-based. fileciteturn2file2

---

## Operating Rules

- Use `integration_test`
- One file per scenario where practical. fileciteturn2file0
- Prefer fake backend or fixture-backed networking. fileciteturn2file2
- Use stable widget keys
- Wait for UI conditions, not arbitrary timeouts. fileciteturn2file2
- Keep flows short and deterministic

---

## File Path Convention

```text
integration_test/
  login_flow_test.dart
```

---

## Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login flow - success', (tester) async {
    app.main(); // ensure test DI is used in test mode
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('emailField')),
      'a@b.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      '123',
    );
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
  });
}
```

---

## Coverage Requirements

At minimum, cover the relevant subset of:

- smoke launch
- success path
- failure path
- navigation completion
- critical recovery path if applicable

---

## Key Rules

Use stable keys such as:

```dart
const Key('emailField')
const Key('passwordField')
const Key('loginButton')
const Key('homeScreen')
const Key('checkoutButton')
```

The uploaded testing guide explicitly recommends stable keys for integration reliability. fileciteturn2file6

---

## Test DI Rule

The app should run in a **test environment** that swaps production dependencies for test doubles or a fake backend. This is a critical recommendation in the uploaded guide. fileciteturn2file6

---

## Naming Rules

Replace:

- `my_app`
- `emailField`
- `passwordField`
- `loginButton`
- `homeScreen`

With the actual app package and feature-specific IDs.

---

## Final Instruction

Keep integration tests:

- scenario-based
- deterministic
- high-value
- short enough for CI
