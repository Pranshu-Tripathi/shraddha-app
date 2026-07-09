/// DTO for `GET /status/<ticket_id>` →
/// `{"ticket_id": ..., "status": ..., "error": ...}`. Data only, no logic.
class TicketStatus {
  const TicketStatus({
    required this.ticketId,
    required this.status,
    this.error,
  });

  final String ticketId;
  final String status;
  final String? error;

  factory TicketStatus.fromJson(Map<String, dynamic> json) => TicketStatus(
    ticketId: json['ticket_id']?.toString() ?? '',
    status: json['status']?.toString() ?? 'unknown',
    error: json['error']?.toString(),
  );
}
