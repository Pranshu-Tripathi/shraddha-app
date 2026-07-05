import 'dart:typed_data';

import '../api_client.dart';

/// Uploads the user's photo + the chosen template id; the backend merges the
/// photo onto that template and returns the finished status image bytes.
/// See docs/BACKEND_API.md → §Status.
class StatusService {
  const StatusService(this._client);

  final ApiClient _client;

  Future<Uint8List> mergeStatus({
    required String templateId,
    required String photoPath,
    required int width,
    required int height,
  }) {
    return _client.postFileForBytes(
      '/v1/status/merge',
      filePath: photoPath,
      fileField: 'photo',
      fields: {'template_id': templateId, 'w': width, 'h': height},
    );
  }
}
