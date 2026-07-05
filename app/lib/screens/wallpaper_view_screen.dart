import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../services/media_storage.dart';
import '../services/wallpaper_platform.dart';

class WallpaperViewArgs {
  const WallpaperViewArgs({required this.imageUrl, this.title});

  final String imageUrl;
  final String? title;
}

/// Full-screen wallpaper preview with one-tap set (home + lock).
class WallpaperViewScreen extends StatefulWidget {
  const WallpaperViewScreen({super.key, this.args});

  final WallpaperViewArgs? args;

  @override
  State<WallpaperViewScreen> createState() => _WallpaperViewScreenState();
}

class _WallpaperViewScreenState extends State<WallpaperViewScreen> {
  static const String _asset = 'assets/images/wallpaper_placeholder.jpg';
  static const Color _accent = Color(0xFF5B57A6);
  bool _busy = false;

  String? get _imageUrl => widget.args?.imageUrl;

  Future<void> _set(String target) async {
    setState(() => _busy = true);
    try {
      final data = await _wallpaperBytes();
      final ok = await WallpaperPlatform.setWallpaper(data, target: target);
      if (!mounted) return;
      _snack(ok ? 'वॉलपेपर सेट हो गया 🙏' : 'सेट नहीं हो पाया');
    } catch (e) {
      if (mounted) _snack('त्रुटि: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _wallpaperBytes() async {
    final imageUrl = _imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      final data = await rootBundle.load(_asset);
      return data.buffer.asUint8List();
    }

    final file = await _downloadToMediaStorage(imageUrl);
    return file.readAsBytes();
  }

  Future<File> _downloadToMediaStorage(String imageUrl) async {
    final uri = Uri.parse(imageUrl);
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode >= 400) {
        throw HttpException('Image download failed', uri: uri);
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      final dir = await MediaStorage.mediaDir();
      final file = File(
        '${dir.path}/wallpaper-${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } finally {
      client.close(force: true);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_imageUrl == null || _imageUrl!.isEmpty)
            Image.asset(_asset, fit: BoxFit.cover)
          else
            Image.network(
              _imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset(_asset, fit: BoxFit.cover),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _busy ? null : () => _set('both'),
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.wallpaper),
                        label: Text(
                          _busy
                              ? 'सेट हो रहा है…'
                              : 'होम + लॉक स्क्रीन सेट करें',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _busy ? null : () => _set('home'),
                          child: const Text(
                            'सिर्फ होम',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const Text(
                          '•',
                          style: TextStyle(color: Colors.white54),
                        ),
                        TextButton(
                          onPressed: _busy ? null : () => _set('lock'),
                          child: const Text(
                            'सिर्फ लॉक',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
