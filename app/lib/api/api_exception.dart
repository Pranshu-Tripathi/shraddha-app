/// A transport-agnostic error surfaced by the API layer.
///
/// Screens render [message] directly and never see Dio types, keeping the UI
/// free of any networking concerns.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
