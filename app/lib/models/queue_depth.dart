/// DTO for `GET /queue` → `{"pending": 0}`. Data only, no logic.
class QueueDepth {
  const QueueDepth({required this.pending});

  final int pending;

  factory QueueDepth.fromJson(Map<String, dynamic> json) =>
      QueueDepth(pending: (json['pending'] as num?)?.toInt() ?? 0);
}
