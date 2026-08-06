---

description: "Task list template for feature implementation"
---

# Tasks: User Authentication (Login, Register, Forgot Password)

**Input**: Design documents from `/specs/001-user-authentication/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included. `plan.md`/`quickstart.md` and constitution Principle VIII ("New or changed business logic... SHOULD ship with a unit test") call for `bloc_test`-based unit tests on all 5 new Blocs plus `SessionCubit`.

**Organization**: Tasks are grouped by user story (spec.md: US1 Login P1, US2 Register P2, US3 Forgot Password P3) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths are included in every task description

## Path Conventions

Single Flutter project (existing `lib/` layering, per plan.md's Project Structure). `lib/features/auth/` gets the full `data/domain/presentation` split (business-logic feature, Constitution Principle I); `SessionCubit` lives in `lib/shared/bloc/` (cross-app state, matching the `SettingsCubit`/`UserCubit` precedent). Tests under `test/`, mirroring `lib/`'s structure.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependencies and environment values every later phase needs.

- [X] T001 Add `supabase_flutter` (runtime) and `bloc_test` (dev, for testing the new Blocs/Cubit per Constitution Principle VIII) to `pubspec.yaml`, then run `flutter pub get`
- [X] T002 [P] Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` entries to `assets/env/.env.dev`, `assets/env/.env.staging`, `assets/env/.env.production` (values from the target Supabase project; see quickstart.md Prerequisites) — left blank; real project keys must be filled in by the project owner (not available in this session)
- [X] T003 [P] Add the auth-screen icon assets (email, password/lock, eye, eye-off — matching the imported design's field icons) to `assets/icons/` and corresponding keys to `lib/utils/assets/app_icons_keys.dart`, per Constitution Principle IV — `password.svg`/`AppIcons.password` already existed and matched the design; added `email_outlined.svg`, `eye.svg`, `eye_hide.svg` + `AppIcons.emailOutlined/eye/eyeHide`

**Checkpoint**: Dependencies installed, env values and icon assets in place.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared infrastructure every user story depends on — session state, the auth repository contract, routing constants. No user story work can begin until this phase is complete.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 [P] Add `supabaseUrl`/`supabaseAnonKey` fields (read via `flutter_dotenv`, same pattern as `securityKey`) to `lib/configurations/app_env.dart`
- [X] T005 [P] Add `accessToken`/`refreshToken` key constants to `lib/configurations/app_persistence_data_keys.dart` (`isLogin`, `userData` already exist and are reused)
- [X] T006 [P] Add `Failure.handleAuthException(AuthException)` mapping (Supabase `AuthException` → `UnauthorizedFailure`/`BadRequestFailure`/`ConnectionFailure`/`UnknownFailure`, per contracts/auth-repository.md) to `lib/configurations/app_errors.dart`
- [X] T007 [P] Update `User` model in `lib/shared/models/user.dart` to the Supabase-aligned shape (`id`, `name`, `email`; drop `firstName`/`lastName`/`token`), per data-model.md
- [X] T008 [P] Add `register`, `forgotPassword`, `verifyOtp`, `resetPassword` route constants to `lib/navigation/app_routes.dart` (`login` already exists)
- [X] T009 Create `AuthRepository` interface in `lib/features/auth/domain/repositories/auth_repository.dart` — `login`, `register`, `requestPasswordRecovery`, `verifyOtp`, `resendOtp`, `resetPassword`, per contracts/auth-repository.md (depends on T007)
- [X] T010 Implement `AuthRepositoryImpl` in `lib/features/auth/data/repositories/auth_repository_impl.dart`, wrapping `Supabase.instance.client.auth` for all six methods and mapping errors via `Failure.handleAuthException` (depends on T006, T009) — uses `resetPasswordForEmail`/`verifyOTP(type: OtpType.recovery)`, the idiomatic Supabase recovery-OTP pair (refined from research.md's initial `signInWithOtp` guess after inspecting the actual gotrue client API)
- [X] T011 Create `SessionCubit` in `lib/shared/bloc/session_cubit.dart` — singleton (`SettingsCubit`/`UserCubit` pattern), `isLoggedIn`, `currentUser`, `restoreSession()` (Hive-only, fail-safe to unauthenticated on decrypt error), `persistSession(...)` (encrypts both tokens via `AESEncryptor`, writes all 4 Hive keys via `SharedPrefHandler`), per contracts/session-cubit.md and data-model.md (depends on T005, T007)
- [X] T012 In `lib/main.dart`: call `Supabase.initialize(url: AppEnv.instance.supabaseUrl, anonKey: AppEnv.instance.supabaseAnonKey)`, provide `SessionCubit.instance` at the `MaterialApp` root, and call `SessionCubit.instance.restoreSession()` before `runApp` (depends on T004, T011) — also added the missing `SharedPrefHandler.init()` call (was never invoked anywhere in the app; `SessionCubit`/Hive cannot work without it)
- [X] T013 [P] Unit tests for `SessionCubit` in `test/shared/bloc/session_cubit_test.dart` — empty box → unauthenticated; valid encrypted entries → authenticated with correct `User`; corrupted entry → fails safe, no throw; `persistSession` writes ciphertext, not plaintext (depends on T011) — written; execution pending a local `flutter_tester` engine artifact download (see final report)

**Checkpoint**: Foundation ready — `AuthRepository`, `SessionCubit`, routes, and env/config are all in place. User story implementation can now begin.

---

## Phase 3: User Story 1 - Returning user signs in (Priority: P1) 🎯 MVP

**Goal**: User enters email + password on the Login screen; on success the session (flag + encrypted tokens + profile) is cached locally and the user is returned to the Settings screen.

**Independent Test**: Push `AppRoutes.login` (e.g. temporarily from the existing Settings tab placeholder in `MainPage`, or via `Navigator.pushNamed`), submit valid credentials for a Supabase test account, confirm the screen pops back and the app reflects a signed-in state; relaunch the app and confirm no re-prompt (quickstart.md §1). No dependency on US2/US3.

### Implementation for User Story 1

- [X] T014 [P] [US1] `LoginEvent` (`LoginSubmittedEvent`) in `lib/features/auth/presentation/bloc/login_event.dart`
- [X] T015 [P] [US1] `LoginState` classes (extending the shared `AppStates` hierarchy) in `lib/features/auth/presentation/bloc/login_state.dart` — reused `AppStates` (`InitialState`/`LoadingState`/`LoadedState(User)`/`ErrorState`) directly; no bespoke subclasses needed (constitution's "unless genuinely warranted" carve-out did not apply here — no new file created)
- [X] T016 [US1] `LoginBloc` in `lib/features/auth/presentation/bloc/login_bloc.dart` — validates via the `Validations` mixin (`isValidEmail`, `isValidPassword`), calls `AuthRepository.login`, and on success calls `SessionCubit.instance.persistSession(...)` (depends on T014, T015, T010, T011)
- [X] T017 [US1] `LoginPage` in `lib/features/auth/presentation/pages/login_page.dart` — email + password `TextInputField`s, "نسيت كلمة المرور؟" link → `Navigator.pushNamed(context, AppRoutes.forgotPassword)`, primary CTA, "إنشاء حساب" link → `Navigator.pushNamed(context, AppRoutes.register)`, matching the design's Login/Auth screen (light + dark, RTL + LTR); on `LoginBloc` success, `Navigator.pop(context)` (depends on T016)
- [X] T018 [US1] Wire `AppRoutes.login` into `lib/navigation/route_generator.dart`'s existing "auth routes" section: `BlocProvider<LoginBloc>` wrapping `LoginPage` (depends on T017)
- [X] T019 [P] [US1] Add login-screen copy keys (welcome heading, field labels, forgot-password link, CTA, create-account prompt) to `lib/configurations/app_translation_keys.dart`, `assets/lang/en.json`, `assets/lang/ar.json`
- [X] T020 [P] [US1] Unit tests for `LoginBloc` in `test/features/auth/presentation/bloc/login_bloc_test.dart` — success (persists session), wrong credentials (`UnauthorizedFailure`, no session written), invalid input (no repository call), network failure, per spec User Story 1 acceptance scenarios (depends on T016) — written, `flutter analyze` clean; execution blocked by the missing `flutter_tester` artifact noted under T013

**Checkpoint**: User Story 1 is fully functional and independently testable — this is the MVP.

---

## Phase 4: User Story 2 - New user creates an account (Priority: P2)

**Goal**: User enters name, email, password, and confirmation on the Register screen; on success the account is created and the user is returned to Login with a success confirmation.

**Independent Test**: From Login's "إنشاء حساب" link (or `Navigator.pushNamed(context, AppRoutes.register)` directly), submit a valid registration, confirm pop-to-login + success snackbar, then immediately log in with the new credentials on the (already-built, US1) Login screen (quickstart.md §2). Depends only on Foundational + the `AppRoutes.login` route existing from US1 for its "already have an account" link target — no dependency on US1's Bloc/page internals.

### Implementation for User Story 2

- [X] T021 [P] [US2] `RegisterEvent` (`RegisterSubmittedEvent`) in `lib/features/auth/presentation/bloc/register_event.dart`
- [X] T022 [P] [US2] `RegisterState` classes in `lib/features/auth/presentation/bloc/register_state.dart` — reused `AppStates` directly (`SuccessState` for the no-payload success case), no new file needed
- [X] T023 [US2] `RegisterBloc` in `lib/features/auth/presentation/bloc/register_bloc.dart` — validates via `Validations` (`isValidName`, `isValidEmail`, `isValidPassword`, `isValidConfirmPassword`), calls `AuthRepository.register` (depends on T021, T022, T010)
- [X] T024 [US2] `RegisterPage` in `lib/features/auth/presentation/pages/register_page.dart` — name/email/password/confirm `TextInputField`s, back button → pop, primary CTA, "تسجيل الدخول" link → pop to Login, matching the design's Register screen (light + dark, RTL + LTR); on success, pop to Login and show `StatusSnackBars.successSnackBar` (depends on T023)
- [X] T025 [US2] Wire `AppRoutes.register` into `lib/navigation/route_generator.dart` (`BlocProvider<RegisterBloc>` wrapping `RegisterPage`) (depends on T024, T018)
- [X] T026 [P] [US2] Add register-screen copy keys to `lib/configurations/app_translation_keys.dart`, `assets/lang/en.json`, `assets/lang/ar.json`
- [X] T027 [P] [US2] Unit tests for `RegisterBloc` in `test/features/auth/presentation/bloc/register_bloc_test.dart` — success, duplicate email (`BadRequestFailure`), confirm-password mismatch (no repository call), invalid fields, per spec User Story 2 acceptance scenarios (depends on T023) — written, `flutter analyze` clean; execution blocked by the missing `flutter_tester` artifact noted under T013

**Checkpoint**: User Stories 1 AND 2 both work independently.

---

## Phase 5: User Story 3 - User recovers a forgotten password (Priority: P3)

**Goal**: User requests a reset by email, receives and verifies a 6-digit OTP (with a real-elapsed-time 60s resend cooldown), then sets a new password — landing back on Login with a success confirmation.

**Independent Test**: From Login's "نسيت كلمة المرور؟" link, submit a registered email → verify OTP screen shows with countdown → wrong code stays on screen with error → countdown reaches zero and resend works, restarting the countdown → backgrounding the app mid-countdown preserves real elapsed time → correct code navigates to Reset Password → mismatched confirmation blocks submit → valid new password pops to Login with success snackbar → login works with the new password, fails with the old one (quickstart.md §3). Depends on Foundational + `AppRoutes.login` (from US1) as the flow's exit point — independent of US1/US2 Bloc internals.

### Implementation for User Story 3

- [X] T028 [P] [US3] 6-box OTP code entry, per contracts/ui-screens.md and data-model.md — **superseded**: initially built as a hand-rolled `OtpCodeInput` shared widget in `lib/shared/widgets/fields/otp_code_input.dart`; later replaced with the `pinput` package (themed to match the design's box style) directly in `VerifyOtpPage`, and the hand-rolled widget was deleted since nothing else referenced it
- [X] T029 [P] [US3] `PasswordRulesHint` widget in `lib/features/auth/presentation/widgets/password_rules_hint.dart` (static "≥8 characters" hint row shown under the new-password field, matching the design)
- [X] T030 [P] [US3] `ForgotPasswordEvent` (`SendOtpRequestedEvent`) in `lib/features/auth/presentation/bloc/forgot_password_event.dart`
- [X] T031 [P] [US3] `ForgotPasswordState` classes in `lib/features/auth/presentation/bloc/forgot_password_state.dart` — reused `AppStates` (`LoadedState(email)` on send-success), no new file needed
- [X] T032 [US3] `ForgotPasswordBloc` in `lib/features/auth/presentation/bloc/forgot_password_bloc.dart` — validates email via `Validations.isValidEmail`, calls `AuthRepository.requestPasswordRecovery` (depends on T030, T031, T010)
- [X] T033 [US3] `ForgotPasswordPage` in `lib/features/auth/presentation/pages/forgot_password_page.dart` — email field, back button, primary CTA "إرسال الرمز", "تذكّرت كلمة المرور؟" link → pop to Login; on success, push `AppRoutes.verifyOtp` with the email as `RouteSettings.arguments` (depends on T032)
- [X] T034 [US3] Wire `AppRoutes.forgotPassword` into `lib/navigation/route_generator.dart`, and update `LoginPage`'s "نسيت كلمة المرور؟" link to navigate here (depends on T033, T018)
- [X] T035 [P] [US3] `OtpEvent` (`VerifyOtpSubmittedEvent`, `ResendOtpRequestedEvent`, an internal countdown-tick event) in `lib/features/auth/presentation/bloc/otp_event.dart`
- [X] T036 [P] [US3] `OtpState` classes, including remaining-seconds countdown value, in `lib/features/auth/presentation/bloc/otp_state.dart` — the one screen genuinely warranting a bespoke state class (continuously-updating countdown + submit status can't fit the shared Initial/Loading/Loaded/Error taxonomy)
- [X] T037 [US3] `OtpBloc` in `lib/features/auth/presentation/bloc/otp_bloc.dart` — validates code via `Validations.isValidCode`, calls `AuthRepository.verifyOtp`/`resendOtp`; owns a real-elapsed-time 60s resend cooldown computed from a stored "last-sent-at" timestamp (not a naive decrementing counter), so backgrounding/foregrounding reflects true elapsed time per research.md §4 (depends on T035, T036, T010) — clock injectable (`DateTime Function()`, defaults to `DateTime.now`) so T047 can simulate elapsed time deterministically
- [X] T038 [US3] `VerifyOtpPage` in `lib/features/auth/presentation/pages/verify_otp_page.dart` — reads the email from `RouteSettings.arguments`, renders `OtpCodeInput`, masked-email confirmation text, countdown/resend row, "تأكيد" CTA, "تغيير البريد الإلكتروني" link → pop; on success, push `AppRoutes.resetPassword` with the email as arguments (depends on T037, T028)
- [X] T039 [US3] Wire `AppRoutes.verifyOtp` into `lib/navigation/route_generator.dart` (depends on T038, T034)
- [X] T040 [P] [US3] `ResetPasswordEvent` (`ResetPasswordSubmittedEvent`) in `lib/features/auth/presentation/bloc/reset_password_event.dart`
- [X] T041 [P] [US3] `ResetPasswordState` classes in `lib/features/auth/presentation/bloc/reset_password_state.dart` — reused `AppStates` directly, no new file needed
- [X] T042 [US3] `ResetPasswordBloc` in `lib/features/auth/presentation/bloc/reset_password_bloc.dart` — validates via `Validations.isValidPassword`/`isValidConfirmPassword`, calls `AuthRepository.resetPassword` (depends on T040, T041, T010)
- [X] T043 [US3] `ResetPasswordPage` in `lib/features/auth/presentation/pages/reset_password_page.dart` — new-password + confirm `TextInputField`s, `PasswordRulesHint`, primary CTA "حفظ كلمة المرور", no back button (matches design — this step is only reachable post-verification); on success, pop back to Login and show `StatusSnackBars.successSnackBar` (depends on T042, T029)
- [X] T044 [US3] Wire `AppRoutes.resetPassword` into `lib/navigation/route_generator.dart` (depends on T043, T039) — also fixed a latent bug found here: `_createRoute()` never forwarded `RouteSettings` to `PageRouteBuilder`, so `Navigator.pushNamed(..., arguments:)` silently lost its arguments for every route, not just auth ones; fixed since VerifyOtpPage/ResetPasswordPage directly depend on it
- [X] T045 [P] [US3] Add forgot-password/OTP/reset-password screen copy keys to `lib/configurations/app_translation_keys.dart`, `assets/lang/en.json`, `assets/lang/ar.json`
- [X] T046 [P] [US3] Unit tests for `ForgotPasswordBloc` in `test/features/auth/presentation/bloc/forgot_password_bloc_test.dart` — success (including the "don't confirm/deny account existence" behavior for unregistered emails), invalid email, network failure (depends on T032) — written, `flutter analyze` clean; execution blocked by the missing `flutter_tester` artifact noted under T013
- [X] T047 [P] [US3] Unit tests for `OtpBloc` in `test/features/auth/presentation/bloc/otp_bloc_test.dart` — correct code verifies, incorrect/expired code errors and stays put, resend blocked until cooldown elapses then restarts a fresh 60s, countdown reflects real elapsed time across a simulated backgrounding gap (depends on T037) — written using the injected fake clock, `flutter analyze` clean; execution blocked by the missing `flutter_tester` artifact noted under T013
- [X] T048 [P] [US3] Unit tests for `ResetPasswordBloc` in `test/features/auth/presentation/bloc/reset_password_bloc_test.dart` — success, mismatched confirmation (no repository call), weak password, network failure (depends on T042) — written, `flutter analyze` clean; execution blocked by the missing `flutter_tester` artifact noted under T013

**Checkpoint**: All three user stories are independently functional. Full feature complete.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verification that spans all three stories.

- [X] T049 [P] Run `dart format .` and `flutter analyze` clean across every file added/modified in this feature, per Constitution Principle VIII — done; full-project `flutter analyze` shows 99 pre-existing issues, all in files this feature never touched (confirmed via grep), zero issues in any auth-feature file
- [ ] T050 Execute the full quickstart.md manual walkthrough (all three scenarios) end-to-end against a real Supabase test project — **not runnable in this environment**: no Supabase project/credentials were provided (`SUPABASE_URL`/`SUPABASE_ANON_KEY` are blank in the `.env.*` files, see T002), and no device/simulator session was available; left for the project owner to run once real credentials are supplied
- [ ] T051 [P] Visually compare all 5 screens (Login, Register, Forgot Password, Verify OTP, Reset Password) against the imported Sakinah design reference in both light/dark themes and RTL/LTR locales — **not runnable in this environment**: `flutter_tester`/app launch is blocked by the missing engine artifact (see T013); left for the project owner to eyeball once the SDK issue is resolved

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup (needs the `supabase_flutter` dependency and env values from T001/T002). BLOCKS all user stories.
- **User Stories (Phase 3-5)**: All depend on Foundational completion. US1, US2, US3 can then proceed in parallel *except* for one shared-file constraint: each story's route-wiring task (T018, T025, T034/T039/T044) edits the same `lib/navigation/route_generator.dart`, so those specific tasks must be serialized in story-priority order (US1 → US2 → US3) even if the rest of each story is worked in parallel.
- **Polish (Phase 6)**: Depends on all three user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: No dependency on US2/US3. This is the MVP.
- **User Story 2 (P2)**: Independently testable; its Register page's "already have an account" link targets `AppRoutes.login`, which exists from Foundational (T008) regardless of whether US1's `LoginPage` (T017) is finished — only the route-wiring task ordering (above) requires US1's T018 to land first in `route_generator.dart`.
- **User Story 3 (P3)**: Same shape as US2 — independently testable, its exit point targets the `AppRoutes.login` route, with the same route-wiring ordering constraint.

### Within Each User Story

- Event/State files before the Bloc that uses them.
- Bloc before the Page that consumes it.
- Page before the route-wiring task.
- Story complete before its "Checkpoint" is considered met.

### Parallel Opportunities

- Setup: T002, T003 in parallel (T001 first, since both later tasks may want dependencies resolved, though not file-conflicting — safe to run all three together).
- Foundational: T004-T008 all touch different files — fully parallel; T009 depends on T007; T010 depends on T006 + T009; T011 depends on T005 + T007; T012 depends on T004 + T011; T013 depends on T011.
- Once Foundational is done, US1/US2/US3 can be staffed in parallel (different developers), subject only to the `route_generator.dart` serialization noted above.
- Within US3, the three sub-flows (Forgot Password / OTP / Reset Password) have their event+state+widget tasks parallelizable, but Blocs/Pages/route-wiring follow the natural Forgot→OTP→Reset sequence since each page passes the email forward via navigation arguments.
- All Bloc unit-test tasks (T013, T020, T027, T046, T047, T048) are parallelizable with each other and with unrelated implementation tasks, once their respective Bloc exists.

---

## Parallel Example: User Story 1

```bash
# Launch event + state files for User Story 1 together:
Task: "LoginEvent in lib/features/auth/presentation/bloc/login_event.dart"
Task: "LoginState in lib/features/auth/presentation/bloc/login_state.dart"

# After LoginBloc (T016) exists, page work and tests can proceed together:
Task: "LoginPage in lib/features/auth/presentation/pages/login_page.dart"
Task: "Unit tests for LoginBloc in test/features/auth/presentation/bloc/login_bloc_test.dart"
```

## Parallel Example: User Story 3

```bash
# Launch all new widgets + all three sub-flows' event/state files together:
Task: "OtpCodeInput in lib/shared/widgets/fields/otp_code_input.dart"
Task: "PasswordRulesHint in lib/features/auth/presentation/widgets/password_rules_hint.dart"
Task: "ForgotPasswordEvent in lib/features/auth/presentation/bloc/forgot_password_event.dart"
Task: "ForgotPasswordState in lib/features/auth/presentation/bloc/forgot_password_state.dart"
Task: "OtpEvent in lib/features/auth/presentation/bloc/otp_event.dart"
Task: "OtpState in lib/features/auth/presentation/bloc/otp_state.dart"
Task: "ResetPasswordEvent in lib/features/auth/presentation/bloc/reset_password_event.dart"
Task: "ResetPasswordState in lib/features/auth/presentation/bloc/reset_password_state.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T013) — CRITICAL, blocks all stories
3. Complete Phase 3: User Story 1 (T014-T020)
4. **STOP and VALIDATE**: Run quickstart.md §1 independently
5. Login is now shippable as the MVP — Settings can gate on `SessionCubit.instance.isLoggedIn`

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. Add User Story 1 (Login) → validate independently → MVP
3. Add User Story 2 (Register) → validate independently
4. Add User Story 3 (Forgot Password/OTP/Reset) → validate independently
5. Phase 6 Polish once all three are in

### Parallel Team Strategy

With multiple developers, after Foundational (Phase 2) is done:
- Developer A: User Story 1 (Login)
- Developer B: User Story 2 (Register)
- Developer C: User Story 3 (Forgot Password/OTP/Reset — the largest phase)

Coordinate only on the shared `lib/navigation/route_generator.dart` edits (serialize T018 → T025 → T034/T039/T044).

---

## Notes

- [P] tasks = different files, no dependencies.
- [Story] label maps task to specific user story for traceability.
- `AuthRepository`/`AuthRepositoryImpl` (T009-T010) intentionally covers all six auth operations at once in Foundational, rather than being split per story — it is one cohesive contract (contracts/auth-repository.md) that every story depends on, matching the "base models/entities/services that all stories depend on" foundational pattern.
- Constitution Principle VI's Dio-only exception applies solely inside `AuthRepositoryImpl` (T010) — no other task touches `Supabase.instance.client` directly.
- Commit after each task or logical group; stop at any Checkpoint to validate a story independently before continuing.
- Avoid: vague tasks, same-file conflicts within a phase, cross-story dependencies beyond the noted `route_generator.dart` ordering.
