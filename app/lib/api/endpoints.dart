/// Backend endpoint paths — the app's single source of truth for the
/// `magic` backend's HTTP surface. Mirrors `whatsapp_hook/server.py`.
class Endpoints {
  const Endpoints._();

  static const String health = '/healthz';
  static const String authRegister = '/v1/auth/register';
  static const String audio = '/v1/audio';
  static const String images = '/v1/images';
  static const String faceSwapTemplates = '/v1/face-swap/templates';
  static const String faceSwapUploadUrl = '/v1/face-swap/upload-url';
  static const String faceSwapMerge = '/v1/face-swap/merge';
  static const String send = '/send';
  static const String sendSummary = '/send_summary';
  static const String queue = '/queue';

  static String status(String ticketId) => '/status/$ticketId';
}
