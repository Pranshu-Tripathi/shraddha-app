import 'package:flutter/services.dart';

/// Thin wrapper over the native wallpaper channel (Kotlin `MainActivity`).
/// Setting the wallpaper needs no runtime permission prompt on Android.
class WallpaperPlatform {
  const WallpaperPlatform._();

  static const MethodChannel _channel = MethodChannel('shanti/wallpaper');

  /// Sets the wallpaper from raw image [bytes].
  /// [target] is 'home', 'lock', or 'both' (default) — one call sets both.
  static Future<bool> setWallpaper(
    Uint8List bytes, {
    String target = 'both',
  }) async {
    final ok = await _channel.invokeMethod<bool>('setWallpaper', {
      'bytes': bytes,
      'target': target,
    });
    return ok ?? false;
  }
}
