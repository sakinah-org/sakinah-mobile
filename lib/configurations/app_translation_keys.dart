abstract class TranslationKeys {
  //todo: Add more translation keys
  static const String settings = 'settings';

  // ============================================================================
  // Auth — Login
  // ============================================================================
  static const String authWelcomeBack = 'auth_welcome_back';
  static const String authLoginSubtitle = 'auth_login_subtitle';
  static const String authEmailLabel = 'auth_email_label';
  static const String authPasswordLabel = 'auth_password_label';
  static const String authForgotPassword = 'auth_forgot_password';
  static const String authLoginCta = 'auth_login_cta';
  static const String authNoAccountPrompt = 'auth_no_account_prompt';
  static const String authCreateAccountLink = 'auth_create_account_link';

  // ============================================================================
  // Auth — Register
  // ============================================================================
  static const String authRegisterTitle = 'auth_register_title';
  static const String authRegisterSubtitle = 'auth_register_subtitle';
  static const String authNameLabel = 'auth_name_label';
  static const String authConfirmPasswordLabel = 'auth_confirm_password_label';
  static const String authRegisterCta = 'auth_register_cta';
  static const String authHaveAccountPrompt = 'auth_have_account_prompt';
  static const String authLoginLink = 'auth_login_link';
  static const String authRegisterSuccessMessage =
      'auth_register_success_message';

  // ============================================================================
  // Auth — Forgot Password
  // ============================================================================
  static const String authForgotPasswordTitle = 'auth_forgot_password_title';
  static const String authForgotPasswordSubtitle =
      'auth_forgot_password_subtitle';
  static const String authSendCodeCta = 'auth_send_code_cta';
  static const String authRememberedPasswordPrompt =
      'auth_remembered_password_prompt';

  // ============================================================================
  // Auth — Verify OTP
  // ============================================================================
  static const String authOtpTitle = 'auth_otp_title';
  static const String authOtpSubtitlePrefix = 'auth_otp_subtitle_prefix';
  static const String authOtpResendPrompt = 'auth_otp_resend_prompt';
  static const String authOtpResendAction = 'auth_otp_resend_action';
  static const String authOtpResendCountdown = 'auth_otp_resend_countdown';
  static const String authOtpVerifyCta = 'auth_otp_verify_cta';
  static const String authOtpWrongEmailPrompt = 'auth_otp_wrong_email_prompt';
  static const String authOtpChangeEmail = 'auth_otp_change_email';

  // ============================================================================
  // Auth — Reset Password
  // ============================================================================
  static const String authResetPasswordTitle = 'auth_reset_password_title';
  static const String authResetPasswordSubtitle =
      'auth_reset_password_subtitle';
  static const String authNewPasswordLabel = 'auth_new_password_label';
  static const String authPasswordRulesHint = 'auth_password_rules_hint';
  static const String authSavePasswordCta = 'auth_save_password_cta';
  static const String authResetPasswordSuccessMessage =
      'auth_reset_password_success_message';

  // ============================================================================
  // Home — greeting header
  // ============================================================================
  static const String homeGreetingMorning = 'home_greeting_morning';
  static const String homeGreetingAfternoon = 'home_greeting_afternoon';
  static const String homeGreetingEvening = 'home_greeting_evening';
  static const String homeGreetingNameSeparator =
      'home_greeting_name_separator';

  // ============================================================================
  // Home — prayer times card
  // ============================================================================
  static const String homeNextPrayerLabel = 'home_next_prayer_label';
  static const String homeUntilAdhanLabel = 'home_until_adhan_label';
  static const String homePrayerFajr = 'home_prayer_fajr';
  static const String homePrayerDhuhr = 'home_prayer_dhuhr';
  static const String homePrayerAsr = 'home_prayer_asr';
  static const String homePrayerMaghrib = 'home_prayer_maghrib';
  static const String homePrayerIsha = 'home_prayer_isha';
  static const String homePrayerLocationRequiredTitle =
      'home_prayer_location_required_title';
  static const String homePrayerLocationRequiredMessage =
      'home_prayer_location_required_message';
  static const String homePrayerUnavailableTitle =
      'home_prayer_unavailable_title';
  static const String homePrayerUnavailableMessage =
      'home_prayer_unavailable_message';
  static const String homeEnableLocationCta = 'home_enable_location_cta';

  // ============================================================================
  // Home — Ayah of Today card
  // ============================================================================
  static const String homeAyahSectionTitle = 'home_ayah_section_title';
  static const String homeAyahShareCta = 'home_ayah_share_cta';
  static const String homeAyahCachedLabel = 'home_ayah_cached_label';
  static const String homeAyahUnavailableMessage =
      'home_ayah_unavailable_message';
  static const String homeRetryCta = 'home_retry_cta';

  // ============================================================================
  // Prayers screen (lib/features/prayers/) — specs/003-prayers-times-screen
  // ============================================================================
  static const String prayersScreenTitle = 'prayers_screen_title';
  static const String prayersLocationCalculationMethodLabel =
      'prayers_location_calculation_method_label';
  static const String prayersReminderOffsetCaption =
      'prayers_reminder_offset_caption';
  static const String prayersAllOffBannerMessage =
      'prayers_all_off_banner_message';
  static const String prayersNotificationDeniedTitle =
      'prayers_notification_denied_title';
  static const String prayersNotificationDeniedMessage =
      'prayers_notification_denied_message';
  static const String prayersNotificationPermanentlyDeniedTitle =
      'prayers_notification_permanently_denied_title';
  static const String prayersNotificationPermanentlyDeniedMessage =
      'prayers_notification_permanently_denied_message';
  static const String prayersEnableNotificationsCta =
      'prayers_enable_notifications_cta';
}
