import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../api/services_scope.dart';
import '../models/face_swap.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import 'status_result_screen.dart';

/// Gallery of backend face-swap templates. Pick one, capture a selfie, then
/// confirm upload + merge on the result screen.
class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  static const Color _accent = Color(0xFF1FA855);

  Future<FaceSwapTemplateList>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= ServicesScope.of(context).status.templates();
  }

  void _retry() {
    setState(() {
      _future = ServicesScope.of(context).status.templates();
    });
  }

  Future<void> _chooseTemplate(FaceSwapTemplate template) async {
    final shouldCapture = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CaptureSheet(template: template),
    );
    if (shouldCapture != true || !mounted) return;
    await _capture(template);
  }

  Future<void> _capture(FaceSwapTemplate template) async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 88,
      );
      if (photo == null || !mounted) return;
      context.push(
        AppRoutes.statusResult,
        extra: StatusResultArgs(template: template, photoPath: photo.path),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('कैमरा नहीं खुला: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: const Text(
          'स्टेटस बनाएँ',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'एक डिज़ाइन चुनें · अपनी तस्वीर लें · backend से स्टेटस बनाएँ',
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
            ),
          ),
          Expanded(
            child: FutureBuilder<FaceSwapTemplateList>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _StatusError(
                    message: snapshot.error.toString(),
                    onRetry: _retry,
                  );
                }

                final templates =
                    snapshot.data?.items ?? const <FaceSwapTemplate>[];
                if (templates.isEmpty) return const _EmptyTemplates();
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.56,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (context, i) {
                    final template = templates[i];
                    return GestureDetector(
                      onTap: () => _chooseTemplate(template),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              template.signedGetUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const _TemplatePlaceholder();
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const _TemplatePlaceholder(),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  28,
                                  10,
                                  10,
                                ),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black54,
                                    ],
                                  ),
                                ),
                                child: Text(
                                  template.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureSheet extends StatelessWidget {
  const _CaptureSheet({required this.template});

  final FaceSwapTemplate template;

  @override
  Widget build(BuildContext context) {
    final previewHeight = (MediaQuery.sizeOf(context).height * 0.42).clamp(
      220.0,
      320.0,
    );
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: previewHeight.toDouble(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    template.signedGetUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _StatusScreenState._accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(
                    'अपनी तस्वीर लें',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplatePlaceholder extends StatelessWidget {
  const _TemplatePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD9EBD8),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _StatusError extends StatelessWidget {
  const _StatusError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Color(0xFF1FA855)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ink),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('फिर कोशिश करें'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTemplates extends StatelessWidget {
  const _EmptyTemplates();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'अभी कोई स्टेटस टेम्पलेट उपलब्ध नहीं है।',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.ink),
        ),
      ),
    );
  }
}
