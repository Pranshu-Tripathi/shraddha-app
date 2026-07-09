import 'dart:io';

import 'package:flutter/foundation.dart';

class SecureMediaHttp {
  const SecureMediaHttp._();

  static const int maxImageBytes = 15 * 1024 * 1024;
  static const int maxAudioBytes = 25 * 1024 * 1024;
  static const int maxSelfieUploadBytes = 10 * 1024 * 1024;

  static Future<void> downloadToFile({
    required String url,
    required File destination,
    required int maxBytes,
    required List<String> allowedContentTypePrefixes,
  }) async {
    final uri = Uri.parse(url);
    _validateRemoteUri(uri);
    final client = HttpClient();
    IOSink? sink;
    try {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Media download failed', uri: uri);
      }
      _validateContentLength(response.contentLength, maxBytes, uri);
      _validateContentType(
        response.headers.contentType?.mimeType,
        allowedContentTypePrefixes,
        uri,
      );

      var received = 0;
      sink = destination.openWrite();
      await for (final chunk in response) {
        received += chunk.length;
        if (received > maxBytes) {
          throw HttpException('Media response exceeded size limit', uri: uri);
        }
        sink.add(chunk);
      }
      await sink.flush();
    } finally {
      await sink?.close();
      client.close(force: true);
    }
  }

  static Future<Uint8List> downloadBytes({
    required String url,
    required int maxBytes,
    required List<String> allowedContentTypePrefixes,
  }) async {
    final dir = await Directory.systemTemp.createTemp('shanti-media-');
    final file = File('${dir.path}/download');
    try {
      await downloadToFile(
        url: url,
        destination: file,
        maxBytes: maxBytes,
        allowedContentTypePrefixes: allowedContentTypePrefixes,
      );
      return file.readAsBytes();
    } finally {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }

  static Future<void> putFile({
    required String signedPutUrl,
    required String filePath,
    required String contentType,
    required int maxBytes,
  }) async {
    final uri = Uri.parse(signedPutUrl);
    _validateRemoteUri(uri);
    final file = File(filePath);
    final length = await file.length();
    if (length > maxBytes) {
      throw HttpException('Upload exceeds size limit', uri: uri);
    }

    final client = HttpClient();
    try {
      final request = await client.putUrl(uri);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      request.headers.set(HttpHeaders.contentLengthHeader, length);
      await request.addStream(file.openRead());
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Media upload failed', uri: uri);
      }
      await response.drain<void>();
    } finally {
      client.close(force: true);
    }
  }

  static void _validateRemoteUri(Uri uri) {
    if (uri.host.isEmpty) {
      throw FormatException(
        'Remote media URL must include a host',
        uri.toString(),
      );
    }
    if (kReleaseMode && uri.scheme != 'https') {
      throw FormatException('Remote media URL must use HTTPS', uri.toString());
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw FormatException(
        'Unsupported remote media URL scheme',
        uri.toString(),
      );
    }
  }

  static void _validateContentLength(int contentLength, int maxBytes, Uri uri) {
    if (contentLength > maxBytes) {
      throw HttpException('Media response exceeds size limit', uri: uri);
    }
  }

  static void _validateContentType(
    String? mimeType,
    List<String> allowedPrefixes,
    Uri uri,
  ) {
    if (mimeType == null || allowedPrefixes.isEmpty) return;
    final normalized = mimeType.toLowerCase();
    final allowed = allowedPrefixes.any(normalized.startsWith);
    if (!allowed) {
      throw HttpException('Unexpected media content type', uri: uri);
    }
  }
}
