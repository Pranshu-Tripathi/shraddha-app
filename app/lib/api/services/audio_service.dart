import '../../models/blob_audio.dart';
import '../api_client.dart';
import '../endpoints.dart';

class AudioService {
  const AudioService(this._client);

  final ApiClient _client;

  Future<BlobAudioListing> listAudio({String? category}) async {
    final path = category == null || category.isEmpty
        ? Endpoints.audio
        : '${Endpoints.audio}?category=${Uri.encodeQueryComponent(category)}';
    final json = await _client.getJson(path);
    return BlobAudioListing.fromJson(json);
  }
}
