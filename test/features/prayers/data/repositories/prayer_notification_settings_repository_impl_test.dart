import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sakinah/configurations/app_env.dart';
import 'package:sakinah/features/prayers/data/repositories/prayer_notification_settings_repository_impl.dart';
import 'package:sakinah/features/prayers/domain/entities/prayer_reminder_setting.dart';
import 'package:sakinah/handlers/shared_handler.dart';

/// Covers this repository's local-first surface (defaults, persistence) with
/// a real Hive box, mirroring
/// test/shared/prayer_times/prayer_times_repository_impl_test.dart's setup.
/// The Supabase-backed paths (syncToRemote/reconcileWithRemote) are not unit
/// tested here — supabase_flutter's fluent query builder has no practical
/// fake/mock seam without a live or local Supabase instance — and are
/// instead exercised manually per quickstart.md Scenario 2.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._path);
  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PrayerNotificationSettingsRepositoryImpl repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp
        .createTemp('sakinah_prayer_notification_settings_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    await AppEnv.init('dev');
    await SharedPrefHandler.init();
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await SharedPrefHandler.instance!.clear();
    repository = PrayerNotificationSettingsRepositoryImpl(
      prefs: SharedPrefHandler.instance,
    );
  });

  group('getLocalSettings', () {
    test('defaults all five prayers to enabled when nothing is stored',
        () async {
      final settings = await repository.getLocalSettings();

      expect(settings, hasLength(5));
      expect(settings.map((s) => s.prayerCode),
          ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']);
      expect(settings.every((s) => s.isEnabled), isTrue);
    });
  });

  group('saveLocalSetting', () {
    test('persists only the changed prayer, leaving the other four untouched',
        () async {
      final updatedAt = DateTime(2026, 8, 10, 14, 5);
      await repository.saveLocalSetting(PrayerReminderSetting(
        prayerCode: 'asr',
        isEnabled: false,
        updatedAt: updatedAt,
      ));

      final settings = await repository.getLocalSettings();
      final asr = settings.firstWhere((s) => s.prayerCode == 'asr');
      final fajr = settings.firstWhere((s) => s.prayerCode == 'fajr');

      expect(asr.isEnabled, isFalse);
      expect(asr.updatedAt, updatedAt);
      expect(fajr.isEnabled, isTrue); // untouched, still default
    });

    test('survives a fresh repository instance (Hive persistence)', () async {
      await repository.saveLocalSetting(PrayerReminderSetting(
        prayerCode: 'isha',
        isEnabled: false,
        updatedAt: DateTime(2026, 8, 10),
      ));

      final reloaded = PrayerNotificationSettingsRepositoryImpl(
        prefs: SharedPrefHandler.instance,
      );
      final settings = await reloaded.getLocalSettings();

      expect(settings.firstWhere((s) => s.prayerCode == 'isha').isEnabled,
          isFalse);
    });
  });
}
