import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sakinah/configurations/app_env.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/handlers/location_handler.dart';
import 'package:sakinah/handlers/permission_handler.dart';
import 'package:sakinah/handlers/shared_handler.dart';
import 'package:sakinah/network/network_handler.dart';
import 'package:sakinah/shared/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import 'package:sakinah/shared/prayer_times/domain/entities/calculation_method.dart';
import 'package:sakinah/shared/prayer_times/domain/entities/prayer_location.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._path);
  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}

class MockDio extends Mock implements Dio {}

class MockLocationHandler extends Mock implements LocationHandler {}

class MockPermissionHandler extends Mock implements PermissionHandler {}

Map<String, dynamic> _alAdhanJson() => {
      'data': {
        'timings': {
          'Fajr': '05:21',
          'Sunrise': '06:58',
          'Dhuhr': '12:12',
          'Asr': '15:11',
          'Maghrib': '17:25',
          'Isha': '19:02',
        },
        'date': {
          'gregorian': {'date': '09-08-2026'}
        },
      },
    };

Position _fakePosition() => Position(
      latitude: 30.0444,
      longitude: 31.2357,
      timestamp: DateTime(2026, 8, 9),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockDio dio;
  late MockLocationHandler locationHandler;
  late MockPermissionHandler permissionHandler;
  late PrayerTimesRepositoryImpl repository;

  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('sakinah_prayer_times_test_');
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
    locationHandler = MockLocationHandler();
    permissionHandler = MockPermissionHandler();
    repository = PrayerTimesRepositoryImpl(
      dioClient: DioClient.instance..dio = dio,
      prefs: SharedPrefHandler.instance,
      locationHandler: locationHandler,
      permissionHandler: permissionHandler,
    );
  });

  group('resolveLocation', () {
    test(
        'detects via device geolocation when nothing cached and permission granted',
        () async {
      when(() => permissionHandler.checkLocationPermission())
          .thenAnswer((_) async => true);
      when(() => locationHandler.getCurrentPosition())
          .thenAnswer((_) async => _fakePosition());

      final result = await repository.resolveLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 30.0444);
      expect(result.longitude, 31.2357);
    });

    test('returns null when permission is denied', () async {
      when(() => permissionHandler.checkLocationPermission())
          .thenAnswer((_) async => false);

      final result = await repository.resolveLocation();

      expect(result, isNull);
      verifyNever(() => locationHandler.getCurrentPosition());
    });

    test('reuses the previously stored location without re-detecting',
        () async {
      when(() => permissionHandler.checkLocationPermission())
          .thenAnswer((_) async => true);
      when(() => locationHandler.getCurrentPosition())
          .thenAnswer((_) async => _fakePosition());
      await repository.resolveLocation(); // seeds the cache

      final result = await repository.resolveLocation();

      expect(result, isNotNull);
      verify(() => locationHandler.getCurrentPosition()).called(1);
    });
  });

  group('getPrayerTimes', () {
    const location = Coordinates(latitude: 30.0444, longitude: 31.2357);

    test('fresh success parses the AlAdhan response and caches it', () async {
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
            data: _alAdhanJson(),
          ));

      final times = await repository.getPrayerTimes(
        location: location,
        method: CalculationMethod.ummAlQura,
        date: DateTime(2026, 8, 9),
      );

      expect(times.fajr, DateTime(2026, 8, 9, 5, 21));
      expect(times.dhuhr, DateTime(2026, 8, 9, 12, 12));
      expect(times.asr, DateTime(2026, 8, 9, 15, 11));
      expect(times.maghrib, DateTime(2026, 8, 9, 17, 25));
      expect(times.isha, DateTime(2026, 8, 9, 19, 2));
    });

    test('network failure falls back to the last cached response', () async {
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
            data: _alAdhanJson(),
          ));
      await repository.getPrayerTimes(
        location: location,
        method: CalculationMethod.ummAlQura,
        date: DateTime(2026, 8, 9),
      ); // seeds the cache

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

      final times = await repository.getPrayerTimes(
        location: location,
        method: CalculationMethod
            .isna, // different method -> forces a refetch attempt
        date: DateTime(2026, 8, 10),
      );

      expect(times.fajr, DateTime(2026, 8, 9, 5, 21)); // the cached day's value
    });

    test('network failure with no cache throws the mapped Failure', () async {
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

      expect(
        () => repository.getPrayerTimes(
          location: location,
          method: CalculationMethod.ummAlQura,
          date: DateTime(2026, 8, 9),
        ),
        throwsA(isA<ConnectionFailure>()),
      );
    });

    test('same-day, same-location, same-method call skips the network entirely',
        () async {
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
            data: _alAdhanJson(),
          ));

      await repository.getPrayerTimes(
        location: location,
        method: CalculationMethod.ummAlQura,
        date: DateTime(2026, 8, 9),
      );
      await repository.getPrayerTimes(
        location: location,
        method: CalculationMethod.ummAlQura,
        date: DateTime(2026, 8, 9),
      );

      verify(() => dio.request(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).called(1);
    });
  });
}
