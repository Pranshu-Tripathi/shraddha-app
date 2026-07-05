import 'package:flutter/material.dart';

import '../config/sections.dart';
import '../theme/app_colors.dart';

/// A large, tappable section row for the scrollable home list (WhatsApp-style):
/// colour-coded emoji badge, big Devanagari name, small English, chevron.
class SectionTile extends StatelessWidget {
  const SectionTile({super.key, required this.section, required this.onTap});

  final BhaktiSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${section.hindi}, ${section.english}',
      child: Material(
        color: section.tint,
        borderRadius: BorderRadius.circular(22),
        elevation: 1,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: section.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: section.color.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(section.emoji, style: const TextStyle(fontSize: 38)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        section.hindi,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        section.english,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: section.color, size: 34),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
