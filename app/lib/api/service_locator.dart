import 'api_client.dart';
import 'services/audio_service.dart';
import 'services/health_service.dart';
import 'services/image_service.dart';
import 'services/status_service.dart';
import 'services/whatsapp_service.dart';

/// Minimal dependency wiring: one [ApiClient], shared by all services.
/// Constructed once at startup. No state or logic — pure assembly.
class Services {
  Services({String deviceId = ''}) : _client = ApiClient(deviceId: deviceId) {
    health = HealthService(_client);
    whatsapp = WhatsappService(_client);
    status = StatusService(_client);
  }

  final ApiClient _client;

  late final AudioService audio = AudioService(_client);
  late final HealthService health;
  late final ImageService images = ImageService(_client);
  late final WhatsappService whatsapp;
  late final StatusService status;

  /// Where the backend lives — handy for showing it in the UI.
  String get backendBaseUrl => _client.baseUrl;
}
