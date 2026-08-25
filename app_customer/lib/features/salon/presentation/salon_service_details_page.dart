import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        .where((String url) => url.isNotEmpty)
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
    context.pushNamed('booking', extra: item);
  }

  void _openImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return _FullScreenImagePage(imageUrl: imageUrl);
        },
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _ServiceGallery(
              images: images,
              controller: _pageController,
              currentIndex: _currentImageIndex,
              onPageChanged: (int index) {
                if (_currentImageIndex == index) {
                  return;
                }

                setState(() {
                  _currentImageIndex = index;
                });
              },
              onImagePressed: _openImage,
              isFavorite: _isFavorite,
              isFavoriteLoading: _isFavoriteLoading,
              onFavoritePressed: _toggleFavorite,
              onBackPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 124),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                _ServiceMainCard(
                  item: item,
                  priceText: _priceText,
                  originalPriceText: _originalPriceText,
                  isDark: isDark,
                ),
                if (item.description?.trim().isNotEmpty == true) ...<Widget>[
                  const SizedBox(height: 18),
                  _ContentCard(
                    title: 'عن الخدمة',
                    icon: Icons.auto_awesome_rounded,
                    child: Text(
                      item.description!.trim(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14.5,
                        height: 1.75,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
                if (item.instructions?.trim().isNotEmpty == true) ...<Widget>[
                  const SizedBox(height: 16),
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
      bottomNavigationBar: _BookingBar(
        isDark: isDark,
        onPressed: _openBooking,
      ),
    );
  }
}

class _ServiceGallery extends StatelessWidget {
  const _ServiceGallery({
    required this.images,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onImagePressed,
    required this.isFavorite,
    required this.isFavoriteLoading,
    required this.onFavoritePressed,
    required this.onBackPressed,
  });

  final List<String> images;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onImagePressed;
  final bool isFavorite;
  final bool isFavoriteLoading;
  final VoidCallback onFavoritePressed;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double galleryHeight = (screenHeight * 0.40)
        .clamp(290.0, 380.0)
        .toDouble();

    return SizedBox(
      width: double.infinity,
      height: galleryHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            child: images.isEmpty
                ? _GalleryPlaceholder(isDark: isDark)
                : PageView.builder(
                    controller: controller,
                    itemCount: images.length,
                    onPageChanged: onPageChanged,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          onImagePressed(images[index]);
                        },
                        child: ColoredBox(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          child: GlNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          IgnorePointer(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: <double>[0, 0.52, 1],
                    colors: <Color>[
                      Color(0x66000000),
                      Colors.transparent,
                      Color(0x44000000),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _RoundOverlayButton(
                      tooltip: 'المفضلة',
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: isFavorite
                          ? const Color(0xFFC9A227)
                          : const Color(0xFF1C1C1C),
                      isLoading: isFavoriteLoading,
                      onPressed: onFavoritePressed,
                    ),
                    _RoundOverlayButton(
                      tooltip: 'رجوع',
                      icon: Icons.arrow_forward_rounded,
                      iconColor: const Color(0xFF1C1C1C),
                      onPressed: onBackPressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
              ? const <Color>[Color(0xFF292929), Color(0xFF171717)]
              : const <Color>[Color(0xFFFFFBF0), Color(0xFFE9DDBB)],
        ),
      ),
      child: Center(
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: const Color(
              0xFFC9A227,
            ).withValues(alpha: isDark ? 0.16 : 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.spa_outlined,
            color: Color(0xFFC9A227),
            size: 46,
          ),
        ),
      ),
    );
  }
}

class _ServiceMainCard extends StatelessWidget {
  const _ServiceMainCard({
    required this.item,
    required this.priceText,
    required this.originalPriceText,
    required this.isDark,
  });

  final CatalogItem item;
  final String priceText;
  final String? originalPriceText;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            item.name,
            textAlign: TextAlign.start,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 17),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'السعر',
                      style: TextStyle(
                        color: Color(0xFF8A8176),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 9,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          priceText,
                          style: const TextStyle(
                            color: Color(0xFFC9A227),
                            fontSize: 20,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (originalPriceText != null)
                          Text(
                            originalPriceText!,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.lineThrough,
                              decorationThickness: 1.8,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (item.durationMinutes != null) ...<Widget>[
                const SizedBox(width: 12),
                _SmallInfoChip(
                  icon: Icons.schedule_rounded,
                  text: '${item.durationMinutes} دقيقة',
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallInfoChip extends StatelessWidget {
  const _SmallInfoChip({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A227).withValues(alpha: isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: const Color(0xFFC9A227), size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: isDark ? const Color(0xFFE0CE73) : const Color(0xFF806A16),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.23 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFC9A227,
                  ).withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFC9A227), size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A227).withValues(alpha: isDark ? 0.13 : 0.09),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFC9A227,
                  ).withValues(alpha: isDark ? 0.18 : 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFC9A227),
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'تعليمات قبل الخدمة',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            instructions,
            textAlign: TextAlign.start,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              height: 1.75,
              fontWeight: FontWeight.w500,
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
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: isLoading ? null : onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 43, height: 43),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFC9A227),
                ),
              )
            : Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({
    required this.isDark,
    required this.onPressed,
  });

  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color buttonColor = isDark
        ? const Color(0xFFC9A227)
        : const Color(0xFF1C1C1C);
    final Color buttonTextColor = isDark
        ? const Color(0xFF1C1C1C)
        : Colors.white;

    return Material(
      color: surfaceColor,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.38 : 0.14),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: Material(
              color: buttonColor,
              borderRadius: BorderRadius.circular(17),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 21,
                        color: buttonTextColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'احجزي الآن',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: buttonTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
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
          children: <Widget>[
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
            Positioned(
              right: 14,
              top: 14,
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
