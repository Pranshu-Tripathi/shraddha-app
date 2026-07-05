/// App-wide configuration — the single place that knows *where* the backend is.
///
/// The backend is a **FastAPI** service (see docs/BACKEND_API.md). Override the
/// URL at run time, e.g. for a physical device on your LAN:
///   flutter run --dart-define=BACKEND_BASE_URL=http://192.168.1.20:8000
class AppConfig {
  const AppConfig._();

  /// Base URL of the FastAPI backend.
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://shraddha-backend-173542503828.asia-south1.run.app',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
