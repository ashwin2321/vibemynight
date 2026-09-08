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
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
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
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _unwrap(_dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) => _unwrap(_dio.post(path, data: body));

  Future<dynamic> put(String path, {Object? body}) => _unwrap(_dio.put(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) => _unwrap(_dio.patch(path, data: body));

  Future<dynamic> delete(String path) => _unwrap(_dio.delete(path));

  /// Multipart image upload for admin forms (POST /admin/uploads).
  /// [fileBytes] rather than a file path so this works identically on
  /// Flutter Web (no filesystem access) and mobile/desktop.
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

  Future<dynamic> _unwrap(Future<Response> request) async {
    try {
      final response = await request;
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
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        throw ApiException(
          (data['message'] as String?) ?? 'Something went wrong',
          errors: (data['errors'] as List?)?.cast<String>(),
          statusCode: e.response?.statusCode,
        );
      }
      throw ApiException(
        e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError
            ? 'Could not reach the server. Check your connection and try again.'
            : 'Something went wrong. Please try again.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
