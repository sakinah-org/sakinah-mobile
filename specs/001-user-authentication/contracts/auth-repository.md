# Contract: `AuthRepository` (domain interface)

`lib/features/auth/domain/repositories/auth_repository.dart`. This is the single seam every screen Bloc depends on — Blocs never call `Supabase.instance.client` directly, only this interface, implemented by `AuthRepositoryImpl` (`lib/features/auth/data/repositories/auth_repository_impl.dart`). All methods return/throw the shared `Failure` hierarchy (`lib/configurations/app_errors.dart`), never a raw `AuthException` or `DioException`, so Blocs have one error-handling shape to deal with — same as the rest of the app's network code.

## `Future<User> login({required String email, required String password})`

- **Preconditions**: `email`/`password` already passed `Validations.isValidEmail`/`isValidPassword` in `LoginBloc` before this is called.
- **Behavior**: calls Supabase `signInWithPassword`, then fetches the full user profile by id (spec: "1. login with Supabase, 2. get user data by its id"). Returns the composed `User` plus, out-of-band, the session's access/refresh tokens (see note below on return shape).
- **Success**: returns `User` (id, name, email). Caller (`LoginBloc`) is responsible for pulling the access/refresh token strings off the Supabase `Session` object returned alongside (repository method may return a small tuple/record `({User user, String accessToken, String refreshToken})` rather than just `User` — implementation detail, not fixed here) and calling `SessionCubit.instance.persistSession(...)`.
- **Failure**: `UnauthorizedFailure` (wrong credentials — spec FR-003, must not reveal which field was wrong), `ConnectionFailure`/`TimeoutFailure` (network), `UnknownFailure` (anything else). Maps from Supabase `AuthException`/`AuthRetryableFetchException`.

## `Future<void> register({required String name, required String email, required String password})`

- **Preconditions**: all four register fields already passed validation (`isValidName`, `isValidEmail`, `isValidPassword`, `isValidConfirmPassword`) in `RegisterBloc`.
- **Behavior**: calls Supabase `signUp` with `name` in `user_metadata`.
- **Success**: void — spec FR-012 only requires popping back to login with a confirmation, no auto-login after register (Assumption: no email-verification gate).
- **Failure**: `BadRequestFailure` (email already registered — spec FR-011), `ConnectionFailure`/`TimeoutFailure`, `UnknownFailure`.

## `Future<void> requestPasswordRecovery({required String email})`

- **Behavior**: calls Supabase `signInWithOtp(email:, shouldCreateUser: false)` to trigger the recovery code email (spec FR-013/FR-014).
- **Success**: void, regardless of whether the email is actually registered — the UI must show the same "code sent" outcome either way per spec's edge case ("must not confirm or deny account existence").
- **Failure**: only genuine transport/service failures (`ConnectionFailure`, `TimeoutFailure`, `UnknownFailure`) surface as errors; "email not found" must NOT surface as a distinct failure type the UI could use to leak account existence.

## `Future<void> verifyOtp({required String email, required String otp})`

- **Preconditions**: `otp` already passed `Validations.isValidCode` (6 digits) in `OtpBloc`.
- **Behavior**: calls Supabase `verifyOTP(email:, token:, type: OtpType.email)`.
- **Success**: void — a verified recovery session now exists client-side, which is what makes the next call (`resetPassword`) valid (spec FR-019, enforced naturally by Supabase, not by extra app-side flags).
- **Failure**: `UnauthorizedFailure` (wrong/expired code — spec FR-016), `ConnectionFailure`/`TimeoutFailure`, `UnknownFailure`.

## `Future<void> resendOtp({required String email})`

- **Behavior**: identical call to `requestPasswordRecovery` (Supabase has one "send OTP" primitive); kept as a separate repository method only so `OtpBloc` has a clearly-named action distinct from the initial send, matching spec FR-018 ("resend" restarts the cooldown).
- **Success/Failure**: same shape as `requestPasswordRecovery`.

## `Future<void> resetPassword({required String newPassword})`

- **Preconditions**: called only while a verified recovery session is active (i.e., only reachable from `ResetPasswordBloc`, which is only reachable after `OtpBloc` succeeds — spec FR-019). `newPassword`/confirmation already validated in `ResetPasswordBloc`.
- **Behavior**: calls Supabase `updateUser(UserAttributes(password: newPassword))`.
- **Success**: void — spec FR-022, caller pops to login with confirmation.
- **Failure**: `UnauthorizedFailure` (no valid recovery session — shouldn't be reachable via the UI but guarded regardless), `ValidationFailure` (Supabase-side password policy rejection, if any), `ConnectionFailure`/`TimeoutFailure`, `UnknownFailure`.

## Out of scope for this contract

- Token refresh beyond initial persistence (spec Assumptions: session termination/refresh triggers are implementation detail for a later pass; `SessionCubit`'s shape supports it but no repository method here forces it).
- Any repository method for logout — not in this feature's scope (see spec Assumptions).
