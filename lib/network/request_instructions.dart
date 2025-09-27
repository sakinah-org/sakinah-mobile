import 'package:dio/dio.dart';

class RequestInstructions {
  final String url;
  final String method;
  final Map<String, dynamic>? queryParameters;
  final Map<String, dynamic>? body;
  Options? options;
  final CancelToken? cancelToken;
  final ProgressCallback? onReceiveProgress;

  RequestInstructions({
    required this.url,
    required this.method,
    this.queryParameters,
    this.body,
    this.options,
    this.cancelToken,
    this.onReceiveProgress,
  }) {
    options?.method ??= method;
  }
}
