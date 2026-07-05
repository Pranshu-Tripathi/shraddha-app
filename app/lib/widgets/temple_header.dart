import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft, welcoming landing header: a gentle abstract watercolor (blurred colour
/// clouds), a muted breathing ॐ with a warm halo, a few drifting light motes,
/// and a soft marigold toran with swaying bells. Calming and easy on the eyes;
/// sits above the unchanged, clear section list.
class TempleHeader extends StatefulWidget {
  const TempleHeader({super.key});

  @override
  State<TempleHeader> createState() => _TempleHeaderState();
}

class _TempleHeaderState extends State<TempleHeader>
    with TickerProviderStateMixin {
  late final AnimationController _slow =
      AnimationController(vsync: this, duration: const Duration(seconds: 80))
        ..repeat();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _slow.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Soft abstract watercolor (static, painted once).
          const Positioned.fill(
            child: CustomPaint(painter: _BlobPainter()),
          ),
          // Gentle drifting light motes + faint ring (animated, light).
          Positioned.fill(
            child: CustomPaint(
              painter: _MotePainter(
                repaint: Listenable.merge([_slow, _pulse]),
                slow: _slow,
                pulse: _pulse,
              ),
            ),
          ),
          // Soft marigold garland across the top.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 54),
              painter: _ToranPainter(),
            ),
          ),
          // Bells, gently swaying.
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final sway = (_pulse.value - 0.5) * 0.10;
              return Stack(
                children: [
                  Positioned(top: 40, left: 22, child: _bell(sway)),
                  Positioned(top: 40, right: 22, child: _bell(-sway)),
                ],
              );
            },
          ),
          // Breathing Om at the centre.
          Positioned(top: 74, left: 0, right: 0, child: Center(child: _om())),
          // Title.
          Positioned(
            top: 226,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'शान्ति',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: AppColors.maroon,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(
                        color: AppColors.glowGold.withValues(alpha: 0.8),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
                Text(
                  'दर्शन करें 🙏',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.ink.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bell(double angle) => Transform.rotate(
        angle: angle,
        alignment: Alignment.topCenter,
        child: const Text('🔔', style: TextStyle(fontSize: 24)),
      );

  Widget _om() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.5 + _pulse.value * 0.4;
        final scale = 0.98 + _pulse.value * 0.04;
        return SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      stops: const [0.0, 0.45, 1.0],
                      colors: [
                        AppColors.glowGold.withValues(alpha: 0.25 + 0.35 * glow),
                        AppColors.glowGold.withValues(alpha: 0.22 * glow),
                        AppColors.glowGold.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Text(
                'ॐ',
                style: TextStyle(
                  fontSize: 76,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepSaffron,
                  shadows: [
                    Shadow(
                      color: AppColors.glowGold.withValues(alpha: 0.9),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Soft, blurred abstract colour clouds — a calm watercolor backdrop.
class _BlobPainter extends CustomPainter {
  const _BlobPainter();

  // [fractionX, fractionY, radius, colorIndex]
  static const List<List<double>> _blobs = [
    [0.20, 0.34, 150, 0],
    [0.82, 0.26, 132, 1],
    [0.30, 0.74, 158, 2],
    [0.78, 0.70, 140, 3],
    [0.52, 0.44, 124, 4],
  ];

  static const List<Color> _colors = [
    Color(0xFFE8A07E), // soft terracotta
    Color(0xFFE6B8C2), // dusty rose
    Color(0xFFEBCB97), // muted gold
    Color(0xFFF2C3A0), // soft peach
    Color(0xFFD9C6E0), // gentle lavender
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _blobs) {
      final paint = Paint()
        ..color = _colors[b[3].toInt()].withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36);
      canvas.drawCircle(
        Offset(b[0] * size.width, b[1] * size.height),
        b[2],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) => false;
}

/// Faint sacred ring + a few softly twinkling, rising light motes.
class _MotePainter extends CustomPainter {
  _MotePainter({
    required Listenable repaint,
    required this.slow,
    required this.pulse,
  }) : super(repaint: repaint);

  final Animation<double> slow;
  final Animation<double> pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 148);
    canvas.drawCircle(
      center,
      104,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = AppColors.gold.withValues(alpha: 0.12),
    );

    final p = pulse.value;
    for (int i = 0; i < 7; i++) {
      final bx = (((i * 0.61803398875) * 5) % 1.0) * size.width;
      final phase = ((slow.value * 6 * (0.5 + (i % 3) * 0.2)) + i * 0.2) % 1.0;
      final py = size.height * (1.0 - phase);
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(p * 2 * math.pi + i));
      canvas.drawCircle(
        Offset(bx, py),
        2.0,
        Paint()..color = const Color(0xFFFBE9C8).withValues(alpha: 0.30 * tw),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MotePainter oldDelegate) => true;
}

/// Paints a soft marigold-and-leaf garland sagging gently across the width.
class _ToranPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const topPad = 6.0;
    final sag = size.height - topPad - 10;

    double yAt(double x) {
      final t = (2 * x / w) - 1;
      return topPad + sag * (1 - t * t);
    }

    final string = Paint()
      ..color = const Color(0xFF7C9A5E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final path = Path()..moveTo(0, yAt(0));
    for (double x = 0; x <= w; x += 6) {
      path.lineTo(x, yAt(x));
    }
    canvas.drawPath(path, string);

    const count = 14;
    final spacing = w / (count - 1);
    for (int i = 0; i < count; i++) {
      final x = i * spacing;
      if (i < count - 1) {
        final mx = x + spacing / 2;
        _leaf(canvas, mx, yAt(mx) + 2);
      }
      _marigold(canvas, x, yAt(x) + 6);
    }
  }

  void _marigold(Canvas canvas, double x, double y) {
    canvas.drawCircle(Offset(x, y), 12, Paint()..color = const Color(0xFFD98A4A));
    canvas.drawCircle(Offset(x, y), 8.5, Paint()..color = const Color(0xFFE8AE6E));
    canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = const Color(0xFFF4D6A6));
  }

  void _leaf(Canvas canvas, double x, double y) {
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: 9, height: 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(r, Paint()..color = const Color(0xFF7C9A5E));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
