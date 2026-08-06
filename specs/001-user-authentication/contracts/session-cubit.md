# Contract: `SessionCubit` (app-scoped, `lib/shared/bloc/session_cubit.dart`)

Provided once at the `MaterialApp` root (`main.dart`). This is the **only** part of the app that reads or writes session data in `SharedPrefHandler`. Any code anywhere in the app that needs to know "is the user logged in" or "who is the current user" calls this — never `SharedPrefHandler` directly for session keys.

## Public surface

| Member | Signature | Called by |
|---|---|---|
| `isLoggedIn` | `bool get isLoggedIn` | anywhere in the app (e.g. Settings deciding whether to show "Login" or the profile) |
| `currentUser` | `User? get currentUser` | anywhere needing the cached profile (name/email display) |
| `restoreSession` | `Future<void> restoreSession()` | once, during app startup (`main.dart`, before `runApp`) — reads Hive only, never calls Supabase |
| `persistSession` | `Future<void> persistSession({required String accessToken, required String refreshToken, required User user})` | `LoginBloc`, once, immediately after a successful `AuthRepository.login()` |

## Behavioral contract

- **`restoreSession()`**: reads `is_login` from Hive. If `false`/absent, cubit state becomes/stays "unauthenticated" with no error, no exception — first-launch and logged-out-relaunch are indistinguishable non-error states. If `true`, reads and decrypts both token entries (`AESEncryptor.decrypt`) and the plain `user_data` entry, reconstructs `User`, and emits an "authenticated" state carrying `currentUser`. A decrypt failure (corrupted/foreign data) MUST be treated as "unauthenticated" (fail safe, do not crash app startup) rather than propagating an exception.
- **`persistSession(...)`**: encrypts `accessToken` and `refreshToken` independently via `AESEncryptor.encrypt` (each call produces its own IV — see data-model.md), writes all three/four Hive keys (`is_login=true`, `access_token`, `refresh_token`, `user_data`), then emits the "authenticated" state. This is the *only* write path into session storage — `RegisterBloc`, `ForgotPasswordBloc`, `OtpBloc`, `ResetPasswordBloc` never call this (none of those flows establish a session; only login does, per spec).
- **State exposure**: `SessionCubit` extends the shared `AppStates` hierarchy per Principle II, e.g. `InitialState` (before `restoreSession()` completes), `LoadedState(User? currentUser)` for both authenticated (`currentUser != null`) and explicitly-unauthenticated (`currentUser == null`) outcomes — no `ErrorState` for the normal "not logged in" case, only for genuine unexpected failures during restore.

## Consumers (informational — not built by this feature, but this is the contract they rely on)

- The Settings screen (whatever page ends up living at that tab) reads `SessionCubit.instance.isLoggedIn` to decide whether to show a "Login" entry point or account details, and is the page `LoginBloc` navigates back to on success (spec FR-004).
- Any future "requires login" gate anywhere else in the app calls the same `isLoggedIn` getter — no parallel session-check mechanism should ever be introduced.
