/// Mantras for the meditation player. `beads` + `beadIntervalMs` are local
/// placeholders; the backend provides real `bead_timings_s` synced to audio
/// (see docs/BACKEND_API.md → §5 Meditation).
class Mantra {
  const Mantra({
    required this.key,
    required this.hindi,
    required this.english,
    required this.beads,
    required this.beadIntervalMs,
  });

  final String key;
  final String hindi;
  final String english;
  final int beads;
  final int beadIntervalMs;
}

const List<Mantra> kMantras = [
  Mantra(key: 'om', hindi: 'ॐ', english: 'Om', beads: 27, beadIntervalMs: 2500),
  Mantra(key: 'shiva', hindi: 'ॐ नमः शिवाय', english: 'Om Namah Shivaya', beads: 27, beadIntervalMs: 3000),
  Mantra(key: 'gayatri', hindi: 'गायत्री मंत्र', english: 'Gayatri Mantra', beads: 27, beadIntervalMs: 4500),
  Mantra(key: 'mahamrityunjaya', hindi: 'महामृत्युंजय', english: 'Mahamrityunjaya', beads: 27, beadIntervalMs: 5000),
  Mantra(key: 'krishna', hindi: 'हरे कृष्ण', english: 'Hare Krishna', beads: 27, beadIntervalMs: 2200),
];

Mantra? mantraByKey(String key) {
  for (final m in kMantras) {
    if (m.key == key) return m;
  }
  return null;
}
