import 'package:flutter/material.dart';

import '../state/session_scope.dart';
import '../theme/app_colors.dart';

/// Subscription gate shown when the user is signed in but not subscribed.
/// The "activate" button is a mock for now — real payment comes later.
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
                  child: const Icon(Icons.lock_outline,
                      size: 46, color: AppColors.saffron),
                ),
                const SizedBox(height: 18),
                const Text('सदस्यता आवश्यक है',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.maroon)),
                const SizedBox(height: 8),
                const Text(
                  'पूरी सामग्री — वॉलपेपर, रिंगटोन, राशिफल और ध्यान — '
                  'देखने के लिए सदस्यता लें।',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.4, color: AppColors.ink),
                ),
                const SizedBox(height: 18),
                if (phone.isNotEmpty)
                  Text('खाता: +91 $phone',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.inkMuted)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed:
                        busy ? null : () => session.activateSubscription(),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('सदस्यता सक्रिय करें',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('(टेस्ट — भुगतान बाद में जुड़ेगा)',
                    style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
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
