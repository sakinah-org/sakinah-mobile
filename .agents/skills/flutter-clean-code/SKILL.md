---
name: flutter-clean-code-and-standards
description: Enforces Dart and Flutter coding standards, SOLID principles, UI composition, state management built-ins, and testing rules. Use when writing, reviewing, or refactoring Dart code.
---
# Flutter & Dart Clean Code Standards

You are an expert Flutter developer. Whenever you write, modify, or review Dart code in this workspace, you MUST adhere strictly to the following rules:

## 1. Code Style & Formatting
- **Line Length:** Strictly keep lines to 80 characters or fewer.
- **Naming Conventions:** - Use `snake_case` for file names.
  - Use `PascalCase` for classes.
  - Use `camelCase` for variables, functions, and enums.
  - NEVER use abbreviations; choose meaningful and descriptive names.
- **Formatting:** Code must conform to `dart_format` and `flutter_lints` standards.

## 2. Dart Best Practices
- **Null Safety:** Write soundly null-safe code. NEVER use the bang operator (`!`) unless the value is absolutely guaranteed to be non-null.
- **Modern Features:** - Use pattern matching where it simplifies logic.
  - Use `Records` to return multiple values instead of creating cumbersome, single-use classes.
  - Use exhaustive `switch` statements or expressions (which do not require `break`).
  - Use arrow syntax (`=>`) for simple, one-line functions.
- **Error Handling:** Anticipate errors using `try-catch` blocks and use custom exceptions tailored to the specific domain. Do not let code fail silently.

## 3. Flutter UI & Widget Rules
- **Immutability:** Widgets (especially `StatelessWidget`) MUST be immutable. 
- **Const Constructors:** Use `const` constructors for widgets and within `build()` methods whenever possible to drastically reduce UI rebuilds.
- **Composition over Inheritance:** Compose complex UIs from smaller, reusable widgets. 
- **Private Widgets (CRITICAL):** Break down large `build()` methods into smaller, private `Widget` classes. NEVER use private helper methods that return a `Widget` (e.g., avoid `Widget _buildHeader() { ... }`).
- **List Performance:** Always use `ListView.builder` or `SliverList` for long lists to ensure lazy loading.
- **Heavy Computations:** Use `compute()` to run expensive calculations (like JSON parsing) in a separate isolate to prevent UI thread blocking.

## 4. State Management & Data
- **Built-in Solutions First:** Prefer Flutter's built-in state management. 
  - Use `ValueNotifier` / `ValueListenableBuilder` for simple, local state.
  - Use `ChangeNotifier` / `ListenableBuilder` for complex or shared state.
  - Use `Streams` / `StreamBuilder` for sequences of async events, and `Futures` / `FutureBuilder` for single async operations.
- **Dependency Injection:** Use simple manual constructor dependency injection to make dependencies explicit.
- **JSON Serialization:** Use `json_serializable` and `json_annotation`. Always use `fieldRename: FieldRename.snake` to convert Dart's camelCase to snake_case JSON keys.

## 5. Routing
- **Declarative Routing:** Use `go_router` for navigation, deep linking, and web support. Utilize its `redirect` property to handle authentication flows securely.
- **Ephemeral Routing:** Use the built-in `Navigator.push/pop` ONLY for short-lived screens like dialogs or temporary views.

## 6. Testing Strategy
- **Pattern:** Follow the Arrange-Act-Assert (Given-When-Then) pattern for all tests.
- **Assertions:** Prefer using the `checks` package for expressive assertions over default `matchers`.
- **Mocking:** Prefer using fakes or stubs over mocks. If mocks are strictly necessary, use `mockito` or `mocktail`.

## 7. Documentation
- Use `///` for all public API doc comments.
- Start with a single-sentence, user-centric summary ending in a period.
- Leave a blank line after the summary before continuing the explanation.
- Explain *why* the code exists or complex logic, rather than just restating what is obvious from the class/method name.