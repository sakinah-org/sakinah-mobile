# Phase 1 Data Model: User Authentication

Entities as identified in [spec.md](./spec.md#key-entities), translated into concrete shapes for this codebase. No new local database — Supabase is the remote system of record; local storage is Hive via `SharedPrefHandler` only.

## User Account (remote — Supabase, not modeled locally)

Owned entirely by Supabase Auth; the app never stores a password. Referenced here only to document what the app relies on existing remotely:

| Field | Notes |
|---|---|
| `id` (uuid) | Supabase auth user id — becomes `User.id` locally |
| `email` | unique, used for login/recovery |
| `password` | never touches app storage in plaintext or otherwise |
| `user_metadata.name` | set at `signUp`; the spec's single "name" field (not first/last) |

## User (local — `lib/shared/models/user.dart`, MODIFIED)

The existing `User` model's `fromJson`/`toJson` (`_id`, `firstname`, `lastname`) were shaped for a different, non-Supabase backend and don't match either Supabase's user object or the spec's single-`name` register field. Updated shape:

```dart
class User {
  String? id;          // was userId — Supabase auth user id
  String? name;         // was firstName/lastName split — spec Register uses one name field
  String? email;

  User({this.id, this.name, this.email});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
  };
}
```

**Validation rules** (enforced by `LoginBloc`/`RegisterBloc` via the existing `Validations` mixin before any network call):
- `email`: `Validations.isValidEmail` (non-empty, regex format)
- `password` / new password: `Validations.isValidPassword` (non-empty, ≥ 8 chars)
- `confirmPassword`: `Validations.isValidConfirmPassword` (non-empty, matches password)
- `name` (register only): `Validations.isValidName` (non-empty, ≥ 3 chars)
- `otp code`: `Validations.isValidCode` (non-empty, length 6 per spec FR-015 — note the mixin's current message text says "6" already; confirm at implementation time that the length check itself, not just the message, enforces 6)

**Removed field**: `token` (was on `User` previously) — access/refresh tokens now live exclusively in `SessionCubit`/Hive as their own encrypted entries, not on the profile model, per the feature description's explicit separation of "tokens" from "user info."

## Authenticated Session (local — owned by `SessionCubit`, persisted via `SharedPrefHandler`)

Not a Dart class of its own — a set of three Hive entries under existing/new `AppPersistenceDataKeys`:

| Hive key | Constant | Shape | Encrypted? |
|---|---|---|---|
| `is_login` | `AppPersistenceDataKeys.isLogin` (existing) | `bool` | n/a |
| `access_token` | `AppPersistenceDataKeys.accessToken` (**new**) | `Map<String,String>` — `{'value': <base64 ciphertext>, 'iv': <base64 iv>}` (see research.md §2) | Yes — `AESEncryptor` |
| `refresh_token` | `AppPersistenceDataKeys.refreshToken` (**new**) | same shape as above | Yes — `AESEncryptor` |
| `user_data` | `AppPersistenceDataKeys.userData` (existing) | `User.toJson()` — plain `Map<String, dynamic>` | No (per spec/description — only tokens are encrypted) |

**State transitions**:
- **Unauthenticated → Authenticated**: `SessionCubit.persistSession(accessToken, refreshToken, user)`, called once by `LoginBloc` after `signInWithPassword` + profile fetch both succeed. Writes all four Hive entries; emits an updated session state so any `context.watch<SessionCubit>()` listener (e.g. Settings) reacts immediately.
- **App cold start**: `SessionCubit.restoreSession()`, called once during app init (before `runApp`, alongside the existing `AESEncryptor`/`AppEnv` init sequence). Reads Hive only — never calls Supabase — decrypts both tokens, reconstructs `User` from the stored map. If `is_login` is absent/false, session stays `Unauthenticated` with no error.
- **Authenticated → Unauthenticated**: out of scope for this feature (see spec Assumptions — logout is a separate feature); `SessionCubit`'s data shape supports it trivially later (`SharedPrefHandler.removeAllOf(keys: [...])` + set `is_login = false`), but no UI entry point is built here.

## Password Recovery Request (transient — owned by `ForgotPasswordBloc` / `OtpBloc`, not persisted)

Not stored in Hive; lives only in Bloc state for the duration of the forgot-password flow (lost on app restart, which is acceptable — spec has no requirement to resume an in-flight recovery across restarts).

| Field | Type | Notes |
|---|---|---|
| `email` | `String` | carried from `ForgotPasswordBloc` → `OtpBloc` → `ResetPasswordBloc` via navigation arguments (`RouteSettings.arguments`, the project's existing pattern — no new state-passing mechanism) |
| `otp` | `String` | 6 digits, entered on the OTP screen, sent to `auth.verifyOTP` |
| `verified` | `bool` | gates navigation to reset-password; also naturally enforced server-side since `updateUser` requires the authenticated recovery session `verifyOTP` produces (research.md §1) |
| `resendAvailableAt` | `DateTime` | timestamp-based cooldown anchor (research.md §4) — not a raw counter, so real elapsed time survives backgrounding |

## Entity Relationship Summary

```
User Account (Supabase, remote)
        │  signInWithPassword / signUp / verifyOTP / updateUser
        ▼
AuthRepository (domain interface)
        │
        ▼
LoginBloc / RegisterBloc / ForgotPasswordBloc / OtpBloc / ResetPasswordBloc
        │  on success, LoginBloc calls:
        ▼
SessionCubit  ──persists──▶  SharedPrefHandler (Hive)
        │                         ├─ is_login (bool)
        │                         ├─ access_token (encrypted map)
        │                         ├─ refresh_token (encrypted map)
        │                         └─ user_data (plain User map)
        ▼
Rest of the app queries SessionCubit.instance.isLoggedIn / .currentUser
```
