import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sakinah/configurations/app_env.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/configurations/app_persistence_data_keys.dart';
import 'package:sakinah/features/home/data/models/ayah_of_today_model.dart';
import 'package:sakinah/features/home/data/repositories/ayah_repository_impl.dart';
import 'package:sakinah/handlers/shared_handler.dart';
import 'package:sakinah/network/network_handler.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._path);
  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}

class MockDio extends Mock implements Dio {}

class _FixedRandom implements Random {
  @override
  int nextInt(int max) => 100; // deterministic global ayah number

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.5;
}

Map<String, dynamic> _alQuranCloudJson() => {
      'data': [
        {
          'text': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
          'surah': {'number': 13, 'englishName': "Ar-Ra'd"},
          'numberInSurah': 28,
        },
        {
          'text': 'Verily, in the remembrance of Allah do hearts find rest.',
          'surah': {'number': 13, 'englishName': "Ar-Ra'd"},
          'numberInSurah': 28,
        },
      ],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockDio dio;
  late AyahRepositoryImpl repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sakinah_ayah_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    await AppEnv.init('dev');
    await SharedPrefHandler.init();
    registerFallbackValue(Options());
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await SharedPrefHandler.instance!.clear();
    dio = MockDio();
    repository = AyahRepositoryImpl(
      dioClient: DioClient.instance..dio = dio,
      prefs: SharedPrefHandler.instance,
      random: _FixedRandom(),
    );
  });

  void stubSuccess() {
    when(() => dio.request(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: _alQuranCloudJson(),
        ));
  }

  void stubFailure() {
    when(() => dio.request(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.connectionError,
    ));
  }

  test('fresh fetch parses the response and caches it', () async {
    stubSuccess();

    final ayah = await repository.getAyahOfToday();

    expect(ayah.arabicText, 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ');
    expect(ayah.surahName, "Ar-Ra'd");
    expect(ayah.ayahNumberInSurah, 28);
    expect(ayah.isFromToday(DateTime.now()), isTrue);
  });

  test('same-day cache hit skips the network call entirely', () async {
    stubSuccess();
    await repository.getAyahOfToday(); // seeds the cache

    await repository.getAyahOfToday();

    verify(() => dio.request(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).called(1);
  });

  test('fetch failure with a stale cache returns it, not-from-today', () async {
    stubSuccess();
    await repository.getAyahOfToday(); // seeds the cache with "today"

    // Force staleness by rewriting the cache with yesterday's date.
    final raw = SharedPrefHandler.instance!
        .get<Map>(key: AppPersistenceDataKeys.ayahOfTodayCache);
    final cached = CachedAyah.fromJson(raw);
    final staleCache = CachedAyah(
      ayah: AyahOfTodayModel.fromAlQuranCloudJson(
        _alQuranCloudJson(),
        cached.ayah.globalAyahNumber,
        DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
    await SharedPrefHandler.instance!.save(
        AppPersistenceDataKeys.ayahOfTodayCache,
        value: staleCache.toJson());

    stubFailure();

    final ayah = await repository.getAyahOfToday();

    expect(ayah.isFromToday(DateTime.now()), isFalse);
  });

  test('fetch failure with no cache at all throws the mapped Failure',
      () async {
    stubFailure();

    expect(
      () => repository.getAyahOfToday(),
      throwsA(isA<ConnectionFailure>()),
    );
  });
}
