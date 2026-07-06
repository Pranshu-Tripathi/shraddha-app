class FaceSwapTemplate {
  const FaceSwapTemplate({
    required this.id,
    required this.name,
    required this.signedGetUrl,
    required this.expiresIn,
  });

  final String id;
  final String name;
  final String signedGetUrl;
  final int expiresIn;

  String get title {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    return base.replaceAll(RegExp(r'[_-]+'), ' ');
  }

  factory FaceSwapTemplate.fromJson(Map<String, dynamic> json) {
    return FaceSwapTemplate(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      signedGetUrl: json['signed_get_url']?.toString() ?? '',
      expiresIn: json['expires_in'] is int
          ? json['expires_in'] as int
          : int.tryParse(json['expires_in']?.toString() ?? '') ?? 0,
    );
  }
}

class FaceSwapTemplateList {
  const FaceSwapTemplateList({required this.items});

  final List<FaceSwapTemplate> items;

  factory FaceSwapTemplateList.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) =>
                    FaceSwapTemplate.fromJson(Map<String, dynamic>.from(item)),
              )
              .where(
                (item) => item.id.isNotEmpty && item.signedGetUrl.isNotEmpty,
              )
              .toList(growable: false)
        : const <FaceSwapTemplate>[];
    return FaceSwapTemplateList(items: items);
  }
}

class FaceSwapUploadUrl {
  const FaceSwapUploadUrl({
    required this.selfieId,
    required this.signedPutUrl,
    required this.contentType,
    required this.expiresIn,
  });

  final String selfieId;
  final String signedPutUrl;
  final String contentType;
  final int expiresIn;

  factory FaceSwapUploadUrl.fromJson(Map<String, dynamic> json) {
    return FaceSwapUploadUrl(
      selfieId: json['selfie_id']?.toString() ?? '',
      signedPutUrl: json['signed_put_url']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? 'image/jpeg',
      expiresIn: json['expires_in'] is int
          ? json['expires_in'] as int
          : int.tryParse(json['expires_in']?.toString() ?? '') ?? 0,
    );
  }
}

class FaceSwapMerge {
  const FaceSwapMerge({
    required this.mergeId,
    required this.signedGetUrl,
    required this.expiresIn,
  });

  final String mergeId;
  final String signedGetUrl;
  final int expiresIn;

  factory FaceSwapMerge.fromJson(Map<String, dynamic> json) {
    return FaceSwapMerge(
      mergeId: json['merge_id']?.toString() ?? '',
      signedGetUrl: json['signed_get_url']?.toString() ?? '',
      expiresIn: json['expires_in'] is int
          ? json['expires_in'] as int
          : int.tryParse(json['expires_in']?.toString() ?? '') ?? 0,
    );
  }
}
