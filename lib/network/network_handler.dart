import 'dart:developer';
import 'package:sakinah/configurations/app_env.dart';
import 'package:sakinah/network/request_instructions.dart';
import 'package:dio/dio.dart';

import 'dio_interceptor.dart';

class DioClient {
  Dio dio = Dio();
  static DioClient instance = DioClient._internal();

  DioClient._internal() {
    dio.options.baseUrl = AppEnv.instance.baseUrl;
    dio.interceptors.add(
      DioLoggingInterceptor.getInterceptor(),
    );
    dio.options.headers = {
      "Accept": "application/json",
    };
  }

  Future<Response> request(RequestInstructions instructions,
      {Function(Object error)? onError}) async {
    try {
      return await dio.request(
        instructions.url,
        queryParameters: instructions.queryParameters,
        data: instructions.body,
        options: instructions.options,
        cancelToken: instructions.cancelToken,
        onReceiveProgress: instructions.onReceiveProgress,
      );
    } catch (e) {
      onError?.call(e);
      rethrow;
    }
  }

  // Future<Response> get(
  //   String url, {
  //   Map<String, dynamic>? queryParameters,
  //   Options? options,
  //   CancelToken? cancelToken,
  //   ProgressCallback? onReceiveProgress,
  //   Object? data,
  // }) async {
  //   try {
  //     return await dio.get(
  //       url,
  //       queryParameters: queryParameters,
  //       options: options,
  //       cancelToken: cancelToken,
  //       onReceiveProgress: onReceiveProgress,
  //       data: data,
  //     );
  //   } catch (e) {
  //     rethrow;
  //   }
  // }

  // Future<Response> post(
  //   String url, {
  //   Map<String, dynamic>? queryParameters,
  //   Object? body,
  //   Options? options,
  //   CancelToken? cancelToken,
  //   ProgressCallback? onReceiveProgress,
  // }) async {
  //   try {
  //     return await dio.post(
  //       url,
  //       queryParameters: queryParameters,
  //       data: body,
  //       options: options,
  //       cancelToken: cancelToken,
  //       onReceiveProgress: onReceiveProgress,
  //     );
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
}
