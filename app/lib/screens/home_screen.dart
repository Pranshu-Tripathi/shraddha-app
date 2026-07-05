import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/sections.dart';
import '../state/session_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/section_tile.dart';
import '../widgets/temple_header.dart';

/// Home (landing): one continuous scroll — temple header, the section tiles,
/// and a closing section at the bottom.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _routeFor(String id) => switch (id) {
        'status' => '/status',
        'wallpaper' => '/wallpaper',
        'rashifal' => '/rashifal',
        'ringtone' => '/ringtone',
        'meditation' => '/meditation',
        _ => '/section/$id',
      };

  void _showAccount(BuildContext context) {
    final session = SessionScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('मेरा खाता',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 10),
              Text('+91 ${session.session?.phone ?? ''}',
                  style: const TextStyle(fontSize: 16, color: AppColors.ink)),
              Text(
                session.isSubscribed ? 'सदस्यता: सक्रिय ✓' : 'सदस्यता: निष्क्रिय',
                style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    session.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('नंबर बदलें / लॉग आउट'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.templeTop, AppColors.templeMid, AppColors.cream],
            stops: [0.0, 0.22, 0.45],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header scrolls with the rest; the account button rides on it.
              Stack(
                children: [
                  const TempleHeader(),
                  Positioned(
                    top: 2,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.account_circle,
                          color: AppColors.maroon, size: 30),
                      onPressed: () => _showAccount(context),
                    ),
                  ),
                ],
              ),
              for (int i = 0; i < kSections.length; i++)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, i == 0 ? 4 : 0, 16, 14),
                  child: SectionTile(
                    section: kSections[i],
                    onTap: () => context.push(_routeFor(kSections[i].id)),
                  ),
                ),
              const _EndSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Closing section at the bottom of the home scroll — a gentle sign-off.
class _EndSection extends StatelessWidget {
  const _EndSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
      child: Column(
        children: [
          Text('🪔  ✦  🪔',
              style: TextStyle(
                  fontSize: 16,
                  color: AppColors.gold.withValues(alpha: 0.9))),
          const SizedBox(height: 14),
          const Text(
            '॥ ॐ शान्ति शान्ति शान्ति ॥',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.maroon),
          ),
          const SizedBox(height: 8),
          const Text(
            'हर दिन थोड़ी भक्ति, थोड़ी शान्ति 🙏',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 20),
          Text('Shanti · संस्करण 0.1.0',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.inkMuted.withValues(alpha: 0.75))),
          const SizedBox(height: 2),
          Text('❤️ भक्ति से बनाया गया',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.inkMuted.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}
