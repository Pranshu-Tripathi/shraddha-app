import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../api/services_scope.dart';
import '../config/status_templates.dart';
import '../services/media_storage.dart';
import '../services/status_share.dart';
import '../theme/app_colors.dart';

/// Args passed to the result screen via go_router `extra`.
class StatusResultArgs {
  const StatusResultArgs({required this.templateId, required this.photoPath});

  final String templateId;
  final String photoPath;
}

/// Shows the merged status (template + the user's photo composited into the
/// slot) and posts it to WhatsApp with one tap. The composite is local for now
/// (mocking the backend merge); swap for the backend-returned image later.
class StatusResultScreen extends StatefulWidget {
  const StatusResultScreen({
    super.key,
    required this.templateId,
    required this.photoPath,
  });

  final String templateId;
  final String photoPath;

  @override
  State<StatusResultScreen> createState() => _StatusResultScreenState();
}

class _StatusResultScreenState extends State<StatusResultScreen> {
  static const Color _accent = Color(0xFF1FA855);
  final GlobalKey _boundaryKey = GlobalKey();
  bool _busy = false;

  /// Capture the on-screen composite as PNG bytes (fallback when there's no
  /// backend yet).
  Future<Uint8List> _localComposite() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1080 / boundary.size.width);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<void> _post() async {
    final services = ServicesScope.of(context);
    setState(() => _busy = true);
    try {
      Uint8List merged;
      try {
        // Real upload: the backend merges the photo onto the template (by id)
        // and returns the finished status image.
        merged = await services.status.mergeStatus(
          templateId: widget.templateId,
          photoPath: widget.photoPath,
          width: 1080,
          height: 1920,
        );
      } catch (_) {
        // Backend not reachable yet — fall back to the local composite.
        merged = await _localComposite();
      }
      final dir = await MediaStorage.mediaDir();
      final file = File(
        '${dir.path}/status_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(merged);
      final res = await StatusShare.shareToWhatsApp(file.path);
      if (!mounted) return;
      _snack(switch (res) {
        'shared' => 'व्हाट्सएप खुल रहा है — "My Status" चुनें 🙏',
        'not_installed' => 'व्हाट्सएप इंस्टॉल नहीं है',
        _ => 'शेयर नहीं हो पाया',
      });
    } catch (e) {
      if (mounted) _snack('त्रुटि: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final t = statusTemplateById(widget.templateId);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: const Text('आपका स्टेटस',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: t == null
          ? const Center(child: Text('टेम्पलेट नहीं मिला'))
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: RepaintBoundary(
                          key: _boundaryKey,
                          child: AspectRatio(
                            aspectRatio: 9 / 16,
                            child: LayoutBuilder(
                              builder: (context, c) {
                                final size = Size(c.maxWidth, c.maxHeight);
                                final slot = t.slotIn(size);
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child:
                                          Image.asset(t.asset, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      left: slot.left,
                                      top: slot.top,
                                      width: slot.width,
                                      height: slot.height,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            slot.width * 0.06),
                                        child: Image.file(
                                          File(widget.photoPath),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _busy ? null : _post,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.share),
                      label: Text(
                        _busy ? 'तैयार हो रहा है…' : 'व्हाट्सएप स्टेटस पर लगाएँ',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
