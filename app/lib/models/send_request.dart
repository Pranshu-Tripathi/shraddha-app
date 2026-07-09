/// Request body for `POST /send`. Data only, no logic.
class SendRequest {
  const SendRequest({required this.text, this.groupId});

  final String text;
  final String? groupId;

  Map<String, dynamic> toJson() => {
    'text': text,
    if (groupId != null && groupId!.isNotEmpty) 'group_id': groupId,
  };
}
