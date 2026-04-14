---
name: flutter-widgets-artest
description: Dictates the exact widgets, properties, and composition patterns to use when building Flutter UIs. Use whenever generating, designing, or refactoring Flutter widget trees.
---

# Flutter UI & Widget Composition Blueprint

You are an expert Flutter UI developer. When generating or modifying widget trees, you MUST follow these strict composition rules. Do not hallucinate custom wrappers, unsupported APIs, or legacy layouts.

---

# 1. Rows and Columns (Spacing)

- **NEVER** use `SizedBox` for spacing between children inside a `Row` or `Column`.
- **ALWAYS** use the native `spacing` parameter.
- This keeps widget trees cleaner and more maintainable.

Example:

```dart
Column(
  spacing: 16,
  children: [
    WidgetA(),
    WidgetB(),
  ],
)
```

---

# 2. Scrollable Lists & Spacing

When building lists of cards or items:

- **NEVER** add margin to the item widgets.
- **ALWAYS** use `ListView.separated`.
- Use `SizedBox` only in `separatorBuilder`.
- Apply outer spacing using the `padding` parameter of the scroll view.
- Do **NOT** add padding or margin inside list items to simulate spacing.

Example:

```dart
ListView.separated(
  padding: const EdgeInsets.all(16),
  itemBuilder: (_, index) => const ItemCard(),
  separatorBuilder: (_, __) => const SizedBox(height: 12),
  itemCount: items.length,
)
```

### Sliver Lists

Inside `CustomScrollView`:

- Use `SliverList`.
- Handle spacing manually inside the builder output.
- Do **NOT** invent APIs like `SliverList.separated`.

---

# 3. Icon Buttons

- **NEVER** wrap `IconButton` with `Container`, `Padding`, `SizedBox`, or `DecoratedBox` to modify appearance.
- **ALWAYS** use `style`.

Example:

```dart
IconButton(
  style: IconButton.styleFrom(
    backgroundColor: AppColors.primary,
    padding: const EdgeInsets.all(12),
  ),
  onPressed: () {},
  icon: const Icon(Icons.search),
)
```

---

# 4. Icon Buttons from UI Designs

When the design shows an icon inside a **circle, square, or shaped button**, follow these rules:

- **ALWAYS use `IconButton`.**
- **NEVER** create a `Container` with decoration and place an `Icon` inside it.
- The button shape, border, background, and size must be configured using the **`style` parameter of `IconButton`**.

Incorrect pattern (do NOT do this):

```dart
Container(
  decoration: BoxDecoration(shape: BoxShape.circle),
  child: Icon(Icons.close),
)
```

Correct implementation pattern:

```dart
IconButton(
  onPressed: () {},
  style: IconButton.styleFrom(
    backgroundColor: const Color(0xFF94A3B8),
    maximumSize: const Size(48, 48),
    minimumSize: const Size(48, 48),
  ),
  icon: drawSvgIcon(
    "attachments",
    width: 24,
    height: 24,
    iconColor: Colors.white,
  ),
)
```

Another example:

```dart
IconButton(
  onPressed: () {},
  style: IconButton.styleFrom(
    backgroundColor: Colors.white,
    maximumSize: const Size(38, 38),
    minimumSize: const Size(38, 38),
    shape: const CircleBorder(
      side: BorderSide(color: Color(0xFFE2E8F0)),
    ),
  ),
  icon: const Icon(
    Icons.close,
    size: 20,
    color: Color(0xFF1E293B),
  ),
)
```

---

# 5. Text Inputs & Search Fields

When implementing search:

- **NEVER** trigger search logic on every keystroke.
- **ALWAYS** implement input debouncing.
- Use either `Timer` from `dart:async` or a reactive debounce mechanism.
- Minimum debounce delay: **300–500 ms**.

This prevents excessive network calls and improves performance.

---

# 6. Anti-Hallucination Mandate

- Do **NOT** invent Flutter widgets or parameters.
- Do **NOT** introduce unsupported constructors or APIs.
- Do **NOT** create custom wrappers for standard Material components unless they already exist in the project.

All styling must come from project utilities:

- `style/app_colors.dart`
- `style/app_typography.dart`

Never hardcode:

- Hex colors
- `TextStyle` definitions
- Font sizes

---

# 7. Widget Extraction

Pages must remain **thin**.

Rules:

- Pages should mainly contain layout composition and state wiring.
- UI sections must be extracted into reusable widgets.
- Avoid large `build()` methods.
- Reusable UI components belong in `presentation/widgets/`.

Preferred structure:

```
presentation/pages/
presentation/widgets/
```

---

# 8. Avoid Private Widget Builder Methods

Avoid using private helper methods like:

- `_buildHeader()`
- `_buildCard()`
- `_buildSection()`

These patterns should be avoided for UI separation.

Instead:

- Extract widgets into dedicated classes.
- Place reusable components in `presentation/widgets/`.

Private widget methods may only be used for **very small one-line widgets**.

---

# 9. Padding Ownership

Spacing responsibility must be clearly defined.

Rules:

- **Page containers control outer spacing.**
- **Components control internal spacing.**

Avoid stacking padding unnecessarily.

Example of problematic pattern:

```dart
Padding(
  padding: const EdgeInsets.all(16),
  child: Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 12,
        children: [],
      ),
    ),
  ),
)
```

Prefer clear spacing ownership.

---

# 10. Typography Discipline

Typography must follow project tokens.

Rules:

- Always use predefined typography styles.
- Do **NOT** create inline `TextStyle(...)`.

Correct usage example:

```dart
Text(
  'Title',
  style: AppTypography.titleLarge,
)
```

---

# 11. Scroll Safety Rules

Avoid problematic scroll layouts.

Rules:

- Do **NOT** place `ListView` inside `Column` without constraints.
- Prefer `Expanded` or slivers when mixing scrollable and non-scrollable content.
- Avoid `shrinkWrap: true` unless absolutely necessary.

Correct pattern:

```dart
Expanded(
  child: ListView(
    children: [],
  ),
)
```

---

# 12. UI State Coverage

Every data-driven screen must support these states:

- Loading
- Empty
- Success
- Error

Never assume data always exists.

Provide clear fallback widgets for each state.

Example:

```dart
switch (state) {
  case ViewState.loading:
    return const LoadingIndicator();
  case ViewState.empty:
    return const EmptyStateWidget();
  case ViewState.error:
    return const ErrorStateWidget();
  case ViewState.success:
    return const ContentWidget();
}
```

---

# Core Principle

Flutter UI must be:

- Consistent  
- Predictable  
- Composable  
- Non-hallucinated  

The widget tree should always reflect **native Flutter patterns and project design tokens**.