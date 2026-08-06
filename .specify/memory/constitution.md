<!--
Sync Impact Report
==================
Version change: [TEMPLATE] → 1.0.0 (initial ratification)
Modified principles: N/A (first concrete version; all placeholders replaced)
Added sections:
  - Core Principles (I–VIII)
  - Technology Stack & Dependencies
  - Development Workflow
  - Governance
Removed sections: none (template placeholders only)
Templates requiring updates:
  - .specify/templates/*.md — not modified by this command (scope guard); no
    outstanding placeholder mismatches detected against this constitution.
Follow-up TODOs:
  - TODO(RATIFICATION_DATE): no prior constitution or historical adoption
    record exists in the repo; ratification date set to the date this
    constitution was authored (2026-08-06). Correct if an earlier date applies.
-->

# Sakinah Constitution

## Core Principles

### I. Feature-First, Complexity-Scaled Architecture
Code lives under `lib/` in fixed top-level layers — `configurations/`,
`network/`, `navigation/`, `handlers/`, `shared/`, `utils/`, `toolkit/`,
`features/` — and every feature is a self-contained folder under
`lib/features/<feature_name>/`. Features MUST NOT import from one another
directly; cross-feature sharing goes through `lib/shared/` (global blocs,
models, widgets) or `lib/handlers/`.

Within a feature, the layering depth MUST match its actual complexity:

- **Business-logic features** (own data fetching, multi-step flows, unique
  domain rules) use the full Clean Architecture split:
  `data/{models,repositories}`, `domain/{entities,repositories,usecases}`,
  `presentation/{bloc,pages,widgets}`, with the dependency rule
  Presentation → Domain ← Data and Domain depending on nothing.
- **UI-only features** (settings screens, static/about pages, navigation
  hubs that only trigger actions already owned by a shared/global cubit)
  get a `presentation/` (or `ui/`) folder only — no repositories, use
  cases, or duplicate entities. The current `lib/features/main/ui/` module
  (pages + widgets, no data/domain layer) is the reference example.

Before adding new state management or data-layer code to a feature, check
`lib/shared/bloc/` and `lib/shared/models/` for an existing owner of that
state or model. Duplicating state that already has a global home is a
constitution violation, not a stylistic nit.

**Rationale**: This project's own incident log (`.agents/rules/ai_agent_mistakes_log.md`)
records repeated over-engineering — full Clean Architecture stacks built for
what were really thin UI wrappers around existing shared state. Scaling
layering to actual complexity keeps the codebase both consistent and lean.

### II. BLoC/Cubit State Management
`flutter_bloc` is the sole state management library; `hydrated_bloc` is
available for state that must persist across restarts. Do not introduce
Provider, Riverpod, GetX, or raw `setState`-only architectures for
non-ephemeral state.

- **Cubit** for state driven by simple commands/data flow with minimal
  event orchestration (lists, dashboards, settings toggles).
- **Bloc** for rich user interaction with multi-step flows where explicit,
  named events aid traceability (forms, auth, wizards). Event handlers
  MUST be named methods (`on<FetchEvent>(_onFetch)`), never inline
  anonymous closures, with explicitly typed event/emitter parameters.
- States extend the shared `AppStates` hierarchy
  (`lib/configurations/app_states.dart`: `InitialState`, `LoadingState`,
  `LoadedState(data)`, `EmptyState`, `ErrorState(errorMessage)`) unless a
  feature's complexity genuinely warrants its own typed state classes —
  in which case follow the `[Feature][Status]State` naming convention
  documented in `.agents/rules/architecture.md`.
- **Global/shared cubits** (`SettingsCubit`, `UserCubit` in
  `lib/shared/bloc/`) follow the existing singleton pattern: private
  named constructor + `static instance` — e.g.
  `SettingsCubit._internal() : super(InitialState()); static SettingsCubit instance = SettingsCubit._internal();`
  Reserve this pattern for cross-app state exposed at the widget-tree root
  via `BlocProvider`. Do not make feature-local, per-screen state a
  singleton — that state is provided/scoped normally through
  `BlocProvider` at the point of use.

**Rationale**: Matches the actual `SettingsCubit`/`UserCubit` implementation
and the explicit Cubit-vs-Bloc guidance already agreed for this project.

### III. No Service-Locator Dependency Injection
This project does NOT use `get_it`, `injectable`, or any service locator.
Dependencies are wired manually: shared services are singletons accessed
via a static `instance` getter (`AppEnv.instance`, `DioClient.instance`,
`AESEncryptor.instance`, `SharedPrefHandler.instance`), and state is
provided to the widget tree via `BlocProvider`/`MultiBlocProvider`. Do not
add a service locator package or `injectable` codegen without an explicit,
separate decision to change this principle.

**Rationale**: `.agents/rules/ai_agent_mistakes_log.md` (Mistake #4) records
this as a corrected, deliberate decision after AI agents repeatedly
introduced `get_it` unprompted — `get_it` is not and has never been a
project dependency (see `pubspec.yaml`).

### IV. Centralized Design System — Theme, Typography, Assets
All visual tokens live in `lib/utils/` and are the only source of truth for
styling; UI code MUST NOT hardcode colors, font sizes, or asset path
strings inline.

- `lib/utils/style/app_colors.dart` — `AppColors`, an abstract class of
  `static const Color` tokens: a base palette (`teal900`…`neutral0`) plus
  co-equal `light*`/`dark*` semantic tokens (`lightBg`/`darkBg`,
  `lightTextPrimary`/`darkTextPrimary`, `lightBrandPrimary`/…) and
  shared semantic state colors (`success`, `error`, `warning`, `info`).
  New colors are added as a base-palette token first, then exposed through
  a light/dark semantic pair if the UI needs it.
- `lib/utils/style/app_typography.dart` — `AppTypography`, an abstract
  class of `static const TextStyle` tokens per role (`h1Light/Dark`,
  `body1/2/3 Light/Dark`, `buttonLight/Dark`, `displayLight/Dark`,
  `quranLight/Dark`), built from three named font families:
  `uiFontFamily` ("Tajawal", the UI workhorse), `quranFontFamily`
  ("Lateef", reserved for Quranic verse text), and `ornamentalFontFamily`
  ("KFGQPC Nastaleeq", ornamental/wordmark use only — do not use it for
  body or UI text). `lightTextTheme`/`darkTextTheme` map these onto
  Flutter's `TextTheme` slots for `ThemeData.textTheme`.
- `lib/utils/style/app_theme.dart` — `lightTheme`/`darkTheme`, two
  top-level `ThemeData` constants (Material 3) that compose `AppColors`
  and `AppTypography` into `colorScheme`, and per-component themes
  (`appBarTheme`, `elevatedButtonTheme`, `cardTheme`, `inputDecorationTheme`,
  etc). New component styling belongs in the relevant `*Theme` block here,
  not scattered through widgets.
- `lib/utils/assets/app_icons_keys.dart` (`AppIcons`) and
  `app_images_keys.dart` (`AppImages`) — abstract classes of
  `static const String` keys. Icons are bare names consumed via
  `drawSvgIcon(AppIcons.home, …)` (`lib/shared/widgets/icon_handler.dart`),
  which resolves `assets/icons/<name>.svg`. Images are full paths built
  from a private `_basePath` (`assets/images/<file>`). Every new icon/image
  asset gets a key added here before use — no ad hoc asset path strings
  in feature code.

**Rationale**: Reflects the existing, already-fairly-mature design-system
layer; `.agents/rules/flutter_rules.md`'s Utils Folder rules independently
confirm "UI must consume styles only from this folder."

### V. Reusable Widgets Over Inline Build Methods
Shared, cross-feature UI primitives live in `lib/shared/widgets/`
(optionally under a subfolder like `fields/` for form inputs — see
`TextInputField`, `country_input_field.dart`, `date_input_field.dart`).
Feature-specific but non-trivial UI pieces (a card, a chip, a list item,
a bottom nav bar) MUST be extracted into their own `StatelessWidget` /
`StatefulWidget` class — under the feature's own `ui/widgets/` (or
`presentation/widgets/`) folder for feature-specific ones, or
`lib/shared/widgets/` for anything reused across features. Private
`Widget _buildX()` methods returning non-trivial sub-trees inside a page
class are not acceptable; only tiny one-liners (a fixed `SizedBox` spacer,
a plain `Divider`) may stay inline. Pages under `.../pages/` stay thin:
wiring, layout, and composition of already-extracted widgets only.

Utility/cross-cutting logic that is not a widget goes in
`lib/handlers/` as a plain class (see `ImagePickerHandler`,
`SharedPrefHandler`, `AESEncryptor`) — instance methods for stateful
device/service interaction, thrown `Failure` subclasses
(`lib/configurations/app_errors.dart`) for error paths, not raw
exceptions. `lib/toolkit/` holds framework-light helpers: extensions
(`context_extensions.dart`, `date_time_extensions.dart`,
`file_extensions.dart`), `Debouncer`, and the `Validations` mixin.

**Rationale**: Directly codifies `ai_agent_mistakes_log.md` Mistake #7
(inline `_buildCategoryChip()`-style helpers instead of dedicated widget
classes) and the existing split between `handlers/` (stateful services)
and `toolkit/` (stateless helpers/extensions).

### VI. Dio-Based Network Layer with Typed Failures
All HTTP calls go through `DioClient.instance` (`lib/network/network_handler.dart`),
a singleton wrapping a single `Dio` instance configured with
`AppEnv.instance.baseUrl` and a logging `InterceptorsWrapper`. Callers
build a `RequestInstructions` (`lib/network/request_instructions.dart`:
url, method, query params, body, `Options`, cancel token, progress
callback) and call `DioClient.instance.request(instructions)` — do not
call `dio.get/post/...` directly from feature code, and do not construct
a second `Dio` instance. `DioLoggingInterceptor` (`lib/network/dio_interceptor.dart`)
is the `logger`-based alternative interceptor; keep request/response/error
logging centralized in `lib/network/`, not duplicated per feature.

Every network error MUST be normalized through
`Failure.handleDioException(DioException)` (`lib/configurations/app_errors.dart`)
into one of the existing `Failure` subclasses (`ConnectionFailure`,
`TimeoutFailure`, `ServerFailure`, `BadRequestFailure`, `UnauthorizedFailure`,
`NotFoundFailure`, `ValidationFailure`, `UnknownFailure`, plus
feature-appropriate ones like `ImagePickerFailure`). New failure types
extend the shared `Failure` base directly — never introduce a
feature-specific abstract failure hierarchy.

**Rationale**: Matches the current `DioClient`/`RequestInstructions`/`Failure`
implementation, and Mistake #1 in the mistakes log explicitly forbids
feature-specific abstract failure classes in favor of one global hierarchy.

### VII. Configuration, Environment, and Localization as Single Sources of Truth
Environment values (base URL, allowed domains, security key) come only
from `AppEnv.instance`, populated via `flutter_dotenv` from
`assets/env/.env.<environment>` and selected by the `env` string in
`main.dart`. Never hardcode a base URL, API key, or environment flag in
feature code — add it to `AppEnv` and the relevant `.env.*` file. API
paths/keys go in `lib/configurations/app_end_points.dart`
(`AppEndPoints`), persisted-storage key names in
`app_persistence_data_keys.dart` (`AppPersistenceDataKeys`), and
localization keys in `app_translation_keys.dart` (`TranslationKeys`) —
each is an abstract class of `static const String` constants; no magic
strings for these concerns anywhere else.

Localization: `assets/lang/en.json` and `assets/lang/ar.json`, loaded by
`GlobalTranslations`/`translator` in `lib/handlers/translation_handler.dart`
via `translator.word(key)` (or `translator.text([...])` for concatenated
keys), keyed against `TranslationKeys`. `Locale('en')`/`Locale('ar')` are
the two supported locales; language switching goes through
`SettingsCubit.toggleLocale()`.

Local persistence uses `SharedPrefHandler` (`lib/handlers/shared_handler.dart`),
a Hive-backed singleton (`Hive.initFlutter()` + a single named box)
initialized once at startup — not raw `shared_preferences` or ad hoc
`Hive.box()` calls scattered through the app.

**Rationale**: These are the project's existing, deliberately centralized
lookup tables; bypassing them (hardcoded strings, direct `dotenv.env[...]`
reads outside `AppEnv`, ad hoc Hive boxes) reintroduces the scattered
config that these classes exist to prevent.

### VIII. Naming, Formatting, and Test Discipline
Files are `snake_case.dart`; classes are `PascalCase`; members, variables,
functions, and enum values are `camelCase`. BLoCs/Cubits follow
`[Feature]Bloc` / `[Feature]Cubit`; events follow `[Feature][Action]Event`;
states follow `[Feature][Status]State` when a feature has its own typed
states. Format with `dart format`; lint against
`package:flutter_lints/flutter.yaml` (`analysis_options.yaml`); run
`flutter analyze` clean before considering a change done.

Testing currently has close to no real coverage — `test/widget_test.dart`
is the unmodified Flutter counter-app template and does not exercise
`MyApp`. Do not treat its presence as a signal that testing conventions
are established; when adding tests, follow the AAA
(Arrange-Act-Assert)/Given-When-Then structure and the unit-test-first,
fake-over-mock guidance in `.agents/rules/test_suite_guide.md`
(`mocktail`/`bloc_test` for BLoC/Cubit logic, fakes for repositories,
minimal real integration tests). New or changed business logic (Cubit/Bloc
transitions, validators, repository orchestration) SHOULD ship with a
unit test; UI-only widget changes are not required to.

**Rationale**: States the real baseline honestly (near-zero coverage)
rather than implying a maturity the codebase doesn't have, while pointing
at the already-written test-strategy doc so future test work has a
consistent shape from the start.

## Technology Stack & Dependencies

Flutter SDK `^3.5.3`. Core dependencies actually in use
(`pubspec.yaml`) and their role — treat this as the approved stack; adding
a new package in a category that's already covered here requires a
reason, not just preference:

- **State management**: `flutter_bloc ^9.1.0`, `hydrated_bloc ^10.0.0`
- **Network**: `dio ^5.7.0`
- **Functional error handling**: `dartz ^0.10.1`, `either_dart ^1.0.0`
  (both present; prefer one consistently within a given piece of code —
  do not mix `Either` types from both packages in the same signature)
- **Local storage**: `hive_flutter ^1.1.0`
- **Env config**: `flutter_dotenv ^6.0.0`
- **Security**: `encrypt ^5.0.3` (via `AESEncryptor`)
- **Device/media**: `image_picker`, `file_picker`, `open_file`,
  `path_provider`, `permission_handler`, `mime`
- **Localization**: `flutter_localizations` (SDK) + the custom
  `GlobalTranslations` delegate; `intl ^0.20.2`
- **UI**: `flutter_svg`, `cached_network_image`, `shimmer_animation`,
  `carousel_slider`, `table_calendar`, `calendar_date_picker2`,
  `flutter_staggered_grid_view`, `dotted_line`, `qr_flutter`,
  `video_player`, `flutter_html`, `country_picker`,
  `country_code_picker`, `currency_picker`
- **Dev/test**: `flutter_lints ^4.0.0`, `mocktail ^1.0.4`, `logger ^2.5.0`

Explicitly NOT part of the current stack — do not add without a deliberate,
separate decision to amend this constitution: `get_it`/`injectable` (see
Principle III), `go_router`/`auto_route` (routing is `Navigator` +
`onGenerateRoute`, see below), `freezed`/`json_serializable`/`build_runner`
(models are hand-written, e.g. `User.fromJson`/`toJson` in
`lib/shared/models/user.dart`), `provider`, `riverpod`, `get`.

### Navigation
Routes are string constants on `AppRoutes` (`lib/navigation/app_routes.dart`)
and resolved by `generateRoute()` (`lib/navigation/route_generator.dart`),
a `switch` on `RouteSettings.name` returning a shared `PageRouteBuilder`
(`_createRoute`) with a fade + subtle-slide-up transition. `MaterialApp`
wires this via `onGenerateRoute: generateRoute` and `initialRoute` in
`lib/main.dart` — no named-route argument passing beyond what
`RouteSettings.arguments` provides. New screens: add a route constant to
`AppRoutes`, add a `case` in `generateRoute()`, navigate with
`Navigator.pushNamed(context, AppRoutes.yourRoute)`. Do not introduce
`go_router` or a second routing mechanism alongside this one.

## Development Workflow

Before writing code for a new feature or change:

1. Check `lib/shared/bloc/`, `lib/shared/models/`, and `lib/handlers/`
   for existing state, models, or utilities that already cover part of
   the requirement (Principle I) — this is the single most common
   correction recorded in `.agents/rules/ai_agent_mistakes_log.md`.
2. Decide UI-only vs business-logic feature and scope the folder
   structure accordingly (Principle I).
3. Add any new colors/typography/icons/images to `lib/utils/` first
   (Principle IV) rather than inlining them at the point of use.
4. Extract non-trivial UI into dedicated widget classes as you write the
   page, not as a later refactor (Principle V).
5. Route all network calls through `DioClient.instance` with a
   `RequestInstructions`, mapping errors through `Failure.handleDioException`
   (Principle VI).
6. Run `dart format` and `flutter analyze` before considering work done
   (Principle VIII); add unit tests for new business logic where
   applicable.

Consult `.agents/rules/ai_agent_mistakes_log.md` before starting non-trivial
feature work — it is a living record of corrections specific to this
codebase and takes precedence over generic Flutter/Clean-Architecture
advice (including the more elaborate, aspirational layering examples in
`.agents/rules/architecture.md` and the generic package recommendations —
e.g. `go_router`, `freezed`, `get_it` — in `.agents/rules/flutter_rules.md`)
wherever the two conflict. Those two files describe a general-purpose
target pattern library; this constitution and the mistakes log describe
what this specific project has actually decided.

## Governance

This constitution is the authoritative source for architectural and
conventions questions in this repository; where it conflicts with generic
guidance in `.agents/rules/` or `.agents/skills/`, this constitution wins.
It does not supersede explicit, contemporaneous instructions from the
project owner for a specific task.

**Amendments**: Propose changes via the same mechanism used to create this
document (`/speckit-constitution`). A change must state which principle(s)
it touches and why (typically: a new package/pattern was deliberately
adopted, or an existing rule proved wrong in practice — record the latter
in `.agents/rules/ai_agent_mistakes_log.md` too, since that log is where
project-specific lessons are meant to accumulate).

**Versioning**: Semantic versioning for this document —
MAJOR for backward-incompatible principle removals/redefinitions
(e.g., adopting `get_it` and reversing Principle III), MINOR for adding a
principle or materially expanding guidance, PATCH for wording/clarity
fixes that don't change a rule's meaning.

**Compliance review**: Non-trivial PRs/changes should be checked against
the Core Principles above, particularly Principle I (don't over-layer
UI-only features), Principle III (no service locator), and Principle IV
(no inline styling/asset paths). When in doubt about an existing
inconsistency in the codebase (e.g. legacy leftovers from the project's
template origin), fix it in the same change if it's directly touched,
otherwise leave it and note it rather than silently working around it.

**Version**: 1.0.0 | **Ratified**: 2026-08-06 | **Last Amended**: 2026-08-06
