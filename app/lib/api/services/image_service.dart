import '../../models/blob_image.dart';
import '../api_client.dart';
import '../endpoints.dart';

class ImageService {
  const ImageService(this._client);

  final ApiClient _client;

  Future<BlobImageListing> listImages({String? category}) async {
    final path = category == null || category.isEmpty
        ? Endpoints.images
        : '${Endpoints.images}?category=${Uri.encodeQueryComponent(category)}';
    final json = await _client.getJson(path);
    return BlobImageListing.fromJson(json);
  }
}
