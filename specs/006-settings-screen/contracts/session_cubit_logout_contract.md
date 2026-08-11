# Contract: `SessionCubit.logout()` (shared, existing singleton)

`lib/shared/bloc/session_cubit.dart` — pre-existing global cubit; this feature adds `logout()`. `restoreSession()`/`persistSession()` are unchanged and remain the only other writers of session data.

## Public API

```dart
Future<void> logout();
```

Called only from the Settings screen's Logout confirmation dialog, only reachable when `isLoggedIn == true` (FR-013).

## Behavior

1. Call `supabase.Supabase.instance.client.auth.signOut()`. Swallow/log (do not rethrow) any failure from this call — local session teardown must still complete even if the network sign-out call fails (never leave the user stuck mid-logout).
2. Remove exactly these `SharedPrefHandler` keys, if present: `AppPersistenceDataKeys.isLogin`, `.accessToken`, `.refreshToken`, `.userData`. No other key is touched.
3. Set `_currentUser = null`.
4. `emit(LoadedState(null))`.

## Postconditions (FR-015, FR-017, SC-004)

- `SessionCubit.instance.isLoggedIn == false` and `currentUser == null`.
- Every other `SharedPrefHandler` key (language, dark mode, prayer location/calculation method, prayer notification settings, Quran font settings) is byte-for-byte unchanged.
- Any widget subscribed to `SessionCubit` (the Settings account section, in particular) rebuilds into its guest-state view without navigation or app restart.

## Explicitly not this method's job

- Re-fetching or clearing feature-specific remote state (e.g., prayer notification schedules tied to the account) — none of this feature's requirements ask for that, and doing so would violate FR-017 ("all guest-accessible functionality... continue to work exactly as it does for a first-time guest," which already holds without touching those keys).
