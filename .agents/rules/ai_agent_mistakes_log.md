# AI Agent Mistakes Log

Version: V0.6.1

---

## Purpose

This file is used to track recurring mistakes made by AI agents and document how to avoid them in future prompts or validations.

It acts as a continuous learning artifact for the Prompt Validator & Refiner.

---

## Versioning Scheme

Format: Vx.y.z

- x → Number of major edits per project (structural changes to this file)
- y → Number of distinct mistakes recorded
- z → Number of edits/refinements applied to existing mistakes

Update rules:

- Increment **y** when adding a NEW mistake.
- Increment **z** when updating an EXISTING mistake.
- Increment **x** when changing the structure or philosophy of this file.

Example:
- V0.1.0 → first mistake added
- V0.1.1 → same mistake refined
- V1.0.0 → major restructuring

---

## How to Use

For every detected mistake:

1. Add a new section under "Mistakes".
2. Describe what went wrong.
3. Explain why it happened.
4. Write explicit prevention rules.
5. Update the version accordingly.

Keep entries short, factual, and actionable.

---

## Template (copy for each mistake)

### Mistake #[ID] — Short Title

**Description**
What the agent did wrong.

**Root Cause**
Why this happened.

**Correct Behavior**
What should have happened instead.

**Prevention Rules**
- Bullet rules for the Prompt Validator.

---

## Mistakes

### Mistake #1 — Non-standard Failure Hierarchy

**Description**
The agent created feature-specific abstract failure classes (e.g., `InvoiceFailure`, `CheckoutFailure`) instead of standardizing specific failures to inherit directly from the global `Failure` class.

**Root Cause**
Over-prioritizing feature modularity by creating redundant abstract layers for error handling instead of adhering to the standardized application-wide `Failure` base class.

**Correct Behavior**
All domain-specific failures (e.g., `StockValidationFailure`, `InvoiceNotFoundError`) must extend the global `Failure` class from `lib/core/error/failures.dart`. All Repository and UseCase signatures must use `Either<Failure, T>` to maintain a consistent error handling interface.

**Prevention Rules**
- Always use `lib/core/error/failures.dart` as the base for all domain failures.
- NEVER create feature-specific abstract failure classes (e.g., avoid `abstract class FeatureFailure`).
- Ensure all `Either` return types in the Domain Layer use the global `Failure` type.
- Verify that specific failures provide the required named parameters (like `message`) defined in the core `Failure` class.


---

### Mistake #2 — Ignoring Existing Shared State Management

**Description**
When generating the Settings feature super prompt, the agent created a new `SettingsBloc`, `UserProfileEntity`, `UserProfileModel`, and full repository/data layer architecture, completely ignoring that the project already has:
- `UserCubit` (global) for user profile data
- `AuthBloc` (global) for authentication actions (logout, delete account)
- `SettingsCubit` (shared) pre-defined for settings-specific state

**Root Cause**
The agent applied the Clean Architecture pattern mechanically without first analyzing the existing project structure to identify reusable shared components. This resulted in duplicate state management and unnecessary boilerplate.

**Correct Behavior**
Before creating any new state management components, the agent should:
1. Check `lib/shared/bloc/` and `lib/app/bloc/` for existing global cubits/blocs
2. Identify which actions already have handlers (e.g., logout → AuthBloc)
3. Reuse existing entities and models from shared layers
4. Only create feature-specific UI components that consume the shared state

For the Settings feature specifically:
- Use `UserCubit` for profile data display
- Use `AuthBloc` for logout and delete account actions
- Use the existing `SettingsCubit` from shared folder
- Only create `SettingsPage` and its widgets

**Prevention Rules**
- ALWAYS check `lib/shared/bloc/`, `lib/app/bloc/`, and `lib/shared/models/` before creating new state management
- If a feature is primarily a UI wrapper around existing actions (like Settings), DO NOT create repositories or use cases
- ASK: "Does this action already exist in a global bloc?" before creating domain/data layers
- Settings/Profile pages are almost always UI-only features that consume shared state

---

### Mistake #3 — Over-Engineering Simple UI Features

**Description**
The agent proposed creating a full Clean Architecture stack (Domain → Data → Presentation) with repository, data sources, use cases, and mock backend integration for the Settings page, which is simply a navigation hub with action buttons.

**Root Cause**
The agent treated every feature request as requiring the full architectural stack without assessing the feature's actual complexity. Settings is a **presentation-only feature** that delegates all business logic to existing shared blocs.

**Correct Behavior**
Distinguish between:
- **Business Logic Features** (Cart, Checkout, Orders) → Need Domain/Data/Presentation layers
- **UI-Only Features** (Settings, About, Help) → Only need Presentation layer + shared state consumption

