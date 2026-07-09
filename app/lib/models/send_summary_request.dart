/// Request body for `POST /send_summary`. Data only, no logic.
class SendSummaryRequest {
  const SendSummaryRequest({
    required this.title,
    required this.items,
    this.groupId,
    this.includeTimestamp = true,
  });

  final String title;
  final List<String> items;
  final String? groupId;
  final bool includeTimestamp;

  Map<String, dynamic> toJson() => {
    'title': title,
    'items': items,
    'include_timestamp': includeTimestamp,
    if (groupId != null && groupId!.isNotEmpty) 'group_id': groupId,
  };
}
