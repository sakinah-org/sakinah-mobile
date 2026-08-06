# Implementation Plan: User Authentication (Login, Register, Forgot Password)

**Branch**: `001-user-authentication` | **Date**: 2026-08-06 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-user-authentication/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Add a five-screen authentication flow (Login, Register, Forgot Password, Verify OTP, Reset Password) backed directly by Supabase Auth. Each screen gets its own `Bloc`; a new app-scoped `SessionCubit`, provided at the `MaterialApp` root, owns reading/caching/refreshing the signed-in flag, AES-encrypted access/refresh tokens, and the cached user profile via the existing Hive-backed `SharedPrefHandler` — it is the single place the rest of the app queries for login state. Login pops back to the screen that launched it (Settings); Register and Reset Password pop back to Login with a success snackbar. Visuals follow the already-imported Sakinah design system, which is confirmed to already match this codebase's `AppColors`/`AppTypography` tokens and its existing `TextInputField` widget pattern.

## Technical Context

**Language/Version**: Dart / Flutter SDK `^3.5.3` (existing project constraint, unchanged)

**Primary Dependencies**: `flutter_bloc ^9.1.0` (Bloc per screen + `SessionCubit`), `supabase_flutter` (**new** — Supabase Auth: password sign-in/sign-up, email OTP recovery, password update; latest version compatible with the Flutter SDK constraint above, resolved at implementation time), `hive_flutter ^1.1.0` (via existing `SharedPrefHandler`), `encrypt ^5.0.3` (via existing `AESEncryptor`), existing `Validations` mixin (`lib/toolkit/validations.dart`)

**Storage**: Local only — Hive box via `SharedPrefHandler` (`is_login` flag, AES-encrypted access token, AES-encrypted refresh token, user profile as a native Hive `Map`). Remote user/account records live in Supabase (external system of record; no local database).

**Testing**: `mocktail` + `bloc_test` for the five Blocs and `SessionCubit` (fake repository/Supabase client, no live network calls); `flutter analyze` clean; manual verification against `quickstart.md` for the visual/RTL match to the design reference.

**Target Platform**: Existing Android/iOS/macOS Flutter app (no new platform surface)

**Project Type**: Mobile app (single Flutter project, existing `lib/` layering)

**Performance Goals**: Screen transitions and form validation feedback perceived as instant (<100ms, standard Flutter UI-thread work only); network-bound actions (login, register, OTP send/verify, password reset) limited only by Supabase round-trip time, not app-side processing.

**Constraints**: Tokens must never be persisted unencrypted (spec FR-006); OTP resend cooldown must be a real elapsed-time 60s countdown survivable across app backgrounding (spec Edge Cases); all five screens must render correctly in both the app's existing light/dark themes and in RTL (Arabic, the design's primary direction) and LTR (English) locales, consistent with `SettingsCubit.toggleLocale()`.

