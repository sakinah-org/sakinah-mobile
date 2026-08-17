import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../configurations/app_end_points.dart';
import '../../domain/repositories/user_device_repository.dart';

class UserDeviceRepositoryImpl implements UserDeviceRepository {
  supabase.SupabaseClient get _client => supabase.Supabase.instance.client;

  @override
  Future<void> registerDevice({
    required String userId,
    required String fcmToken,
    required String platform,
  }) async {
    try {
      await _client.from(AppEndPoints.userDevicesTable).upsert(
        {
          'user_id': userId,
          'fcm_token': fcmToken,
          'platform': platform,
        },
        onConflict: 'user_id,fcm_token',
      );
    } catch (e) {
      // Swallowed, same contract as PrayerNotificationSettingsRepositoryImpl
      // .syncToRemote — login must still succeed even if this fails.
      log('UserDeviceRepositoryImpl.registerDevice failed: $e');
    }
  }

  @override
  Future<void> unregisterDevice({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      await _client
          .from(AppEndPoints.userDevicesTable)
          .delete()
          .eq('user_id', userId)
          .eq('fcm_token', fcmToken);
    } catch (e) {
      // Swallowed — logout must still complete even if this fails.
      log('UserDeviceRepositoryImpl.unregisterDevice failed: $e');
    }
  }
}
