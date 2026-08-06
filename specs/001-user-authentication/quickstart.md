# Quickstart: Validating User Authentication

This is a validation guide for proving the feature works end-to-end against the acceptance scenarios in [spec.md](./spec.md) — not an implementation walkthrough. See [data-model.md](./data-model.md) and [contracts/](./contracts/) for the shapes/interfaces this exercises.

## Prerequisites

1. A Supabase project with:
   - Email/password auth enabled.
   - Email OTP (magic-link/OTP) enabled for the recovery flow, with `shouldCreateUser: false` behavior available (default).
   - At least one test account already registered (for login/forgot-password scenarios) and email delivery reachable in your test environment (or Supabase's dashboard "Auth → Users" + logs to read OTPs during manual testing, if email isn't wired to a real inbox yet).
2. `SUPABASE_URL` / `SUPABASE_ANON_KEY` set in `assets/env/.env.dev` (and `.env.staging` / `.env.production` for those environments) — see `AppEnv` (research.md §1, plan.md Technical Context). These files are gitignored; do not commit real keys.
3. App running against the `dev` environment (`main.dart`'s `env` string), pointed at the Supabase project above.

## Scenario walkthroughs

### 1. Returning user signs in (spec User Story 1)

1. From the Settings screen, navigate to Login (`AppRoutes.login`).
2. Enter a registered test account's email + correct password → submit.
3. **Expect**: navigation pops back to Settings; app is now in an authenticated state.
4. Force-close and relaunch the app.
5. **Expect**: no login prompt reappears — `SessionCubit.restoreSession()` recognizes the cached session (spec FR-005, SC-006).
6. Verify token encryption: inspect the Hive box file on disk (or via a debug print of the raw stored value before decryption) and confirm the `access_token`/`refresh_token` entries are ciphertext, not the plaintext JWT (spec FR-006, SC-004).
7. Repeat step 2 with a wrong password → **expect** an error message, no navigation, no session written.

### 2. New user creates an account (spec User Story 2)

1. From Login, tap "إنشاء حساب" → `RegisterPage`.
2. Submit with an email that's already registered → **expect** a clear duplicate-account error, no navigation (spec FR-011).
3. Submit with a mismatched confirm-password → **expect** inline validation error, no submission attempt (spec FR-010).
4. Submit valid name/email/password/confirmation → **expect** navigation back to Login plus a success snackbar (spec FR-012, SC-002).
5. Immediately log in with the newly created credentials on the Login screen → **expect** success (confirms Assumption: no email-verification gate blocks first login).

### 3. User recovers a forgotten password (spec User Story 3)

1. From Login, tap "نسيت كلمة المرور؟" → `ForgotPasswordPage`.
2. Submit a registered email → **expect** navigation to `VerifyOtpPage` with the masked email shown, and a code arrives (check Supabase Auth logs or the test inbox) (spec FR-013/FR-014).
3. On the OTP screen, confirm the resend link is disabled with a visible countdown starting at 0:60 (spec FR-017).
4. Enter an incorrect 6-digit code → **expect** an inline error, still on the OTP screen (spec FR-016).
5. Wait for the countdown to reach 0:00 → **expect** resend becomes tappable; tap it → **expect** a new code is sent and the countdown restarts at a fresh 0:60 (spec FR-018).
6. Background the app for ~20 seconds mid-countdown, then foreground it → **expect** the remaining time reflects real elapsed time, not a reset (spec Edge Cases).
7. Enter the correct code → **expect** navigation to `ResetPasswordPage` (spec FR-016).
8. Submit a new password with a non-matching confirmation → **expect** inline validation error (spec FR-020).
9. Submit a valid new password + matching confirmation → **expect** navigation back to Login plus a success snackbar (spec FR-022, SC-003).
10. Log in with the new password → **expect** success; log in with the old password → **expect** failure.

## Automated coverage (complements, doesn't replace, the manual walkthrough above)

Per Principle VIII, new business logic ships with unit tests:

- `test/features/auth/presentation/bloc/{login,register,forgot_password,otp,reset_password}_bloc_test.dart` — `bloc_test` + `mocktail`-faked `AuthRepository`, covering each acceptance scenario's success/failure transitions without any live network call.
- `test/shared/bloc/session_cubit_test.dart` — covers `restoreSession()` against a faked `SharedPrefHandler`/`AESEncryptor` (empty box → unauthenticated; valid encrypted entries → authenticated with correct `User`; corrupted entry → fails safe to unauthenticated, does not throw) and `persistSession()` (writes all four Hive keys, tokens are ciphertext not plaintext).

Run with the project's existing test command (`flutter test`) and `flutter analyze` clean, per Principle VIII.
