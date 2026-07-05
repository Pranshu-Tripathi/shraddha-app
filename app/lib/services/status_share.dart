import 'package:flutter/services.dart';

/// Native bridge to post the generated status image to WhatsApp
/// (`ACTION_SEND` + FileProvider, targeting com.whatsapp).
class StatusShare {
  const StatusShare._();

  static const MethodChannel _channel = MethodChannel('shanti/status');

  /// Returns 'shared' (opened WhatsApp), 'not_installed', or 'error'.
  static Future<String> shareToWhatsApp(String path) async {
    final res = await _channel.invokeMethod<String>(
      'shareToWhatsApp',
      {'path': path},
    );
    return res ?? 'error';
  }

  static Future<bool> isWhatsAppInstalled() async {
    final res = await _channel.invokeMethod<bool>('isWhatsAppInstalled');
    return res ?? false;
  }
}
