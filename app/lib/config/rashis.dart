/// The 12 rashis (zodiac signs) — static, fixed on device. Daily summaries come
/// from the backend (see docs/BACKEND_API.md → §4 Rashifal).
class Rashi {
  const Rashi({
    required this.key,
    required this.hindi,
    required this.english,
    required this.emoji,
    required this.dates,
  });

  final String key;
  final String hindi;
  final String english;
  final String emoji;
  final String dates;
}

const List<Rashi> kRashis = [
  Rashi(
    key: 'mesh',
    hindi: 'मेष',
    english: 'Aries',
    emoji: '🐏',
    dates: '21 मार्च – 19 अप्रैल',
  ),
  Rashi(
    key: 'vrishabh',
    hindi: 'वृषभ',
    english: 'Taurus',
    emoji: '🐂',
    dates: '20 अप्रैल – 20 मई',
  ),
  Rashi(
    key: 'mithun',
    hindi: 'मिथुन',
    english: 'Gemini',
    emoji: '👯',
    dates: '21 मई – 20 जून',
  ),
  Rashi(
    key: 'kark',
    hindi: 'कर्क',
    english: 'Cancer',
    emoji: '🦀',
    dates: '21 जून – 22 जुलाई',
  ),
  Rashi(
    key: 'simha',
    hindi: 'सिंह',
    english: 'Leo',
    emoji: '🦁',
    dates: '23 जुलाई – 22 अगस्त',
  ),
  Rashi(
    key: 'kanya',
    hindi: 'कन्या',
    english: 'Virgo',
    emoji: '🌾',
    dates: '23 अगस्त – 22 सितंबर',
  ),
  Rashi(
    key: 'tula',
    hindi: 'तुला',
    english: 'Libra',
    emoji: '⚖️',
    dates: '23 सितंबर – 22 अक्टूबर',
  ),
  Rashi(
    key: 'vrishchik',
    hindi: 'वृश्चिक',
    english: 'Scorpio',
    emoji: '🦂',
    dates: '23 अक्टूबर – 21 नवंबर',
  ),
  Rashi(
    key: 'dhanu',
    hindi: 'धनु',
    english: 'Sagittarius',
    emoji: '🏹',
    dates: '22 नवंबर – 21 दिसंबर',
  ),
  Rashi(
    key: 'makar',
    hindi: 'मकर',
    english: 'Capricorn',
    emoji: '🐊',
    dates: '22 दिसंबर – 19 जनवरी',
  ),
  Rashi(
    key: 'kumbh',
    hindi: 'कुम्भ',
    english: 'Aquarius',
    emoji: '🏺',
    dates: '20 जनवरी – 18 फरवरी',
  ),
  Rashi(
    key: 'meen',
    hindi: 'मीन',
    english: 'Pisces',
    emoji: '🐟',
    dates: '19 फरवरी – 20 मार्च',
  ),
];
