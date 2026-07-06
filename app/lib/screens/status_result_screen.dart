import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/services_scope.dart';
import '../models/face_swap.dart';
import '../services/media_storage.dart';
import '../services/status_share.dart';
import '../theme/app_colors.dart';

/// Args passed to the result screen via go_router `extra`.
class StatusResultArgs {
  const StatusResultArgs({required this.template, required this.photoPath});

  final FaceSwapTemplate template;
  final String photoPath;
}

/// Confirms the selfie, runs the face-swap backend flow, and shows the merged
/// result returned by `/v1/face-swap/merge`.
class StatusResultScreen extends StatefulWidget {
  const StatusResultScreen({
    super.key,
    required this.template,
    required this.photoPath,
  });

  final FaceSwapTemplate template;
  final String photoPath;

  @override
  State<StatusResultScreen> createState() => _StatusResultScreenState();
}

class _StatusResultScreenState extends State<StatusResultScreen> {
  static const Color _accent = Color(0xFF1FA855);

  bool _busy = false;
  String? _mergedUrl;

  Future<void> _createStatus() async {
    final service = ServicesScope.of(context).status;
    setState(() => _busy = true);
    try {
      final upload = await service.createUploadUrl(contentType: 'image/jpeg');
      await service.uploadSelfie(
        signedPutUrl: upload.signedPutUrl,
        photoPath: widget.photoPath,
        contentType: upload.contentType,
      );
      final merge = await service.merge(
        templateId: widget.template.id,
        selfieId: upload.selfieId,
      );
      if (!mounted) return;
      setState(() => _mergedUrl = merge.signedGetUrl);
      _snack('स्टेटस तैयार हो गया 🙏');
    } catch (e) {
      if (mounted) _snack('त्रुटि: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final mergedUrl = _mergedUrl;
    if (mergedUrl == null || mergedUrl.isEmpty) return;

    setState(() => _busy = true);
    try {
      final file = await _downloadMergedImage(mergedUrl);
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

  Future<File> _downloadMergedImage(String imageUrl) async {
    final uri = Uri.parse(imageUrl);
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode >= 400) {
        throw HttpException('Status download failed', uri: uri);
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      final dir = await MediaStorage.mediaDir();
      final file = File(
        '${dir.path}/status_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
    final mergedUrl = _mergedUrl;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: const Text(
          'आपका स्टेटस',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: mergedUrl == null
                  ? _ConfirmationPreview(
                      template: widget.template,
                      photoPath: widget.photoPath,
                    )
                  : _MergedPreview(imageUrl: mergedUrl),
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
                onPressed: _busy
                    ? null
                    : mergedUrl == null
                    ? _createStatus
                    : _share,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        mergedUrl == null ? Icons.auto_fix_high : Icons.share,
                      ),
                label: Text(
                  _busy
                      ? 'तैयार हो रहा है…'
                      : mergedUrl == null
                      ? 'स्टेटस बनाएँ'
                      : 'व्हाट्सएप स्टेटस पर लगाएँ',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationPreview extends StatelessWidget {
  const _ConfirmationPreview({required this.template, required this.photoPath});

  final FaceSwapTemplate template;
  final String photoPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _PreviewPanel(
                  label: 'Template',
                  child: Image.network(
                    template.signedGetUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PreviewPanel(
                  label: 'Photo',
                  child: Image.file(File(photoPath), fit: BoxFit.cover),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          template.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'तस्वीर सही है तो backend merge शुरू करें।',
          style: TextStyle(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _MergedPreview extends StatelessWidget {
  const _MergedPreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
