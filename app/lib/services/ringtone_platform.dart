import 'package:flutter/services.dart';

/// Thin wrapper over the native ringtone channel (Kotlin `MainActivity`).
/// Setting a ringtone needs the special `WRITE_SETTINGS` grant (a one-time
/// system screen) — the native side opens it and returns 'needs_permission'.
class RingtonePlatform {
  const RingtonePlatform._();

  static const MethodChannel _channel = MethodChannel('shanti/ringtone');

  /// Returns 'set', 'needs_permission', or 'error'.
  static Future<String> setRingtone(
    Uint8List bytes, {
    required String name,
    String? mimeType,
  }) async {
    final res = await _channel.invokeMethod<String>('setRingtone', {
      'bytes': bytes,
      'name': name,
      'mimeType': mimeType,
    });
    return res ?? 'error';
  }
}
