import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/services_scope.dart';
import '../models/blob_image.dart';
import '../theme/app_colors.dart';
import 'wallpaper_view_screen.dart';

/// Wallpaper gallery backed by `/v1/images`.
class WallpaperScreen extends StatefulWidget {
  const WallpaperScreen({super.key});

  @override
  State<WallpaperScreen> createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends State<WallpaperScreen> {
  static const String _fallbackAsset =
      'assets/images/wallpaper_placeholder.jpg';
  static const Color _accent = Color(0xFF5B57A6);

  Future<BlobImageListing>? _future;
  List<String> _categories = const [];
  String? _selectedCategory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _loadImages(updateCategories: true);
  }

  Future<BlobImageListing> _loadImages({
    String? category,
    bool updateCategories = false,
  }) async {
    final images = ServicesScope.of(context).images;
    final listing = await images.listImages(category: category);
    if (!mounted || !updateCategories) return listing;

    final categories = listing.categories.isNotEmpty
        ? listing.categories
        : _uniqueCategories(listing.items);
    if (!_sameCategories(_categories, categories)) {
      setState(() => _categories = categories);
    }
    return listing;
  }

  List<String> _uniqueCategories(List<BlobImage> items) {
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
      _future = _loadImages(category: category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: const Text(
          'दिव्य वॉलपेपर',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryChips(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onSelected: _selectCategory,
          ),
          Expanded(
            child: FutureBuilder<BlobImageListing>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _WallpaperError(
                    message: snapshot.error.toString(),
                    onRetry: () {
                      setState(() {
                        _future = _loadImages(
                          category: _selectedCategory,
                          updateCategories: _selectedCategory == null,
                        );
                      });
                    },
                  );
                }

                final items = snapshot.data?.items ?? const <BlobImage>[];
                if (items.isEmpty) return const _EmptyWallpaperGrid();
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.52,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _WallpaperTile(
                    image: items[i],
                    onTap: () => context.push(
                      '/wallpaper/view',
                      extra: WallpaperViewArgs(
                        imageUrl: items[i].signedGetUrl,
                        title: _titleFor(items[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(BlobImage image) {
    final dot = image.name.lastIndexOf('.');
    final name = dot > 0 ? image.name.substring(0, dot) : image.name;
    return name.replaceAll(RegExp(r'[_-]+'), ' ');
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
            selectedColor: _WallpaperScreenState._accent,
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF34305D),
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: const Color(0xFFDAD8EF),
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

class _WallpaperTile extends StatelessWidget {
  const _WallpaperTile({required this.image, required this.onTap});

  final BlobImage image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              image.signedGetUrl,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const _WallpaperPlaceholder();
              },
              errorBuilder: (context, error, stackTrace) => Image.asset(
                _WallpaperScreenState._fallbackAsset,
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
                child: Text(
                  image.category.replaceAll(RegExp(r'[_-]+'), ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WallpaperPlaceholder extends StatelessWidget {
  const _WallpaperPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE4DECB),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _WallpaperError extends StatelessWidget {
  const _WallpaperError({required this.message, required this.onRetry});

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
            const Icon(Icons.cloud_off, size: 48, color: Color(0xFF5B57A6)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF34305D)),
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

class _EmptyWallpaperGrid extends StatelessWidget {
  const _EmptyWallpaperGrid();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'इस श्रेणी में अभी वॉलपेपर उपलब्ध नहीं हैं।',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF34305D)),
        ),
      ),
    );
  }
}
