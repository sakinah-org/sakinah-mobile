# Phase 0 Research: User Authentication

All items from the Technical Context had a reasonably clear answer from the existing codebase and the feature description itself, so this is a confirmation record of the decisions made and why — not a set of open unknowns.

## 1. Supabase integration surface

**Decision**: Use `supabase_flutter`'s `Supabase.instance.client.auth` directly from a single `AuthRepositoryImpl` (`lib/features/auth/data/repositories/auth_repository_impl.dart`), initialized once in `main.dart` via `Supabase.initialize(url: AppEnv.instance.supabaseUrl, anonKey: AppEnv.instance.supabaseAnonKey)`, called **before** `AppEnv`-dependent singletons that need it, mirroring the existing `AESEncryptor`/`AppEnv` init-ordering fix already applied for this project.

**Rationale**: The feature description explicitly calls for direct Supabase integration in two steps for login ("1. login with Supabase, 2. get user data by its id from Supabase"), and for OTP send/verify/reset via Supabase for forgot-password. `supabase_flutter` is the standard, actively maintained Flutter SDK for this and already matches the project's static-singleton access pattern (`Supabase.instance.client`, same shape as `AppEnv.instance`).

**Auth calls used**:
- Login: `auth.signInWithPassword(email:, password:)` → then a profile fetch (`auth.currentUser` already carries core fields; if richer profile fields are needed, a `select` on a `profiles`/`users` table keyed by `auth.currentUser!.id` — exact table/columns are a data-layer implementation detail, not a spec concern, and default to `auth.currentUser` metadata if no separate profile table exists).
- Register: `auth.signUp(email:, password:, data: {'name': name})` (name stored in Supabase `user_metadata`, since the spec's Register story asks for a single `name` field, not first/last).
- Forgot password (send OTP): `auth.signInWithOtp(email:, shouldCreateUser: false)` — Supabase's OTP email flow doubles as the recovery code channel; `shouldCreateUser: false` prevents silently registering an unregistered email, keeping the "don't confirm/deny account existence" edge case (spec) uniform in UI feedback while not creating spurious accounts.
- Verify OTP: `auth.verifyOTP(email:, token:, type: OtpType.email)`.
- Reset password: `auth.updateUser(UserAttributes(password: newPassword))` — valid once `verifyOTP` has produced an authenticated recovery session client-side; this naturally enforces spec FR-019 ("reset-password screen only reachable after a verified OTP") without extra app-side gating logic.

**Alternatives considered**: Building a custom REST wrapper over Supabase's GoTrue HTTP API through `DioClient` — rejected (see plan.md Complexity Tracking: reimplements SDK-internal protocol handling for no benefit, and contradicts the feature description's explicit "integrate with Supabase" instruction).

## 2. Token storage: encryption + persistence shape

**Decision**: `SessionCubit` stores three Hive entries via the existing `SharedPrefHandler`: `AppPersistenceDataKeys.isLogin` (`bool`), a new `accessToken` key, and a new `refreshToken` key. Each token is stored as a small Hive-native `Map<String, String>` of `{'value': <base64 ciphertext>, 'iv': <base64 iv>}` — **not** a bare string — because `AESEncryptor.encrypt()` generates a fresh random IV per call (`IV.fromLength(16)`) and that IV must be persisted alongside the ciphertext to decrypt later; storing only the ciphertext string would make the token undecryptable on next app launch.

**Rationale**: `AESEncryptor`/`EncryptedValue` already exist and are the project's one security-reviewed encryption path (`lib/handlers/security/`); reusing them as-is (no changes needed beyond what was already fixed) satisfies spec FR-006 without inventing a second encryption scheme. Hive stores `Map<String, dynamic>` natively — no manual JSON string encoding needed, consistent with the feature description's own suggestion ("check if Hive can save object instead so it will save us this effort").

**Alternatives considered**: Concatenating `iv:ciphertext` into one string — works but is a hand-rolled micro-format for no benefit when Hive already stores maps natively; a `flutter_secure_storage` platform-keychain approach — rejected as an unrequested new dependency when the project already has a reviewed, working `AESEncryptor` path the user explicitly pointed at.

## 3. User profile persistence shape

**Decision**: Persist the user profile under the existing `AppPersistenceDataKeys.userData` key as the plain (unencrypted) `Map<String, dynamic>` from `User.toJson()`, saved/read directly through `SharedPrefHandler.save`/`get<Map>`. `User` (`lib/shared/models/user.dart`) is adjusted to match what Supabase actually returns (`id`, `email`, a single `name` rather than `firstName`/`lastName`) — see data-model.md.

