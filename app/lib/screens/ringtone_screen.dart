import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';

import '../api/services_scope.dart';
import '../models/blob_audio.dart';
import '../services/media_storage.dart';
import '../services/ringtone_platform.dart';
import '../services/secure_media_http.dart';
import '../theme/app_colors.dart';

/// Devotional ringtones backed by `/v1/audio`.
class RingtoneScreen extends StatefulWidget {
  const RingtoneScreen({super.key});

  @override
  State<RingtoneScreen> createState() => _RingtoneScreenState();
}

class _RingtoneScreenState extends State<RingtoneScreen> {
  static const Color _accent = Color(0xFF2F8E86);
  static const String _asset = 'assets/audio/ringtone_placeholder.wav';

  Future<BlobAudioListing>? _future;
  List<String> _categories = const [];
  String? _selectedCategory;
  String? _busyId;
  String? _loadingPreviewId;
  String? _playingId;
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _playerSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _playerSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() => _playingId = null);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _loadAudio(updateCategories: true);
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<BlobAudioListing> _loadAudio({
    String? category,
    bool updateCategories = false,
  }) async {
    final listing = await ServicesScope.of(
      context,
    ).audio.listAudio(category: category);
    if (!mounted || !updateCategories) return listing;

    final categories = listing.categories.isNotEmpty
        ? listing.categories
        : _uniqueCategories(listing.items);
    if (!_sameCategories(_categories, categories)) {
      setState(() => _categories = categories);
    }
    return listing;
  }

  List<String> _uniqueCategories(List<BlobAudio> items) {
    final categories = <String>{};
    for (final item in items) {
      if (item.category.isNotEmpty) categories.add(item.category);
    }
    return categories.toList(growable: false);
  }

  bool _sameCategories(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _selectCategory(String? category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _future = _loadAudio(category: category);
    });
  }

  Future<void> _set(BlobAudio audio) async {
    setState(() => _busyId = audio.id);
    try {
      final bytes = await _audioBytes(audio);
      final res = await RingtonePlatform.setRingtone(
        bytes,
        name: _safeName(audio),
        mimeType: audio.contentType,
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
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _togglePreview(BlobAudio audio) async {
    if (_loadingPreviewId != null) return;

    if (_playingId == audio.id) {
      await _player.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }

    setState(() => _loadingPreviewId = audio.id);
    try {
      await _player.stop();
      if (audio.signedGetUrl.isEmpty) {
        await _player.setAsset(_asset);
      } else {
        await _player.setUrl(audio.signedGetUrl);
      }
      if (!mounted) return;
      setState(() => _playingId = audio.id);
      unawaited(
        _player.play().catchError((Object error) {
          if (mounted) _snack('ऑडियो नहीं चल पाया: $error');
        }),
      );
    } catch (e) {
      if (mounted) _snack('ऑडियो नहीं चल पाया: $e');
    } finally {
      if (mounted) setState(() => _loadingPreviewId = null);
    }
  }

  Future<Uint8List> _audioBytes(BlobAudio audio) async {
    if (audio.signedGetUrl.isEmpty) {
      final data = await rootBundle.load(_asset);
      return data.buffer.asUint8List();
    }

    final file = await _downloadToMediaStorage(audio);
    return file.readAsBytes();
  }

  Future<File> _downloadToMediaStorage(BlobAudio audio) async {
    final dir = await MediaStorage.mediaDir();
    final file = File(
      '${dir.path}/ringtone-${_safeName(audio)}-${DateTime.now().millisecondsSinceEpoch}${_extensionFor(audio)}',
    );
    await SecureMediaHttp.downloadToFile(
      url: audio.signedGetUrl,
      destination: file,
      maxBytes: SecureMediaHttp.maxAudioBytes,
      allowedContentTypePrefixes: const ['audio/'],
    );
    return file;
  }

  String _safeName(BlobAudio audio) {
    final title = _normalizeName(audio.title);
    if (title.isNotEmpty) return title;

    final id = _normalizeName(audio.id);
    return id.isEmpty ? 'ringtone' : id;
  }

  String _normalizeName(String value) {
    final safe = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return safe.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }

  String _extensionFor(BlobAudio audio) {
    return switch (audio.contentType?.toLowerCase()) {
      'audio/aac' => '.aac',
      'audio/flac' => '.flac',
      'audio/mp4' || 'audio/m4a' || 'audio/x-m4a' => '.m4a',
      'audio/mpeg' || 'audio/mp3' => '.mp3',
      'audio/ogg' || 'audio/opus' => '.ogg',
      'audio/wav' || 'audio/x-wav' || 'audio/wave' => '.wav',
      _ => '.audio',
    };
  }

  void _retry() {
    setState(() {
      _future = _loadAudio(
        category: _selectedCategory,
        updateCategories: _selectedCategory == null,
      );
    });
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
        title: const Text(
          'भक्ति रिंगटोन',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _CategoryChips(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onSelected: _selectCategory,
          ),
          Expanded(
            child: FutureBuilder<BlobAudioListing>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _RingtoneError(
                    message: snapshot.error.toString(),
                    onRetry: _retry,
                  );
                }

                final items = snapshot.data?.items ?? const <BlobAudio>[];
                if (items.isEmpty) return const _EmptyRingtoneList();
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  itemCount: items.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final audio = items[i];
                    return _RingtoneTile(
                      audio: audio,
                      busy: _busyId == audio.id,
                      previewLoading: _loadingPreviewId == audio.id,
                      playing: _playingId == audio.id,
                      onPreview: () => _togglePreview(audio),
                      onSet: () => _set(audio),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final allCategories = <String?>[null, ...categories];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: allCategories.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = allCategories[i];
          final selected = category == selectedCategory;
          return ChoiceChip(
            label: Text(category == null ? 'सभी' : _labelFor(category)),
            selected: selected,
            onSelected: (_) => onSelected(category),
            selectedColor: _RingtoneScreenState._accent,
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF164F4A),
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: const Color(0xFFCFE7E3),
            side: BorderSide.none,
            showCheckmark: false,
          );
        },
      ),
    );
  }

  String _labelFor(String category) {
    final words = category.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (words.isEmpty) return category;
    return words
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

class _RingtoneTile extends StatelessWidget {
  const _RingtoneTile({
    required this.audio,
    required this.busy,
    required this.previewLoading,
    required this.playing,
    required this.onPreview,
    required this.onSet,
  });

  final BlobAudio audio;
  final bool busy;
  final bool previewLoading;
  final bool playing;
  final VoidCallback onPreview;
  final VoidCallback onSet;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFCFE7E3),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: _RingtoneScreenState._accent,
                foregroundColor: Colors.white,
                fixedSize: const Size(48, 48),
              ),
              tooltip: playing ? 'रोकें' : 'चलाएँ',
              onPressed: previewLoading ? null : onPreview,
              icon: previewLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(playing ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    audio.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _RingtoneScreenState._accent,
              ),
              onPressed: busy ? null : onSet,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('सेट करें'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingtoneError extends StatelessWidget {
  const _RingtoneError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Color(0xFF2F8E86)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF164F4A)),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('फिर कोशिश करें'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRingtoneList extends StatelessWidget {
  const _EmptyRingtoneList();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'इस श्रेणी में अभी रिंगटोन उपलब्ध नहीं हैं।',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF164F4A)),
        ),
      ),
    );
  }
}
