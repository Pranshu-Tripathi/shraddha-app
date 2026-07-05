import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../services/ringtone_platform.dart';
import '../theme/app_colors.dart';

/// List of devotional ringtones. All use the bundled placeholder tone for now;
/// the backend provides the real catalog + audio (docs/BACKEND_API.md → §3).
class RingtoneScreen extends StatefulWidget {
  const RingtoneScreen({super.key});

  @override
  State<RingtoneScreen> createState() => _RingtoneScreenState();
}

class _RingtoneScreenState extends State<RingtoneScreen> {
  static const Color _accent = Color(0xFF2F8E86);
  static const String _asset = 'assets/audio/ringtone_placeholder.wav';

  static const List<(String, String)> _items = [
    ('ॐ ध्वनि', 'Om Dhwani'),
    ('गायत्री मंत्र', 'Gayatri Mantra'),
    ('शिव धुन', 'Shiv Dhun'),
    ('हनुमान चालीसा', 'Hanuman Chalisa'),
    ('कृष्ण बांसुरी', 'Krishna Flute'),
    ('मंदिर घंटी', 'Temple Bell'),
  ];

  int? _busy;

  Future<void> _set(int i) async {
    setState(() => _busy = i);
    try {
      final data = await rootBundle.load(_asset);
      final res = await RingtonePlatform.setRingtone(
        data.buffer.asUint8List(),
        name: 'shanti_$i',
      );
      if (!mounted) return;
      switch (res) {
        case 'set':
          _snack('रिंगटोन सेट हो गई 🙏');
        case 'needs_permission':
          _snack('अनुमति दें — सेटिंग खुल गई है, चालू करके वापस आएँ');
        default:
          _snack('रिंगटोन सेट नहीं हो पाई');
      }
    } catch (e) {
      if (mounted) _snack('त्रुटि: $e');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: const Text('भक्ति रिंगटोन',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _items.length,
        separatorBuilder: (context, i) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (hi, en) = _items[i];
          final busy = _busy == i;
          return Material(
            color: const Color(0xFFCFE7E3),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                        color: _accent, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hi,
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                        Text(en,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.inkMuted)),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _accent),
                    onPressed: busy ? null : () => _set(i),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('सेट करें'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
