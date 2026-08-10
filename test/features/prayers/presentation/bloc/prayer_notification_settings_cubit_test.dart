import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:sakinah/configurations/app_env.dart';
import 'package:sakinah/features/prayers/domain/entities/prayer_reminder_setting.dart';
import 'package:sakinah/features/prayers/domain/repositories/prayer_notification_settings_repository.dart';
import 'package:sakinah/features/prayers/presentation/bloc/prayer_notification_settings_cubit.dart';
import 'package:sakinah/features/prayers/presentation/bloc/prayer_notification_settings_state.dart';
import 'package:sakinah/handlers/notification_handler.dart';
import 'package:sakinah/handlers/permission_handler.dart';
import 'package:sakinah/handlers/shared_handler.dart';
import 'package:sakinah/shared/prayer_times/domain/entities/calculation_method.dart';
import 'package:sakinah/shared/prayer_times/domain/entities/prayer_location.dart';
import 'package:sakinah/shared/prayer_times/domain/entities/prayer_times.dart';
import 'package:sakinah/shared/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:sakinah/shared/prayer_times/presentation/bloc/prayer_times_cubit.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._path);
  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}

class MockRepository extends Mock
    implements PrayerNotificationSettingsRepository {}

class MockPermissionHandler extends Mock implements PermissionHandler {}

class MockNotificationHandler extends Mock implements NotificationHandler {}

class MockPrayerTimesRepository extends Mock implements PrayerTimesRepository {}

List<PrayerReminderSetting> _defaults() {
  final now = DateTime.now();
  return const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']
      .map((code) => PrayerReminderSetting(
          prayerCode: code, isEnabled: true, updatedAt: now))
      .toList();
}

