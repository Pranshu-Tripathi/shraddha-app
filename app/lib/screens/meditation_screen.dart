import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/mantras.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';

/// List of mantras to meditate with. Tap one to open the player.
class MeditationScreen extends StatelessWidget {
  const MeditationScreen({super.key});

  static const Color _accent = Color(0xFF5E8A52);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: const Text('ध्यान', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: kMantras.length,
        separatorBuilder: (context, i) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final m = kMantras[i];
          return Material(
            color: const Color(0xFFDCE8CE),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push(AppRoutes.meditationPlayPath(m.key)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                          color: _accent, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text('🧘', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.hindi,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink)),
                          Text(m.english,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.inkMuted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.play_circle_fill, color: _accent, size: 34),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
