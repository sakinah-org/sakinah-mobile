---
name: flutter-clean-architecture
description: Enforces Clean Architecture, BLoC/Cubit state management, strict directory structures, and UI conventions for Flutter projects. Use when scaffolding new features, writing UI, or refactoring Dart code.
---
# Flutter Clean Architecture & Development Guidelines

You are an expert Flutter developer adhering strictly to Clean Architecture principles. When generating, reviewing, or refactoring code for this project, you MUST follow the rules below.

## 1. Feature Scaffolding & Directory Structure
When asked to create a new feature, you must isolate it within `lib/features/[feature_name]/` and create the following exact structure:
- `data/models/`: DTOs with JSON serialization (`[model]_model.dart`).
- `data/repositories/`: Repository implementations (`[feature]_repository_impl.dart`).
- `domain/entities/`: Pure business objects (`[entity]_entity.dart`).
- `domain/repositories/`: Repository interfaces (`[feature]_repository.dart`).
- `domain/usecases/`: Specific use cases (e.g., `get_[name].dart`).
- `presentation/bloc/`: BLoC/Cubit implementation, events, and states.
- `presentation/pages/`: Screen widgets (`[feature]_page.dart`).
- `presentation/widgets/`: Extracted feature-specific UI components.

**Requirement:** Every feature must also have a `.md` file at its root describing its context.

## 2. Dependency Rules (CRITICAL)
- **Layer Flow:** Presentation depends on Domain. Data depends on Domain. Domain depends on NOTHING.
- **Cross-Feature:** NEVER import files from one feature directly into another feature. Use app-level BLoCs for shared state or `get_it` for dependency injection.
- **Singletons:** Use singletons ONLY for stateless services (e.g., `NetworkHelper`, `SharedHelper`). NEVER use singletons for mutable app state; use an App-level State Manager provided high in the widget tree instead.

## 3. State Management (BLoC / Cubit)
You must use `flutter_bloc` (or `hydrated_bloc` for persistent state). 

**Choosing between BLoC and Cubit:**
- Use **Cubit** for system/data flow and simple commands (e.g., `load()`, `refresh()`) with minimal events.
- Use **Bloc** for rich user interactions and multi-step flows (Chat, Forms, Auth).

**Naming Conventions:**
- Classes: `[Feature]Bloc` or `[Feature]Cubit`
- Events: `[Feature][Action]Event`
- States: `[Feature][Status]State`

**Required State Implementations:**
When generating states, you must account for standard flows: `Initial`, `Loading`, `Loaded`, `Empty`, `Refreshing`, `Updating`, and `Pagination`. 
When generating an `ErrorState`, you MUST use this exact structure:
```dart
class [Feature]ErrorState extends [Feature]State {
  final String message;
  final int? code;
  final Exception? exception;
  final StackTrace? stackTrace;
  final bool isRetryable;

  [Feature]ErrorState({
    required this.message,
    this.code,
    this.exception,
    this.stackTrace,
    this.isRetryable = true,
  });
}
```

## 4. UI & Widget Rules

### Thin Pages
Files inside `presentation/pages/` **must only** contain:
- Wiring (`BlocProviders`, `BlocBuilders`)
- Layout structures (`Scaffold`, high-level layout)

Business logic or reusable UI components **must not** be implemented inside pages.

---

### Widget Extraction
Any UI component displayed on a page **must be extracted** into `presentation/widgets/`.

Do **not** use private builder methods such as `_buildX()` unless the widget is extremely small (e.g., a simple `Divider` or similar one-liner).

---

### Styling Rules
Hardcoding UI styling values is **not allowed**.

Use the centralized style sources:

- **Colors:** `utils/style/app_colors.dart`
- **Typography:** `utils/style/app_typography.dart`
- **Assets:**  
  - `utils/asset/app_icons_key.dart`  
  - `utils/asset/app_images_keys.dart`