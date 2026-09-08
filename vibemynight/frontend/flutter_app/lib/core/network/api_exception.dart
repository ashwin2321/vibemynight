/// Thrown by [ApiClient] whenever the backend returns success:false, or the
/// network/transport itself fails. Carries enough for the UI to show a
/// friendly message per the spec's error-handling requirements.
class ApiException implements Exception {
  final String message;
  final List<String>? errors;
  final int? statusCode;

  const ApiException(this.message, {this.errors, this.statusCode});

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isNetworkError => statusCode == null;

  @override
  String toString() => message;
}
