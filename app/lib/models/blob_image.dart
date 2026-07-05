class BlobImage {
  const BlobImage({
    required this.id,
    required this.category,
    required this.name,
    required this.signedGetUrl,
    required this.signedUrlExpiresIn,
    this.contentType,
    this.size = 0,
    this.updated,
  });

  final String id;
  final String category;
  final String name;
  final String? contentType;
  final int size;
  final DateTime? updated;
  final String signedGetUrl;
  final int signedUrlExpiresIn;

  factory BlobImage.fromJson(Map<String, dynamic> json) {
    return BlobImage(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      contentType: json['content_type']?.toString(),
      size: json['size'] is int
          ? json['size'] as int
          : int.tryParse(json['size']?.toString() ?? '') ?? 0,
      updated: DateTime.tryParse(json['updated']?.toString() ?? ''),
      signedGetUrl: json['signed_get_url']?.toString() ?? '',
      signedUrlExpiresIn: json['signed_url_expires_in'] is int
          ? json['signed_url_expires_in'] as int
          : int.tryParse(json['signed_url_expires_in']?.toString() ?? '') ?? 0,
    );
  }
}

class BlobImageListing {
  const BlobImageListing({required this.items, this.categories = const []});

  final List<BlobImage> items;
  final List<String> categories;

  factory BlobImageListing.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawCategories = json['categories'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => BlobImage.fromJson(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.signedGetUrl.isNotEmpty)
              .toList(growable: false)
        : const <BlobImage>[];
    final categories = rawCategories is List
        ? rawCategories
              .map((category) => category.toString())
              .where((category) => category.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return BlobImageListing(items: items, categories: categories);
  }
}
