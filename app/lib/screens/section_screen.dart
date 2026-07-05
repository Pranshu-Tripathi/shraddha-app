import 'package:flutter/material.dart';

import '../config/sections.dart';
import '../theme/app_colors.dart';

/// Generic section screen. Content will load from the backend later; for now
/// it shows a friendly, on-theme placeholder.
class SectionScreen extends StatelessWidget {
  const SectionScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  Widget build(BuildContext context) {
    final section = sectionById(sectionId);
    if (section == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('—')),
        body: const Center(child: Text('Section not found')),
      );
    }
    return Scaffold(
      backgroundColor: section.tint,
      appBar: AppBar(
        backgroundColor: section.color,
        foregroundColor: Colors.white,
        title: Text(
          section.hindi,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration:
                  BoxDecoration(color: section.color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(section.emoji, style: const TextStyle(fontSize: 70)),
            ),
            const SizedBox(height: 24),
            Text(
              section.hindi,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.english,
              style: const TextStyle(fontSize: 18, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),
            const Text(
              'जल्द आ रहा है 🙏',
              style: TextStyle(fontSize: 20, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
