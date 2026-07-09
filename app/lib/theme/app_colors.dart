import 'package:flutter/material.dart';

/// Warm, devotional palette — soft on the eyes. Each section also has its own
/// accent so users recognize it by colour, not just text.
class AppColors {
  const AppColors._();

  static const Color cream = Color(0xFFFFF7EC); // app background
  static const Color saffron = Color(0xFFEF8A2E); // primary
  static const Color maroon = Color(0xFFA52A2A); // accent
  static const Color gold = Color(0xFFD6A019);
  static const Color ink = Color(0xFF3D2B1F); // primary text (dark brown)
  static const Color inkMuted = Color(0xFF7A6552); // secondary text

  // Temple landing ambiance (soft, welcoming)
  static const Color templeTop = Color(
    0xFFEFD3B6,
  ); // soft warm peach-sand (top)
  static const Color templeMid = Color(0xFFF8E9D7);
  static const Color glowGold = Color(0xFFF3D9B4); // soft warm halo
  static const Color deepSaffron = Color(0xFFB66239); // muted terracotta (Om)
}
