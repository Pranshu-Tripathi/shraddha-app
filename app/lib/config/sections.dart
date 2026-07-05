import 'package:flutter/material.dart';

/// One devotional section shown on the home list. Presentation config only —
/// the actual content comes from the backend (see docs/BACKEND_API.md).
class BhaktiSection {
  const BhaktiSection({
    required this.id,
    required this.hindi,
    required this.english,
    required this.emoji,
    required this.color,
    required this.tint,
  });

  final String id;
  final String hindi;
  final String english;
  final String emoji;
  final Color color; // saturated accent
  final Color tint; // soft card background

  String get routePath => '/section/$id';
}

/// The four sections. Order = display order on the home list.
const List<BhaktiSection> kSections = [
  BhaktiSection(
    id: 'status',
    hindi: 'स्टेटस बनाएँ',
    english: 'WhatsApp Status',
    emoji: '💬',
    color: Color(0xFF1FA855),
    tint: Color(0xFFCFEAD8),
  ),
  BhaktiSection(
    id: 'wallpaper',
    hindi: 'दिव्य वॉलपेपर',
    english: 'Divine Wallpapers',
    emoji: '🖼️',
    color: Color(0xFF5B57A6),
    tint: Color(0xFFDAD8EF),
  ),
  BhaktiSection(
    id: 'ringtone',
    hindi: 'भक्ति रिंगटोन',
    english: 'Bhakti Ringtones',
    emoji: '🔔',
    color: Color(0xFF2F8E86),
    tint: Color(0xFFCFE7E3),
  ),
  BhaktiSection(
    id: 'rashifal',
    hindi: 'राशिफल',
    english: 'Daily Rashifal',
    emoji: '✨',
    color: Color(0xFFD6A019),
    tint: Color(0xFFFAE8BE),
  ),
  BhaktiSection(
    id: 'meditation',
    hindi: 'ध्यान',
    english: 'Meditation',
    emoji: '🧘',
    color: Color(0xFF5E8A52),
    tint: Color(0xFFDCE8CE),
  ),
];

BhaktiSection? sectionById(String id) {
  for (final s in kSections) {
    if (s.id == id) return s;
  }
  return null;
}
