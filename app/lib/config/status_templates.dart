import 'dart:ui';

/// A WhatsApp-status template. The user's captured photo is placed into [slot]
/// (relative 0..1 coords). Templates are bundled placeholders now; the backend
/// will provide the real catalog and do the merge (see docs/BACKEND_API.md).
class StatusTemplate {
  const StatusTemplate({
    required this.id,
    required this.hindi,
    required this.english,
    required this.asset,
    required this.slotLeft,
    required this.slotTop,
    required this.slotWidth,
    required this.slotHeight,
  });

  final String id;
  final String hindi;
  final String english;
  final String asset;
  final double slotLeft;
  final double slotTop;
  final double slotWidth;
  final double slotHeight;

  /// The photo slot in absolute pixels for a rendered area of [size].
  Rect slotIn(Size size) => Rect.fromLTWH(
    slotLeft * size.width,
    slotTop * size.height,
    slotWidth * size.width,
    slotHeight * size.height,
  );
}

const List<StatusTemplate> kStatusTemplates = [
  StatusTemplate(
    id: 'morning',
    hindi: 'शुभ प्रभात',
    english: 'Good Morning',
    asset: 'assets/images/status/status_morning.jpg',
    slotLeft: 0.18,
    slotTop: 0.36,
    slotWidth: 0.64,
    slotHeight: 0.36,
  ),
  StatusTemplate(
    id: 'blessing',
    hindi: 'आशीर्वाद',
    english: 'Blessings',
    asset: 'assets/images/status/status_blessing.jpg',
    slotLeft: 0.18,
    slotTop: 0.36,
    slotWidth: 0.64,
    slotHeight: 0.36,
  ),
  StatusTemplate(
    id: 'lotus',
    hindi: 'जय श्री राम',
    english: 'Jai Shri Ram',
    asset: 'assets/images/status/status_lotus.jpg',
    slotLeft: 0.18,
    slotTop: 0.36,
    slotWidth: 0.64,
    slotHeight: 0.36,
  ),
];

StatusTemplate? statusTemplateById(String id) {
  for (final t in kStatusTemplates) {
    if (t.id == id) return t;
  }
  return null;
}