For UI-only features:
- No repositories
- No use cases
- No data sources
- No new entities/models if they exist in shared
- Only pages and widgets that compose existing cubits/blocs

**Prevention Rules**
- Before designing architecture, ASK: "Does this feature contain unique business logic or just display/trigger existing actions?"
- If the feature is described as "settings", "about", "help", "profile view", it is likely UI-only
- UI-only features should ONLY have a `presentation/` folder with pages and widgets
- NEVER create mock data sources for features that don't fetch unique data
- Settings pages should be treated as **navigation hubs**, not data-driven features

---


---

### Mistake #4 — Ignoring User Preference on Dependency Injection

**Description**
The agent repeatedly included `get_it` and `injectable` in the architecture stack despite the user's preference for manual dependency injection or `BlocProvider`.

**Root Cause**
The agent adhered too strictly to a "standard" Clean Architecture template without checking for project-specific constraints or user preferences regarding DI frameworks.

**Correct Behavior**
- Check project conventions or ask the user before enforcing a DI framework.
- If the user prefers manual injection or specific tools (like `BlocProvider`), use those instead of `get_it`.
- Update architectural templates to reflect the user's choice (e.g., "Manual Injection / BlocProvider").

**Prevention Rules**
- Default to **Manual Injection** or **BlocProvider** unless `get_it` is explicitly requested.
- Review `pubspec.yaml` to see if `get_it` is even a dependency before suggesting it.
- When generating super prompts, state "Dependency Injection: Manual / Provider" as the default.

---

### Mistake #5 — Anonymous Callbacks in Blocs

**Description**
Used anonymous functions in `on<Event>` handlers instead of named callback methods, and failed to explicitly type the event parameter.

**Root Cause**
Rushing implementation or not adhering to strict clean code practices for Bloc, leading to less readable and harder-to-maintain code.

**Correct Behavior**
- Define private methods like `_onFetchInvoice` and pass them as tear-offs or closures to `on<Event>`.
- Explicitly type the event and emitter parameters in the callback method signature.

**Prevention Rules**
- Always use named callback methods for Bloc event handlers (e.g., `on<Event>(_onEvent)`).
- Ensure event parameters in callbacks are typed explicitly (e.g., `Future<void> _onEvent(Event event, Emitter<State> emit)`).
- This improves readability and stack trace clarity.

---

### Mistake #6 — Ignoring Figma Design Details / Low Match Percentage

**Description**
Failed to accurately match the provided Figma design (match < 45%). Missed layout structures like section ordering, card sizing, search bar styling (rounded, color `#E9E9E9`, suffix icons without background/shadow), and the complete custom app bar design.

**Root Cause**
Overlooked the visual specifics in the Figma screenshots/links, relying heavily on generic Material widget compositions instead of customizing them to match exact design tokens and layout hierarchy.

**Correct Behavior**
- Carefully analyze provided Figma links or screenshots for exact layout hierarchy, section ordering, and widget styling.
- Extensively customize `AppBar` or standard widgets to match the provided references perfectly.
- Ensure proper mapping of sections (e.g., Opportunities as a vertical card, Essential Deals as horizontal small cards).

**Prevention Rules**
- Always review Figma references down to granular details (e.g., border radius, suffix icons, badges, background hex colors).
- Do not assume section orders; verify which section is on top (e.g., Opportunities above Essential Deals).
- Ensure headers, titles, and specific UI elements like filter chips are implemented precisely as shown.

---

### Mistake #7 — Not Extracting UI Components into Separate Widgets

**Description**
The agent built a complex UI list (e.g., category chips with custom states and styling) as an inline private returned function block (like `_buildCategoryChip()`) within the main page widget instead of extracting it into a separate reusable StatelessWidget file.

**Root Cause**
Taking a shortcut to build UI quickly within the main page file instead of separating concerns and following Flutter's best practices of composing UIs from smaller, dedicated widget classes.

**Correct Behavior**
UI components that represent distinct visual entities, especially those repeated in lists (like chips, cards, list items), must be extracted into their own widget classes inside the `presentation/widgets/` directory.

**Prevention Rules**
- Always extract individual UI components like cards, chips, buttons, list items, or simple rows (e.g. `_buildMetaItem`) into separate Widget classes.
- Place extracted feature-specific widgets in the `lib/features/<feature_name>/presentation/widgets/` folder.
- Do not use private methods (e.g., `Widget _build(...)`) to construct widget sub-trees within a page; use proper StatelessWidgets instead.

---

End of file.