void main() {
  late MockRepository repository;
  late MockPermissionHandler permissionHandler;
  late MockNotificationHandler notificationHandler;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = await Directory.systemTemp
        .createTemp('sakinah_prayer_notification_cubit_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    await AppEnv.init('dev');
    await SharedPrefHandler.init();
    final now = DateTime.now();
    registerFallbackValue(PrayerReminderSetting(
        prayerCode: 'fajr', isEnabled: true, updatedAt: now));
    registerFallbackValue(const <({String prayerCode, bool isEnabled})>[]);
    registerFallbackValue(const <String, DateTime>{});
    registerFallbackValue(const Coordinates(latitude: 30, longitude: 31));
    registerFallbackValue(CalculationMethod.ummAlQura);
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  setUp(() {
    repository = MockRepository();
    permissionHandler = MockPermissionHandler();
    notificationHandler = MockNotificationHandler();

    when(() => permissionHandler.checkNotificationPermissionStatus())
        .thenAnswer((_) async => ph.PermissionStatus.granted);
    when(() => notificationHandler.rescheduleAll(any(), any()))
        .thenAnswer((_) async {});
    when(() => notificationHandler.scheduleReminder(
        prayerCode: any(named: 'prayerCode'),
        prayerTime: any(named: 'prayerTime'))).thenAnswer((_) async {});
    when(() => notificationHandler.cancelReminder(
        prayerCode: any(named: 'prayerCode'))).thenAnswer((_) async {});
    when(() => repository.saveLocalSetting(any())).thenAnswer((_) async {});
  });

  PrayerNotificationSettingsCubit buildCubit() =>
      PrayerNotificationSettingsCubit(
        repository: repository,
        permissionHandler: permissionHandler,
        notificationHandler: notificationHandler,
      );

  blocTest<PrayerNotificationSettingsCubit, PrayerNotificationSettingsState>(
    'loadSettings emits [Loading, Loaded] with all-five-enabled defaults for a guest',
    setUp: () {
      when(() => repository.getLocalSettings())
          .thenAnswer((_) async => _defaults());
    },
    build: buildCubit,
    act: (cubit) => cubit.loadSettings(),
    expect: () => [
      isA<PrayerNotificationSettingsLoadingState>(),
      isA<PrayerNotificationSettingsLoadedState>()
          .having((s) => s.settings.length, 'settings.length', 5)
          .having((s) => s.settings.every((e) => e.isEnabled), 'all enabled',
              isTrue)
          .having((s) => s.permissionStatus, 'permissionStatus',
              NotificationPermissionStatus.granted),
    ],
    verify: (_) {
      // Guest (no signed-in session in this test process) never syncs.
      verifyNever(
          () => repository.reconcileWithRemote(userId: any(named: 'userId')));
    },
  );

  group('toggle', () {
    blocTest<PrayerNotificationSettingsCubit, PrayerNotificationSettingsState>(
      'optimistically updates state, persists locally, and cancels the reminder when turned off',
      seed: () => PrayerNotificationSettingsLoadedState(_defaults(),
          permissionStatus: NotificationPermissionStatus.granted),
      build: buildCubit,
      act: (cubit) => cubit.toggle('asr', false),
      expect: () => [
        isA<PrayerNotificationSettingsLoadedState>().having(
            (s) =>
                s.settings.firstWhere((e) => e.prayerCode == 'asr').isEnabled,
            'asr.isEnabled',
            isFalse),
      ],
      verify: (_) {
        verify(() => repository.saveLocalSetting(any())).called(1);
        verify(() => notificationHandler.cancelReminder(prayerCode: 'asr'))
            .called(1);
      },
    );

    blocTest<PrayerNotificationSettingsCubit, PrayerNotificationSettingsState>(
      'never syncs to Supabase for a guest (no signed-in session)',
      seed: () => PrayerNotificationSettingsLoadedState(_defaults(),
          permissionStatus: NotificationPermissionStatus.granted),
      build: buildCubit,
      act: (cubit) => cubit.toggle('asr', false),
      verify: (_) {
        verifyNever(
            () => repository.syncToRemote(any(), userId: any(named: 'userId')));
      },
    );
  });

  group('permission status mapping', () {
    blocTest<PrayerNotificationSettingsCubit, PrayerNotificationSettingsState>(
      'maps permanentlyDenied through to the Loaded state',
      seed: () => PrayerNotificationSettingsLoadedState(_defaults(),
          permissionStatus: NotificationPermissionStatus.granted),
      setUp: () {
        when(() => permissionHandler.checkNotificationPermissionStatus())
            .thenAnswer((_) async => ph.PermissionStatus.permanentlyDenied);
      },
      build: buildCubit,
      act: (cubit) => cubit.requestNotificationPermission(),
      expect: () => [
        isA<PrayerNotificationSettingsLoadedState>().having(
            (s) => s.permissionStatus,
            'permissionStatus',
            NotificationPermissionStatus.permanentlyDenied),
      ],
    );

    blocTest<PrayerNotificationSettingsCubit, PrayerNotificationSettingsState>(
      'maps denied through to the Loaded state',
      seed: () => PrayerNotificationSettingsLoadedState(_defaults(),
          permissionStatus: NotificationPermissionStatus.granted),
      setUp: () {
        when(() => permissionHandler.checkNotificationPermissionStatus())
            .thenAnswer((_) async => ph.PermissionStatus.denied);
      },
      build: buildCubit,
      act: (cubit) => cubit.requestNotificationPermission(),
      expect: () => [
        isA<PrayerNotificationSettingsLoadedState>().having(
            (s) => s.permissionStatus,
            'permissionStatus',
            NotificationPermissionStatus.denied),
      ],
    );
  });

  group('schedules using PrayerTimesCubit.instance', () {
    late MockPrayerTimesRepository prayerTimesRepository;
    late PrayerTimesCubit previousInstance;

    setUp(() {
      previousInstance = PrayerTimesCubit.instance;
      prayerTimesRepository = MockPrayerTimesRepository();
      PrayerTimesCubit.instance = PrayerTimesCubit.test(prayerTimesRepository);
    });

    tearDown(() {
      PrayerTimesCubit.instance = previousInstance;
    });

    blocTest<PrayerNotificationSettingsCubit, PrayerNotificationSettingsState>(
      'schedules a reminder using the currently loaded prayer time when turned on',
      seed: () {
        final now = DateTime.now();
        final settings = _defaults()
            .map((s) => s.prayerCode == 'asr'
                ? s.copyWith(isEnabled: false, updatedAt: now)
                : s)
            .toList();
        return PrayerNotificationSettingsLoadedState(settings,
            permissionStatus: NotificationPermissionStatus.granted);
      },
      setUp: () async {
        when(() => prayerTimesRepository.resolveLocation(forceRedetect: false))
            .thenAnswer(
                (_) async => const Coordinates(latitude: 30, longitude: 31));
        when(() => prayerTimesRepository.getStoredCalculationMethod())
            .thenAnswer((_) async => CalculationMethod.ummAlQura);
        when(() => prayerTimesRepository.getPrayerTimes(
              location: any(named: 'location'),
              method: any(named: 'method'),
              date: any(named: 'date'),
            )).thenAnswer((invocation) async => PrayerTimes(
              date: invocation.namedArguments[#date] as DateTime,
              fajr: DateTime(2026, 8, 9, 5, 21),
              dhuhr: DateTime(2026, 8, 9, 12, 12),
              asr: DateTime(2026, 8, 9, 15, 11),
              maghrib: DateTime(2026, 8, 9, 17, 25),
              isha: DateTime(2026, 8, 9, 19, 2),
            ));
        await PrayerTimesCubit.instance.loadPrayerTimes();
      },
      build: buildCubit,
      act: (cubit) => cubit.toggle('asr', true),
      verify: (_) {
        verify(() => notificationHandler.scheduleReminder(
            prayerCode: 'asr',
            prayerTime: DateTime(2026, 8, 9, 15, 11))).called(1);
      },
    );
  });
}
