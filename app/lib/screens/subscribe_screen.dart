import 'package:flutter/material.dart';

import '../state/session_scope.dart';
import '../theme/app_colors.dart';

/// Subscription gate shown when the user is signed in but not subscribed.
class SubscribeScreen extends StatelessWidget {
  const SubscribeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final phone = session.session?.phone ?? '';
    final busy = session.busy;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.saffron.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.lock_outline,
                    size: 46,
                    color: AppColors.saffron,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'सदस्यता आवश्यक है',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.maroon,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'पूरी सामग्री — वॉलपेपर, रिंगटोन, राशिफल और ध्यान — '
                  'देखने के लिए सदस्यता लें।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 18),
                if (phone.isNotEmpty)
                  Text(
                    'खाता: +91 $phone',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.saffron,
                    disabledBackgroundColor: AppColors.saffron.withValues(
                      alpha: 0.45,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                  ),
                  onPressed: null,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'सदस्यता जल्द उपलब्ध होगी',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'भुगतान सत्यापन जुड़ने के बाद ही सदस्यता खुलेगी',
                  style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: busy ? null : () => session.signOut(),
                  child: const Text('नंबर बदलें'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