**Scale/Scope**: 5 screens (Login, Register, Forgot Password, Verify OTP, Reset Password), 5 screen-level Blocs + 1 app-scoped `SessionCubit`, 1 new feature module (`lib/features/auth/`), extends 2 existing shared files (`AppRoutes`, `route_generator.dart`) and touches `main.dart` (provide `SessionCubit`, initialize Supabase) — no backend/server code (Supabase is managed externally).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
|---|---|---|
| **I. Feature-First, Complexity-Scaled** | Auth is a business-logic feature (owns data fetching via Supabase, multi-step OTP flow, unique domain rules) → full Clean Architecture split under `lib/features/auth/{data,domain,presentation}/`. `SessionCubit` is cross-app state → lives in `lib/shared/bloc/`, not inside the feature, per the "check `lib/shared/bloc/` first" rule. | PASS |
| **II. BLoC/Cubit State Management** | Five screens with multi-step, named-event flows (login, register, forgot-password, verify-otp, reset-password) → `Bloc` each, per the constitution's own example list ("forms, auth, wizards"). `SessionCubit` is simple retrieve/cache/hold/refresh command flow → `Cubit`, global singleton pattern matching `SettingsCubit`/`UserCubit`. Named event-handler methods only, no inline closures. | PASS |
| **III. No Service-Locator DI** | No `get_it`/`injectable` introduced. `Supabase.instance.client` (initialized once in `main.dart` via `Supabase.initialize(...)`) is itself a static-singleton accessor, consistent with the existing `AppEnv.instance` / `AESEncryptor.instance` pattern — not a service locator. Repositories are constructed manually and passed into Blocs at the point of use (`BlocProvider`), same as the rest of the app. | PASS |
| **IV. Centralized Design System** | All 5 screens consume only `AppColors`/`AppTypography`/`app_theme.dart`; the referenced design tokens (colors, spacing, typography) already match these files 1:1 (verified against the design's `tokens/*.css`). New icons needed (email, password/lock, eye/eye-off) get added to `AppIcons` + `assets/icons/` before use, not inlined. | PASS |
| **V. Reusable Widgets Over Inline Build** | Existing `lib/shared/widgets/fields/text_input_field.dart` already implements the exact label-above + bordered-container + prefix/suffix-icon pattern the design uses for every text field across all 5 screens — reused as-is, no duplicate field widget. One genuinely new shared primitive is needed: a 6-box OTP code input (`OtpCodeInput`, `lib/shared/widgets/fields/`) since nothing like it exists yet. Feature-specific composite widgets (e.g. a password-rules hint row) go under `lib/features/auth/presentation/widgets/`. | PASS |
| **VI. Dio-Based Network Layer** | Supabase Auth (`gotrue-dart`, bundled inside `supabase_flutter`) manages its own HTTP transport internally as a vendored SDK — it is not a raw REST call `DioClient`/`RequestInstructions` can wrap. This is a deliberate, explicit, contemporaneous instruction from the project owner to integrate directly with Supabase for auth. All *other* future HTTP calls in the app continue through `DioClient.instance` unchanged; this exception is scoped to the Supabase Auth SDK boundary only. **Documented in Complexity Tracking below.** | CONCERN — justified |
| **VII. Configuration/Env as Single Source of Truth** | New `SUPABASE_URL` / `SUPABASE_ANON_KEY` values added to `AppEnv` (populated from `assets/env/.env.<environment>`, same pattern as the existing `securityKey`/`baseUrl`), not hardcoded. New Hive keys added to `AppPersistenceDataKeys` (`accessToken`, `refreshToken` — `userData`/`isLogin` already exist and are reused). New copy strings added to `TranslationKeys` + `assets/lang/{en,ar}.json`, consumed via `translator.word()` — no hardcoded UI strings. | PASS |
| **VIII. Naming/Formatting/Test Discipline** | `LoginBloc`/`RegisterBloc`/`ForgotPasswordBloc`/`OtpBloc`/`ResetPasswordBloc` + matching `[Feature][Action]Event`/`[Feature][Status]State` naming; `SessionCubit` follows the `SettingsCubit`/`UserCubit` singleton convention. `bloc_test` unit tests planned for all 5 Blocs + `SessionCubit` transition logic. | PASS |

**Overall**: PASS with one documented, explicitly-authorized exception (Principle VI, Supabase SDK boundary — see Complexity Tracking).

## Project Structure

### Documentation (this feature)

```text
specs/001-user-authentication/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

This is a single Flutter mobile app (existing `lib/` layering per the constitution) — no separate frontend/backend split, no new platform target. Auth is a business-logic feature, so it gets the full Clean Architecture split (Principle I); `SessionCubit` is cross-app state and lives in `lib/shared/bloc/` instead.

```text
lib/
├── main.dart                              # MODIFIED: init Supabase, provide SessionCubit at app root, retrieve session before first frame
├── configurations/
│   ├── app_env.dart                       # MODIFIED: add supabaseUrl, supabaseAnonKey
│   ├── app_persistence_data_keys.dart     # MODIFIED: add accessToken, refreshToken keys (userData/isLogin reused)
│   ├── app_errors.dart                    # MODIFIED: add failure mapping for Supabase AuthException
│   └── app_translation_keys.dart          # MODIFIED: add auth screen copy keys
├── navigation/
│   ├── app_routes.dart                    # MODIFIED: add register, forgotPassword, verifyOtp, resetPassword (login already exists)
│   └── route_generator.dart               # MODIFIED: wire the 5 routes into the existing "auth routes" switch section
├── shared/
│   ├── bloc/
│   │   └── session_cubit.dart             # NEW: app-scoped session (is_login, encrypted tokens, user profile) via SharedPrefHandler
│   ├── models/
│   │   └── user.dart                      # MODIFIED: align fields with Supabase user shape + single `name` field (register uses one name field, not first/last)
│   └── widgets/fields/
│       └── otp_code_input.dart            # NEW: 6-box OTP input widget (shared — no equivalent exists)
├── utils/assets/
│   └── app_icons_keys.dart                # MODIFIED: add email, password/lock, eye, eyeOff keys (+ assets/icons/*.svg)
└── features/
    └── auth/
        ├── data/
        │   ├── models/
        │   │   └── auth_user_model.dart           # NEW: Supabase-shaped DTO (fromJson/toJson)
        │   └── repositories/
        │       └── auth_repository_impl.dart       # NEW: wraps Supabase.instance.client.auth calls, maps AuthException → Failure
        ├── domain/
        │   ├── entities/                            # (reuses shared/models/user.dart as the entity; no duplicate entity)
        │   ├── repositories/
        │   │   └── auth_repository.dart              # NEW: interface — login, register, requestOtp, verifyOtp, resetPassword, fetchUserProfile
        │   └── usecases/                              # thin pass-throughs only if a Bloc needs to compose >1 repository call
        └── presentation/
            ├── bloc/
            │   ├── login_bloc.dart / login_event.dart / login_state.dart
            │   ├── register_bloc.dart / register_event.dart / register_state.dart
            │   ├── forgot_password_bloc.dart / forgot_password_event.dart / forgot_password_state.dart
            │   ├── otp_bloc.dart / otp_event.dart / otp_state.dart        # owns the 60s resend countdown (Timer/Stream)
            │   └── reset_password_bloc.dart / reset_password_event.dart / reset_password_state.dart
            ├── pages/
            │   ├── login_page.dart
            │   ├── register_page.dart
            │   ├── forgot_password_page.dart
            │   ├── verify_otp_page.dart
            │   └── reset_password_page.dart
            └── widgets/
                └── password_rules_hint.dart          # feature-specific, non-trivial → own widget class (Principle V)

test/
└── features/auth/presentation/bloc/
    ├── login_bloc_test.dart
    ├── register_bloc_test.dart
    ├── forgot_password_bloc_test.dart
    ├── otp_bloc_test.dart
    └── reset_password_bloc_test.dart
test/shared/bloc/
    └── session_cubit_test.dart
```

**Structure Decision**: Single Flutter project, existing `lib/` root layers unchanged. `lib/features/auth/` gets the full `data/domain/presentation` split (Principle I, business-logic feature). `SessionCubit` is deliberately placed in `lib/shared/bloc/` — not inside the feature — because it is queried app-wide ("session cubit is the one who will integrate with SharedPref... when I want to check if the user is logged in... I will call session cubit"), matching the existing `SettingsCubit`/`UserCubit` precedent. All 5 auth Blocs stay feature-local under `lib/features/auth/presentation/bloc/`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Principle VI (Dio-only network layer) bypassed for Supabase Auth calls | Supabase Auth is provided as a vendored client SDK (`supabase_flutter` → `gotrue-dart`) that owns its own HTTP transport, session refresh timers, and error types internally. The user explicitly and directly instructed integrating with Supabase for login, get-user-by-id, OTP send/verify, and password reset — this is a deliberate, contemporaneous project-owner instruction, which the constitution's Governance section says takes precedence over the general principle for this specific task. | Wrapping Supabase's SDK calls in a hand-built `RequestInstructions`/raw HTTP request would mean reimplementing gotrue's auth protocol (PKCE/OTP flows, token refresh, session parsing) on top of `Dio` — strictly more code, more risk of protocol drift from Supabase's own client, and no benefit since Supabase's SDK is the intended integration point named by the feature description itself. All non-auth network calls remain on `DioClient.instance` untouched. |

## Post-Design Constitution Check

*Re-evaluated after Phase 1 (`data-model.md`, `contracts/`, `quickstart.md`).*

No new violations were introduced by the detailed design:

- **I**: `data-model.md`/contracts confirm the `data/domain/presentation` split stays entirely within `lib/features/auth/`; `SessionCubit` stays in `lib/shared/bloc/` as planned, and no feature-local duplicate of `User` or session state was introduced.
- **II**: `contracts/ui-screens.md` confirms one `Bloc` per screen with named events (`LoginSubmittedEvent`, `SendOtpRequestedEvent`, `ResendOtpRequestedEvent`, `VerifyOtpSubmittedEvent`, `ResetPasswordSubmittedEvent`, `RegisterSubmittedEvent`); `contracts/session-cubit.md` confirms `SessionCubit` stays a simple Cubit with no event orchestration.
- **III**: `contracts/auth-repository.md` confirms Blocs depend only on the `AuthRepository` interface, constructed manually and passed via `BlocProvider` — no locator introduced during design.
- **V**: design confirmed exactly one new shared widget (`OtpCodeInput`) and one new feature-local widget (`PasswordRulesHint`); everything else reuses `TextInputField`/`StatusSnackBars`/the existing `ElevatedButton` theme — no inline `_buildX()` methods planned.
- **VI**: the one documented exception (above) is unchanged and fully scoped to `AuthRepositoryImpl`'s internal use of `Supabase.instance.client.auth` — `contracts/auth-repository.md` keeps this behind a domain interface so the exception cannot leak into Blocs/UI.
- **VII**: `data-model.md` and `contracts/session-cubit.md` confirm all new persistence keys go through `AppPersistenceDataKeys`, all new env values through `AppEnv`, no ad hoc keys/strings.

**Overall**: PASS, same single documented exception as the pre-design check, no new gates introduced.
