import 'package:flutter/material.dart';

import '../../../core/utils/price_formatter.dart';
import '../../../shared/widgets/gl_network_image.dart';
import '../../catalog/data/models/catalog_item.dart';

class SalonServiceDetailsPage extends StatefulWidget {
  const SalonServiceDetailsPage({
    required this.item,
    super.key,
    this.originalPrice,
    this.onFavoriteChanged,
  });

  final CatalogItem item;

  /// السعر السابق قبل الخصم.
  /// اتركيه null إذا ماكو خصم.
  final num? originalPrice;

  /// يربط القلب مع API المفضلة عند تمرير الدالة من الصفحة السابقة.
  final Future<void> Function(bool isFavorite)? onFavoriteChanged;

  @override
  State<SalonServiceDetailsPage> createState() =>
      _SalonServiceDetailsPageState();
}

class _SalonServiceDetailsPageState extends State<SalonServiceDetailsPage> {
  final PageController _pageController = PageController();

  int _currentImageIndex = 0;
  late bool _isFavorite;
  bool _isFavoriteLoading = false;

  CatalogItem get item => widget.item;

  List<String> get _imageUrls {
    return item.images
        .map((image) => image.url?.trim())
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }

  String get _priceText {
    if (item.priceType == 'inspection') {
      return 'السعر بعد المعاينة';
    }

    return PriceFormatter.formatIqd(item.price);
  }

  String? get _originalPriceText {
    final num? originalPrice = widget.originalPrice;

    if (originalPrice == null ||
        item.priceType == 'inspection' ||
        item.price == null ||
        originalPrice <= item.price!) {
      return null;
    }

    return PriceFormatter.formatIqd(originalPrice);
  }

  @override
  void initState() {
    super.initState();
    _isFavorite = item.isFavorite;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) {
      return;
    }

    final bool oldValue = _isFavorite;
    final bool newValue = !oldValue;

    setState(() {
      _isFavorite = newValue;
      _isFavoriteLoading = true;
    });

    try {
      await widget.onFavoriteChanged?.call(newValue);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isFavorite = oldValue;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('تعذر تحديث المفضلة. حاولي مرة ثانية.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isFavoriteLoading = false;
        });
      }
    }
  }

  void _openBooking() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('تم اختيار خدمة ${item.name}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final List<String> images = _imageUrls;

    final Color backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _ImagesGallery(
                  images: images,
                  controller: _pageController,
                  currentIndex: _currentImageIndex,
                  onPageChanged: (int index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ServiceHeader(
                      item: item,
                      priceText: _priceText,
                      originalPriceText: _originalPriceText,
                    ),
                    if (item.durationMinutes != null) ...[
                      const SizedBox(height: 16),
                      _DetailLine(
                        icon: Icons.schedule_rounded,
                        text: '${item.durationMinutes} دقيقة',
                      ),
                    ],
                    if (item.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 26),
                      const _SectionTitle(title: 'الوصف'),
                      const SizedBox(height: 10),
                      Text(
                        item.description!.trim(),
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 15,
                          height: 1.75,
                        ),
                      ),
                    ],
                    if (item.instructions?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 26),
                      const _SectionTitle(title: 'التعليمات'),
                      const SizedBox(height: 11),
                      _InstructionsCard(
                        instructions: item.instructions!.trim(),
                        isDark: isDark,
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),

          // زر الرجوع والقلب فوق الصورة.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundOverlayButton(
                    tooltip: 'المفضلة',
                    icon: _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor: _isFavorite
                        ? const Color(0xFFC9A227)
                        : const Color(0xFF1C1C1C),
                    isLoading: _isFavoriteLoading,
                    onPressed: _toggleFavorite,
                  ),
                  _RoundOverlayButton(
                    tooltip: 'رجوع',
                    icon: Icons.arrow_forward_rounded,
                    iconColor: const Color(0xFF1C1C1C),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BookingBar(isDark: isDark, onPressed: _openBooking),
    );
  }
}

class _ImagesGallery extends StatelessWidget {
  const _ImagesGallery({
    required this.images,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<String> images;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double imageHeight = MediaQuery.sizeOf(context).height * 0.48;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: imageHeight.clamp(350.0, 460.0),
          child: images.isEmpty
              ? _GalleryPlaceholder(isDark: isDark)
              : PageView.builder(
                  controller: controller,
                  itemCount: images.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) {
                              return _FullScreenImagePage(
                                imageUrl: images[index],
                              );
                            },
                          ),
                        );
                      },
                      child: ColoredBox(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        child: GlNetworkImage(
                          imageUrl: images[index],

                          // تعرض الصورة بشكل قريب من فانيلا.
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
        ),

        // مصغرات الصور فقط، بدون عداد 1/3.
        if (images.length > 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
            child: SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: images.length,
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(width: 9);
                },
                itemBuilder: (BuildContext context, int index) {
                  final bool isSelected = currentIndex == index;

                  return GestureDetector(
                    onTap: () {
                      controller.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 68,
                      height: 68,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFC9A227)
                              : isDark
                              ? const Color(0xFF2E2E2E)
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 2.2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: GlNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _GalleryPlaceholder extends StatelessWidget {
  const _GalleryPlaceholder({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: isDark
              ? const [Color(0xFF242424), Color(0xFF171717)]
              : const [Color(0xFFFFFBF0), Color(0xFFF0E5C3)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.spa_outlined, color: Color(0xFFC9A227), size: 58),
      ),
    );
  }
}

class _ServiceHeader extends StatelessWidget {
  const _ServiceHeader({
    required this.item,
    required this.priceText,
    required this.originalPriceText,
  });

  final CatalogItem item;
  final String priceText;
  final String? originalPriceText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item.name,
          textAlign: TextAlign.start,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 25,
            height: 1.25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              priceText,
              style: const TextStyle(
                color: Color(0xFFC9A227),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (originalPriceText != null)
              Text(
                originalPriceText!,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.lineThrough,
                  decorationThickness: 1.8,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({required this.instructions, required this.isDark});

  final String instructions;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A227).withValues(alpha: isDark ? 0.10 : 0.075),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFC9A227).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFC9A227),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              instructions,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundOverlayButton extends StatelessWidget {
  const _RoundOverlayButton({
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
    this.isLoading = false,
  });

  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.20),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: isLoading ? null : onPressed,
        constraints: const BoxConstraints.tightFor(width: 56, height: 56),
        icon: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color: Color(0xFFC9A227),
                ),
              )
            : Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.isDark, required this.onPressed});

  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text(
              'احجزي هذه الخدمة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: isDark
                  ? const Color(0xFFC9A227)
                  : const Color(0xFF1C1C1C),
              foregroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImagePage extends StatelessWidget {
  const _FullScreenImagePage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: GlNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 14,
              end: 14,
              child: _RoundOverlayButton(
                tooltip: 'إغلاق',
                icon: Icons.close_rounded,
                iconColor: const Color(0xFF1C1C1C),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.start,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFC9A227), size: 21),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
