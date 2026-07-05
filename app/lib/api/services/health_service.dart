import '../../models/health_status.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Calls the backend's liveness endpoint. Nothing beyond call + map.
class HealthService {
  const HealthService(this._client);

  final ApiClient _client;

  Future<HealthStatus> check() async {
    final json = await _client.getJson(Endpoints.health);
    return HealthStatus.fromJson(json);
  }
}
