import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// App-scoped storage for downloaded media (wallpapers, ringtones, audio).
/// Lives under the app's external files dir, which Android **auto-deletes on
/// uninstall** — satisfying "remove our media on uninstall" (Android has no
/// on-uninstall code hook). See docs/BACKEND_API.md → §7.
class MediaStorage {
  const MediaStorage._();

  /// Returns (creating if needed) the app-scoped media directory.
  static Future<Directory> mediaDir() async {
    final base = await getExternalStorageDirectory();
    final dir = Directory('${base!.path}/media');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Deletes all app-provided media (e.g. a manual "clear cache").
  static Future<void> clearAll() async {
    final dir = await mediaDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
