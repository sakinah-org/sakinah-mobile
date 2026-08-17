/// Single seam for registering this device's FCM push token against the
/// signed-in user (`public.user_devices`, read by the `send-prayer-reminders`
/// Edge Function). See specs/003-prayers-times-screen/research.md R3.
abstract class UserDeviceRepository {
  /// Upserts on (user_id, fcm_token): if [userId] has no row for this exact
  /// token yet, a new row is created for them; if it already exists, it's
  /// refreshed in place. Fire-and-forget — swallows all failures so login
  /// never fails because of a push-registration problem.
  Future<void> registerDevice({
    required String userId,
    required String fcmToken,
    required String platform,
  });

  /// Deletes this device's (user_id, fcm_token) row so a signed-out device
  /// stops receiving pushes meant for [userId]. Fire-and-forget — swallows
  /// all failures so logout always completes.
  Future<void> unregisterDevice({
    required String userId,
    required String fcmToken,
  });
}
