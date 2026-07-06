import 'dart:io';

import '../../models/face_swap.dart';
import '../api_client.dart';
import '../api_exception.dart';
import '../endpoints.dart';

/// Calls the backend face-swap flow used by WhatsApp Status.
class StatusService {
  const StatusService(this._client);

  final ApiClient _client;

  Future<FaceSwapTemplateList> templates() async {
    final json = await _client.getJson(Endpoints.faceSwapTemplates);
    return FaceSwapTemplateList.fromJson(json);
  }

  Future<FaceSwapUploadUrl> createUploadUrl({
    String contentType = 'image/jpeg',
  }) async {
    final json = await _client.postJson(
      Endpoints.faceSwapUploadUrl,
      body: {'content_type': contentType},
    );
    return FaceSwapUploadUrl.fromJson(json);
  }

  Future<void> uploadSelfie({
    required String signedPutUrl,
    required String photoPath,
    required String contentType,
  }) async {
    final uri = Uri.parse(signedPutUrl);
    final bytes = await File(photoPath).readAsBytes();
    final client = HttpClient();
    try {
      final request = await client.putUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      request.headers.set(HttpHeaders.contentLengthHeader, bytes.length);
      request.add(bytes);
      final response = await request.close();
      if (response.statusCode >= 400) {
        throw ApiException(
          'Selfie upload failed',
          statusCode: response.statusCode,
        );
      }
      await response.drain<void>();
    } finally {
      client.close(force: true);
    }
  }

  Future<FaceSwapMerge> merge({
    required String templateId,
    required String selfieId,
  }) async {
    final json = await _client.postJson(
      Endpoints.faceSwapMerge,
      body: {'template_id': templateId, 'selfie_id': selfieId},
    );
    return FaceSwapMerge.fromJson(json);
  }
}