**Rationale**: The feature description asks for encryption on the two tokens only, not on profile data ("for the access and refresh token they should be encrypted... for the user info... save it in SharedPref"); Hive's native Map support means no JSON-string round-trip is needed, directly answering the description's own question about whether Hive can save the object form.

**Alternatives considered**: Encrypting the profile too — rejected, out of scope per the description's explicit token-only encryption instruction (also recorded as a spec Assumption boundary was not needed here since the description was explicit, not ambiguous).

## 4. Bloc vs. Cubit split, and OTP countdown ownership

**Decision**: One `Bloc` per screen (`LoginBloc`, `RegisterBloc`, `ForgotPasswordBloc`, `OtpBloc`, `ResetPasswordBloc`), each with named event-handler methods per Principle II. The 60-second, real-elapsed-time resend countdown (spec FR-017/FR-018, Edge Cases) is owned by `OtpBloc` itself via a periodic `Timer`/tick event feeding countdown state, computed from a stored "OTP last-sent-at" timestamp rather than a naive decrementing counter — so backgrounding/foregrounding the app (Edge Cases) reflects real elapsed time instead of resetting.

**Rationale**: Matches the constitution's explicit guidance that multi-step forms/wizards use `Bloc`, and keeps each screen's state machine independently testable per spec's "Independent Test" criteria for each user story.

**Alternatives considered**: A single `AuthBloc` for all five screens — rejected, conflates five independent, differently-shaped state machines and would fail the "independently testable/deployable" requirement from the spec's own User Story structure.

## 5. `SessionCubit` scope and responsibilities

**Decision**: `SessionCubit` (`lib/shared/bloc/session_cubit.dart`) is a global singleton Cubit (`SessionCubit._internal()` / `static SessionCubit instance`, same shape as `SettingsCubit`/`UserCubit`), provided at the `MaterialApp` root in `main.dart`. Its public surface: `bool get isLoggedIn`, `Future<void> restoreSession()` (reads from `SharedPrefHandler` at app start — never calls Supabase), `Future<void> persistSession({accessToken, refreshToken, user})` (called once by `LoginBloc` after a successful login+profile-fetch), `User? get currentUser`, and a token-refresh entry point for future use. It owns all `SharedPrefHandler` reads/writes for session data — `LoginBloc`/`RegisterBloc`/etc. never touch `SharedPrefHandler` directly, only call `SessionCubit.instance.persistSession(...)` after a successful login.

**Rationale**: Directly matches the feature description's explicit instructions: "session cubit is the one who will integrate with SharedPref... login bloc [does not]" and "when I want to check if the user is logged in... I will call session cubit." Placing it in `lib/shared/bloc/` (not inside `features/auth/`) follows Principle I's explicit precedent (`SettingsCubit`, `UserCubit` already live there) since it is consumed app-wide, not just by the auth feature.

**Alternatives considered**: Folding session state into the existing (currently-empty) `UserCubit` — rejected; the description explicitly names a distinct `SessionCubit`, and `UserCubit` today has no defined responsibility to overload.

## 6. Design-system correspondence

**Decision**: Reuse `lib/shared/widgets/fields/text_input_field.dart` unmodified for every text field across all 5 screens (name, email, password, confirm password) — its label-above / bordered-container / prefix-icon / password-visibility-toggle pattern already matches the imported design pixel-for-pixel in structure. Build one new shared widget, `OtpCodeInput` (`lib/shared/widgets/fields/otp_code_input.dart`), for the 6-box OTP entry — no equivalent exists yet. Reuse `StatusSnackBars.successSnackBar` for the two required success confirmations (post-register, post-reset). Add the missing icon assets/keys the design requires but the codebase doesn't yet have (`email`, `password`/lock, `eye`, `eyeOff`) to `AppIcons` + `assets/icons/`, per Principle IV.

**Rationale**: Confirmed by direct inspection of the imported design's token files (`colors.css`, `typography.css`, `spacing.css`) against `lib/utils/style/app_colors.dart` / `app_typography.dart` — they match exactly (same hex values, same 6-level type scale, same spacing/radius scale), because the design system was itself generated from this Flutter theme. No new design tokens are needed.

**Alternatives considered**: Building bespoke field widgets per auth screen — rejected, directly violates Principle V given a matching shared widget already exists.
