import 'dart:async';

import 'package:flutter/material.dart';

import '../config/mantras.dart';
import '../theme/app_colors.dart';
import '../widgets/rudraksha_mala.dart';

/// Meditation player: recite along while a rudraksha mala advances one bead per
/// interval. The interval is a local placeholder; the backend will provide
/// `bead_timings_s` synced to the mantra audio (docs/BACKEND_API.md → §5).
class MeditationPlayerScreen extends StatefulWidget {
  const MeditationPlayerScreen({super.key, required this.mantraKey});

  final String mantraKey;

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF5E8A52);

  late final Mantra _m = mantraByKey(widget.mantraKey) ?? kMantras.first;
  int _active = 0;
  int _rounds = 0;
  bool _playing = false;
  Timer? _timer;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  void _toggle() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _timer = Timer.periodic(Duration(milliseconds: _m.beadIntervalMs), (_) {
        setState(() {
          _active++;
          if (_active >= _m.beads) {
            _active = 0;
            _rounds++;
          }
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Text(_m.hindi, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 18),
          Text(_m.hindi,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink)),
          Text(_m.english,
              style: const TextStyle(fontSize: 15, color: AppColors.inkMuted)),
          Expanded(
            child: Center(
              child: RudrakshaMala(
                beads: _m.beads,
                active: _active,
                pulse: _pulse,
              ),
            ),
          ),
          Text('मनका ${_active + 1} / ${_m.beads}    •    माला $_rounds',
              style: const TextStyle(fontSize: 16, color: AppColors.ink)),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            onPressed: _toggle,
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
            label: Text(_playing ? 'रोकें' : 'शुरू करें',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
