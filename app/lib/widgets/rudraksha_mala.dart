import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A lightweight, custom-painted rudraksha mala (japa beads in a ring).
/// The [active] bead is highlighted and gently pulses; advancing [active]
/// (driven by the player / backend bead timings) walks the mala. No assets.
class RudrakshaMala extends StatelessWidget {
  const RudrakshaMala({
    super.key,
    required this.beads,
    required this.active,
    required this.pulse,
  });

  final int beads;
  final int active;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(300),
      painter: _MalaPainter(beads: beads, active: active, pulse: pulse),
    );
  }
}

class _MalaPainter extends CustomPainter {
  _MalaPainter({required this.beads, required this.active, required this.pulse})
      : super(repaint: pulse);

  final int beads;
  final int active;
  final Animation<double> pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 - 8);
    final r = size.width / 2 - 28;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x553E2A1A),
    );

    for (int i = 0; i < beads; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / beads;
      final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      if (i == active) {
        final s = 1.0 + pulse.value * 0.35;
        canvas.drawCircle(p, 17 * s,
            Paint()..color = const Color(0xFFE0A33B).withValues(alpha: 0.45));
        canvas.drawCircle(p, 11 * s, Paint()..color = const Color(0xFF8A5A2E));
        canvas.drawCircle(
          p,
          11 * s,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = const Color(0xFFF0C56B),
        );
      } else {
        canvas.drawCircle(p, 9, Paint()..color = const Color(0xFF7A4A2B));
        canvas.drawLine(
          Offset(p.dx - 5, p.dy),
          Offset(p.dx + 5, p.dy),
          Paint()
            ..color = const Color(0x335A351E)
            ..strokeWidth = 1.4,
        );
      }
    }

    // Guru (sumeru) bead with a tassel at the bottom.
    final gp = Offset(c.dx, c.dy + r + 20);
    canvas.drawCircle(gp, 13, Paint()..color = const Color(0xFF5A351E));
    canvas.drawLine(
      gp,
      Offset(gp.dx, gp.dy + 22),
      Paint()
        ..color = const Color(0xFF8A2A2A)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MalaPainter oldDelegate) =>
      oldDelegate.active != active || oldDelegate.beads != beads;
}
