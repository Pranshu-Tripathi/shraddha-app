/// DTO for `POST /send` and `POST /send_summary` →
/// `{"ticket_id": ..., "position": ..., "status": ...}`. Data only, no logic.
class SendResponse {
  const SendResponse({
    required this.ticketId,
    required this.status,
    this.position,
  });

  final String ticketId;
  final String status;
  final int? position;

  factory SendResponse.fromJson(Map<String, dynamic> json) => SendResponse(
    ticketId: json['ticket_id']?.toString() ?? '',
    status: json['status']?.toString() ?? 'unknown',
    position: (json['position'] as num?)?.toInt(),
  );
}
