---
name: widget-test-template
description: "Use when creating or refining Flutter widget tests. Provides a repeatable template for rendering, interaction, and UI-state testing with stable widget keys."
risk: low
source: custom
date_added: "2026-03-23"
---

# Widget Test Template

## Purpose

Provide a **repeatable widget-test template** for Flutter UI behavior.

Use this template to verify:

- rendering
- loading / success / empty / error states
- button taps
- text input
- visible widget reactions to state changes

This template is intentionally scoped to **widget testing** only.

---

## When to Use

Use this template when the target is:

- a widget
- a screen
- UI that reacts to Cubit/Bloc state
- a user interaction inside a widget tree

Do **not** use this template for:

- pure business logic
- deep multi-screen flows
- end-to-end app journeys

This follows the rule that widget tests should verify widget-tree behavior, not full integration flows. fileciteturn2file4

---

## Operating Rules

- Use `testWidgets`
- Use `pumpWidget`
- Use `pumpAndSettle` only when needed
- Wrap the target with required app/providers
- Assert visible behavior, not internals
- Prefer stable widget keys for important elements

The broader testing guidance emphasizes stable keys for reliable automation and UI assertions. fileciteturn2file6

---

## File Path Convention

```text
test/
 └─ features/
     └─ feature/
         └─ presentation/
             └─ feature_screen_test.dart
```

---

## Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'given screen loads when rendered then expected widgets are visible',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FeatureScreen(),
        ),
      );

      expect(find.byType(FeatureScreen), findsOneWidget);
      expect(find.byKey(const Key('featureScreen')), findsOneWidget);
    },
  );

  testWidgets(
    'given submit button when tapped then loading indicator is shown',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FeatureScreen(),
        ),
      );

      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'given text field when user enters value then input is reflected',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FeatureScreen(),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('emailField')),
        'a@b.com',
      );
      await tester.pump();

      expect(find.text('a@b.com'), findsOneWidget);
    },
  );
}
```

---

## Coverage Requirements

At minimum, cover the relevant subset of:

- initial rendering
- loading state
- success state
- empty state
- error state
- button tap interactions
- text input behavior

---

## Key Rules

Use stable, readable keys such as:

```dart
const Key('featureScreen')
const Key('submitButton')
const Key('emailField')
const Key('errorView')
```

Keys should be:

- stable
- predictable
- human-readable

---

## Naming Rules

Replace:

- `FeatureScreen`
- `featureScreen`
- `submitButton`
- `emailField`

With the actual feature names and IDs.

---

## Final Instruction

Keep widget tests:

- UI-focused
- deterministic
- small in scope
- centered on visible behavior
