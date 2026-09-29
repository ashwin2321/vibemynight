import 'dart:async';
import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Thin wrapper around Dio that:
/// - points at [ApiConstants.baseUrl]
/// - attaches `Authorization: Bearer <token>` automatically once an admin
///   has logged in (harmless no-op for public/customer calls)
/// - unwraps the backend's `{ success, data, message, errors }` envelope so
///   every service method just gets the `data` payload back
/// - converts failures (success:false, HTTP errors, network errors) into a
///   single [ApiException] type the UI layer can handle uniformly
/// - implements centralized bounded exponential backoff retries for idempotent
///   GET requests to seamlessly absorb server cold starts and transient network drops
class ApiClient {
  ApiClient._internal({Dio? customDio}) {
    _dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 45),
            receiveTimeout: const Duration(seconds: 45),
            sendTimeout: const Duration(seconds: 45),
            contentType: 'application/json',
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            await TokenStorage.instance.clearToken();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  /// Visible-for-testing constructor allowing mock Dio injection in unit tests.
  factory ApiClient.withDio(Dio dio) => ApiClient._internal(customDio: dio);

  late final Dio _dio;

  /// Cache of in-flight GET requests to prevent duplicate retry storms for identical calls.
  final Map<String, Future<dynamic>> _inFlightGets = {};

  /// Bounded retry delays for transient GET failures: 1s -> 2.5s -> 5s (max 3 retries).
  static const List<Duration> _retryDelays = [
    Duration(milliseconds: 1000),
    Duration(milliseconds: 2500),
    Duration(milliseconds: 5000),
  ];

  /// Idempotent GET request with centralized, bounded exponential backoff retry.
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    final cacheKey = '$path?${query?.toString() ?? ''}';
    if (_inFlightGets.containsKey(cacheKey)) {
      return _inFlightGets[cacheKey]!;
    }

    final future = _executeGetWithRetry(path, query);
    _inFlightGets[cacheKey] = future;
    return future.whenComplete(() {
      _inFlightGets.remove(cacheKey);
    });
  }

  Future<dynamic> _executeGetWithRetry(String path, Map<String, dynamic>? query) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await _dio.get(path, queryParameters: query);
        return _unwrapResponse(response);
      } on DioException catch (e) {
        if (_isTransientNetworkError(e) && attempt < _retryDelays.length) {
          final delay = _retryDelays[attempt];
          attempt++;
          await Future.delayed(delay);
          continue;
        }
        _handleDioException(e);
      }
    }
  }

  /// Evaluates whether a network error is transient (e.g. Render server cold-start / sleeping container).
  bool _isTransientNetworkError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }

    final status = e.response?.statusCode;
    if (status != null && (status == 502 || status == 503 || status == 504)) {
      return true;
    }

    final errStr = e.error?.toString().toLowerCase() ?? '';
    if (errStr.contains('socketexception') ||
        errStr.contains('connection refused') ||
        errStr.contains('connection reset') ||
        errStr.contains('network is unreachable')) {
      return true;
    }

    return false;
  }

  /// Non-idempotent operations: strictly NO automatic retries to prevent duplicate mutations.
  Future<dynamic> post(String path, {Object? body}) => _unwrap(_dio.post(path, data: body));

  Future<dynamic> put(String path, {Object? body}) => _unwrap(_dio.put(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) => _unwrap(_dio.patch(path, data: body));

  Future<dynamic> delete(String path) => _unwrap(_dio.delete(path));

  /// Multipart image upload for admin forms (POST /admin/uploads).
  Future<dynamic> uploadFile(
    String path, {
    required List<int> fileBytes,
    required String filename,
    String? folderValue,
  }) {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: filename),
      if (folderValue != null) 'folder': folderValue,
    });
    return _unwrap(_dio.post(path, data: formData));
  }

  /// Raw byte stream download (for Excel templates, PDFs, etc.)
  Future<List<int>> getRawBytes(String path) async {
    final response = await _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }

  Future<dynamic> _unwrap(Future<Response> request) async {
    try {
      final response = await request;
      return _unwrapResponse(response);
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  dynamic _unwrapResponse(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final success = body['success'] as bool? ?? true;
      if (!success) {
        throw ApiException(
          (body['message'] as String?) ?? 'Something went wrong',
          errors: (body['errors'] as List?)?.cast<String>(),
          statusCode: response.statusCode,
        );
      }
      return body['data'];
    }
    // Some responses (rare) may not use the envelope - return as-is.
    return body;
  }

  Never _handleDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] as String?;
      final errors = (data['errors'] as List?)?.cast<String>();
      String finalMsg = (msg != null && msg.isNotEmpty && msg != 'Something went wrong')
          ? msg
          : (errors != null && errors.isNotEmpty && errors.first.isNotEmpty
              ? errors.first
              : (msg ?? 'Something went wrong. Please try again.'));

      throw ApiException(
        finalMsg,
        errors: errors,
        statusCode: e.response?.statusCode,
      );
    }

    String fallbackMessage = 'Something went wrong. Please try again.';
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
      fallbackMessage = 'Connecting to VibeMyNight... Please check your internet connection.';
    } else if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
      fallbackMessage = 'Request timed out while downloading source data. Please try again.';
    } else if (e.response?.statusCode == 502 || e.response?.statusCode == 503 || e.response?.statusCode == 504) {
      fallbackMessage = 'Server is currently waking up. Please try again in a few seconds.';
    }

    throw ApiException(
      fallbackMessage,
      statusCode: e.response?.statusCode,
    );
  }
}
