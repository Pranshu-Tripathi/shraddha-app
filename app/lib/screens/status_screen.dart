import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../config/status_templates.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import 'status_result_screen.dart';

/// Gallery of WhatsApp-status templates. Tap one → capture a photo → result.
class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  static const Color _accent = Color(0xFF1FA855);

  Future<void> _capture(BuildContext context, StatusTemplate t) async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 88,
      );
      if (photo == null || !context.mounted) return;
      context.push(
        AppRoutes.statusResult,
        extra: StatusResultArgs(templateId: t.id, photoPath: photo.path),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('कैमरा नहीं खुला: $e')));
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
        title: const Text('स्टेटस बनाएँ',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'एक डिज़ाइन चुनें · अपनी तस्वीर लगाएँ · एक टैप में स्टेटस पर लगाएँ',
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.56,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: kStatusTemplates.length,
              itemBuilder: (context, i) {
                final t = kStatusTemplates[i];
                return GestureDetector(
                  onTap: () => _capture(context, t),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(t.asset, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
