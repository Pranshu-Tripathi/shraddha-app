import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'device_context.dart';

/// Thin wrapper around a configured [Dio] instance.
///
/// Centralizes the base URL, timeouts, and JSON headers, and converts
/// low-level [DioException]s into a single [ApiException] type so that
/// services and screens never import Dio directly.
class ApiClient {
  ApiClient({Dio? dio, this.deviceId = ''})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.backendBaseUrl,
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              headers: const {'Content-Type': 'application/json'},
              // Let us inspect 4xx ourselves instead of throwing.
              validateStatus: (code) => code != null && code < 500,
            ),
          ) {
    // Attach device-context headers to every request (campaign + image fit).
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll(DeviceContext.headers(deviceId: deviceId));
          handler.next(options);
        },
      ),
    );
  }

  final String deviceId;
  final Dio _dio;

  String get baseUrl => _dio.options.baseUrl;

  Future<Map<String, dynamic>> getJson(String path) async {
    try {
      final res = await _dio.get<dynamic>(path);
      return _unwrap(res);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _dio.post<dynamic>(path, data: body);
      return _unwrap(res);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// Posts a multipart form (one file + fields) and returns the raw response
  /// bytes — e.g. a backend-merged image.
  Future<Uint8List> postFileForBytes(
    String path, {
    required String filePath,
    required String fileField,
    Map<String, dynamic> fields = const {},
  }) async {
    try {
      final form = FormData.fromMap({
        ...fields,
        fileField: await MultipartFile.fromFile(filePath, filename: 'upload'),
      });
      final res = await _dio.post<List<int>>(
        path,
        data: form,
        options: Options(responseType: ResponseType.bytes),
      );
      if ((res.statusCode ?? 0) >= 400) {
        throw ApiException('Upload failed', statusCode: res.statusCode);
      }
      return Uint8List.fromList(res.data ?? const []);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Map<String, dynamic> _unwrap(Response<dynamic> res) {
    final data = res.data;
    final map = data is Map<String, dynamic>
        ? data
        : <String, dynamic>{'raw': data};
    final status = res.statusCode ?? 0;
    if (status >= 400) {
      throw ApiException(
        map['error']?.toString() ??
            map['detail']?.toString() ??
            'Request failed',
        statusCode: status,
      );
    }
    return map;
  }

  ApiException _toApiException(DioException e) {
    final serverMsg = e.response?.data is Map
        ? ((e.response!.data as Map)['error'] ??
                  (e.response!.data as Map)['detail'])
              ?.toString()
        : null;
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'Backend timed out. Is the server running at ${AppConfig.backendBaseUrl}?',
      DioExceptionType.connectionError =>
        'Cannot reach backend at ${AppConfig.backendBaseUrl}.',
      _ => serverMsg ?? e.message ?? 'Network error',
    };
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}
