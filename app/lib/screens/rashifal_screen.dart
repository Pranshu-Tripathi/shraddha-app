import 'package:flutter/material.dart';

import '../config/rashis.dart';
import '../theme/app_colors.dart';

/// One page with all 12 rashis; tap a rashi to expand its short daily summary.
/// Rashis are static; the daily summary comes from the backend (placeholder now).
class RashifalScreen extends StatefulWidget {
  const RashifalScreen({super.key});

  @override
  State<RashifalScreen> createState() => _RashifalScreenState();
}

class _RashifalScreenState extends State<RashifalScreen> {
  static const Color _accent = Color(0xFFD6A019);
  int? _open;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: const Text(
          'राशिफल',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: kRashis.length,
        separatorBuilder: (context, i) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final r = kRashis[i];
          final open = _open == i;
          return Material(
            color: const Color(0xFFFAE8BE),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _open = open ? null : i),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: _accent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            r.emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.hindi,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                r.dates,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.expand_more, color: _accent),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: open
                          ? _Summary(rashi: r)
                          : const SizedBox(width: double.infinity),
                    ),
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

class _Summary extends StatelessWidget {
  const _Summary({required this.rashi});

  final Rashi rashi;

  @override
  Widget build(BuildContext context) {
    // Placeholder — backend fills the daily summary (docs/BACKEND_API.md §4).
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(
            'आज ${rashi.hindi} राशि के लिए दिन शुभ है। धैर्य और भक्ति बनाए रखें — '
            'रुका हुआ कार्य पूरा होगा।',
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _Pill(label: 'शुभ रंग: केसरी'),
              SizedBox(width: 8),
              _Pill(label: 'शुभ अंक: ९'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.ink),
      ),
    );
  }
}
