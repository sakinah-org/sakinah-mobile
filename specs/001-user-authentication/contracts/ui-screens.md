# Contract: Screens & Routes

Five routes added to `AppRoutes` (`lib/navigation/app_routes.dart`) and wired into the existing, currently-empty "auth routes" section of `generateRoute()` (`lib/navigation/route_generator.dart`). Visuals for every screen must match the imported Sakinah design (`Sakinah Screens.dc.html`, screens "Login / Auth", "Register", "Forgot Password", "Verify Code (OTP)", "Reset Password") in both light/dark themes and RTL/LTR, using only `AppColors`/`AppTypography` tokens (already confirmed to match the design's tokens 1:1).

| Route constant | Path | Page | Pushed from | On success |
|---|---|---|---|---|
| `AppRoutes.login` (existing) | `/login` | `LoginPage` | Settings screen | `Navigator.pop(context)` back to Settings (spec FR-004) |
| `AppRoutes.register` (new) | `/register` | `RegisterPage` | "إنشاء حساب" link on Login | `Navigator.pop(context)` back to Login + `StatusSnackBars.successSnackBar` (spec FR-012) |
| `AppRoutes.forgotPassword` (new) | `/forgot-password` | `ForgotPasswordPage` | "نسيت كلمة المرور؟" link on Login | `Navigator.pushNamed(context, AppRoutes.verifyOtp, arguments: email)` (spec FR-014) |
| `AppRoutes.verifyOtp` (new) | `/verify-otp` | `VerifyOtpPage` | Forgot Password, on send success | `Navigator.pushNamed(context, AppRoutes.resetPassword, arguments: email)` (spec FR-016) |
| `AppRoutes.resetPassword` (new) | `/reset-password` | `ResetPasswordPage` | Verify OTP, on verify success | `Navigator.popUntil` back to Login + `StatusSnackBars.successSnackBar` (spec FR-022) |

Design shows a back-chevron affordance on Register/Forgot-Password/OTP/Reset screens (not Login, which is the flow's entry point) — implemented as a standard `AppBar`/leading back button using the existing `AppIcons.chevronRight` (correct direction for RTL "back").

## Login screen (`LoginPage`)

**Fields** (both via reused `TextInputField`): email (`keyboardType: emailAddress`), password (`keyboardType: visiblePassword`, built-in show/hide toggle).
**Actions**: "نسيت كلمة المرور؟" (forgot password) link → `AppRoutes.forgotPassword`; primary CTA "تسجيل الدخول" (submit) → `LoginBloc` `LoginSubmittedEvent`; "إنشاء حساب" (create account) link → `AppRoutes.register`.
**Design elements explicitly NOT in scope** (present in the design mock but absent from the spec's functional requirements — do not implement): social sign-in buttons, "المتابعة كضيف" (continue as guest). These belong to a different, unspecified feature; building them here would exceed this feature's approved scope.
**Maps to**: spec User Story 1, acceptance scenarios 1–4.

## Register screen (`RegisterPage`)

**Fields**: name, email, password, confirm password (all via `TextInputField`).
**Actions**: back button → pop to Login; primary CTA "إنشاء الحساب" → `RegisterBloc` `RegisterSubmittedEvent`; "تسجيل الدخول" (already have an account) link → pop to Login.
**Maps to**: spec User Story 2, acceptance scenarios 1–4.

## Forgot Password screen (`ForgotPasswordPage`)

**Fields**: email only.
**Actions**: back button → pop to Login; primary CTA "إرسال الرمز" (send code) → `ForgotPasswordBloc` `SendOtpRequestedEvent`; "تذكّرت كلمة المرور؟" (remembered password) link → pop to Login.
**Maps to**: spec User Story 3, acceptance scenario 1.

## Verify OTP screen (`VerifyOtpPage`)

**Fields**: 6-box `OtpCodeInput` (new shared widget — see data-model.md/research.md), masked email confirmation text (design: `ab••••@email.com` — mask all but the first two characters before `@`).
**Actions**: back button → pop; primary CTA "تأكيد" (confirm) → `OtpBloc` `VerifyOtpSubmittedEvent`; "إعادة الإرسال" (resend), enabled only once `OtpBloc`'s countdown reaches zero → `ResendOtpRequestedEvent`, which restarts the 60s countdown (spec FR-017/FR-018); "تغيير البريد الإلكتروني" (change email) link → pop back to Forgot Password.
**Maps to**: spec User Story 3, acceptance scenarios 2–4, and the countdown/backgrounding Edge Cases.

## Reset Password screen (`ResetPasswordPage`)

**Fields**: new password, confirm password (via `TextInputField`), plus the static password-rules hint text under the new-password field (design: "8 أحرف على الأقل..." — matches `Validations.isValidPassword`'s ≥8-char rule; feature-specific `PasswordRulesHint` widget per Principle V).
**Actions**: primary CTA "حفظ كلمة المرور" (save password) → `ResetPasswordBloc` `ResetPasswordSubmittedEvent`. No back button in the design (committed step after verified OTP) — matches spec FR-019 (only reachable post-verification; going back would re-expose an already-consumed recovery step).
**Maps to**: spec User Story 3, acceptance scenarios 5–6.

## Cross-screen contract notes

- Every screen's primary CTA button uses the design's `Button` component contract (`variant="primary" size="lg"`) — realized in this codebase as the existing `ElevatedButton` theme from `app_theme.dart` (`elevatedButtonTheme`), not a new button widget.
- Every screen must show a loading state on the primary CTA during the in-flight network call (disabled + spinner or equivalent) and a non-blocking error surface (inline text or snackbar, consistent with `ErrorState(errorMessage)` from the shared `AppStates` hierarchy) on failure — implied by every Bloc's `Loading`/`Error` states but not pinned to one exact widget treatment here (implementation detail for `/speckit-tasks`).
- RTL is the default per the design (`dir="rtl"` throughout); LTR (English locale, `SettingsCubit.toggleLocale()`) must mirror layout correctly — standard Flutter `Directionality`/`TextDirection` handling driven by `MaterialApp.locale`, no auth-specific RTL code needed beyond using standard widgets that already respect `Directionality`.
