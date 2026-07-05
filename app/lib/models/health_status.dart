/// DTO for `GET /health` → `{"status": "ok"}`. Data only, no logic.
class HealthStatus {
  const HealthStatus({required this.status});

  final String status;

  factory HealthStatus.fromJson(Map<String, dynamic> json) =>
      HealthStatus(status: json['status']?.toString() ?? 'unknown');
}
