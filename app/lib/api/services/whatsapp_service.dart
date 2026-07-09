import '../../models/queue_depth.dart';
import '../../models/send_request.dart';
import '../../models/send_response.dart';
import '../../models/send_summary_request.dart';
import '../../models/ticket_status.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Maps 1:1 to the WhatsApp hook endpoints in `whatsapp_hook/server.py`.
/// Pure pass-through: build request DTO → call → map response DTO.
class WhatsappService {
  const WhatsappService(this._client);

  final ApiClient _client;

  Future<SendResponse> send(SendRequest request) async {
    final json = await _client.postJson(Endpoints.send, body: request.toJson());
    return SendResponse.fromJson(json);
  }

  Future<SendResponse> sendSummary(SendSummaryRequest request) async {
    final json = await _client.postJson(
      Endpoints.sendSummary,
      body: request.toJson(),
    );
    return SendResponse.fromJson(json);
  }

  Future<TicketStatus> status(String ticketId) async {
    final json = await _client.getJson(Endpoints.status(ticketId));
    return TicketStatus.fromJson(json);
  }

  Future<QueueDepth> queueDepth() async {
    final json = await _client.getJson(Endpoints.queue);
    return QueueDepth.fromJson(json);
  }
}
