import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/gl_network_image.dart';
import '../data/customer_banner.dart';
import '../providers/banner_provider.dart';
import 'banner_navigator.dart';

class CustomerBannerCarousel extends ConsumerStatefulWidget {
  const CustomerBannerCarousel({
    required this.placement,
    this.aspectRatio = 1.58,
    this.height,
    super.key,
  });

  final String placement;
  final double aspectRatio;
  final double? height;

  @override
  ConsumerState<CustomerBannerCarousel> createState() =>
      _CustomerBannerCarouselState();
}

class _CustomerBannerCarouselState
    extends ConsumerState<CustomerBannerCarousel>
    with WidgetsBindingObserver {
  static const Duration _autoPlayDuration =
      Duration(seconds: 3);

  static const Duration _pageAnimationDuration =
      Duration(milliseconds: 650);

  final PageController _pageController =
      PageController();

  Timer? _autoPlayTimer;

  int _currentIndex = 0;

  List<CustomerBanner> _items = const [];

  bool _isUserDragging = false;
  bool _isAutoAnimating = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _startAutoPlay();
    } else {
      _stopAutoPlay();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _stopAutoPlay();

    _pageController.dispose();

    super.dispose();
  }

  void _startAutoPlay() {
    _stopAutoPlay();

    if (_items.length < 2 || _isUserDragging) {
      return;
    }

    _autoPlayTimer = Timer.periodic(
      _autoPlayDuration,
      (_) {
        if (!mounted ||
            !_pageController.hasClients ||
            _items.length < 2) {
          return;
        }

        final nextIndex =
            (_currentIndex + 1) % _items.length;

        _isAutoAnimating = true;

        _pageController
            .animateToPage(
              nextIndex,
              duration: _pageAnimationDuration,
              curve: Curves.easeOutCubic,
            )
            .whenComplete(() {
          if (mounted) {
            _isAutoAnimating = false;
          }
        });
      },
    );
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _pauseForInteraction() {
    _isUserDragging = true;
    _stopAutoPlay();
  }

  void _resumeAfterInteraction() {
    _isUserDragging = false;
    _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(bannersProvider(widget.placement));

    return state.when(
      loading: () => _buildLoading(context),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        _syncItems(items);

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildCarousel(context, items);
      },
    );
  }

  void _syncItems(
    List<CustomerBanner> items,
  ) {
    final changed =
        items.length != _items.length ||
        !_sameBannerIds(items, _items);

    if (!changed) {
      return;
    }

    _items =
        List<CustomerBanner>.unmodifiable(items);

    _currentIndex = _items.isEmpty
        ? 0
        : _currentIndex
            .clamp(0, _items.length - 1)
            .toInt();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_pageController.hasClients &&
          _items.isNotEmpty) {
        _pageController.jumpToPage(_currentIndex);
      }

      _startAutoPlay();
    });
  }

  bool _sameBannerIds(
    List<CustomerBanner> first,
    List<CustomerBanner> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (var i = 0; i < first.length; i++) {
      if (first[i].imageUrl != second[i].imageUrl ||
          first[i].title != second[i].title ||
          first[i].subtitle != second[i].subtitle) {
        return false;
      }
    }

    return true;
  }

  Widget _buildLoading(BuildContext context) {
    return _frame(
      context,
      const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0x12000000),
        ),
        child: Center(
          child: SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
            ),
          ),
        ),
      ),
      showOuterShadow: false,
    );
  }

  Widget _buildCarousel(
    BuildContext context,
    List<CustomerBanner> items,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _frame(
          context,
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification
                      is ScrollStartNotification &&
                  !_isAutoAnimating) {
                _pauseForInteraction();
              } else if (notification
                      is ScrollEndNotification &&
                  _isUserDragging) {
                _resumeAfterInteraction();
              }

              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              physics:
                  const BouncingScrollPhysics(),
              onPageChanged: (index) {
                if (!mounted) {
                  return;
                }

                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final banner = items[index];

                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == items.length - 1
                        ? 0
                        : 4,
                  ),
                  child: _BannerCard(
                    banner: banner,
                  ),
                );
              },
            ),
          ),
        ),

        if (items.length > 1) ...[
          const SizedBox(height: 10),
          _BannerIndicators(
            count: items.length,
            currentIndex: _currentIndex,
          ),
        ],
      ],
    );
  }

  Widget _frame(
    BuildContext context,
    Widget child, {
    bool showOuterShadow = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width -
                    36;

        final calculatedHeight =
            widget.height ??
                (availableWidth /
                        widget.aspectRatio)
                    .clamp(205.0, 330.0)
                    .toDouble();

        return SizedBox(
          height: calculatedHeight,
          width: double.infinity,
          child: showOuterShadow
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    // الحواف متوسطة وليست دائرية زيادة.
                    borderRadius:
                        BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.075,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: child,
                )
              : child,
        );
      },
    );
  }
}

class _BannerIndicators extends StatelessWidget {
  const _BannerIndicators({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) {
          final selected =
              index == currentIndex;

          return AnimatedContainer(
            duration:
                const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(
              horizontal: 3,
            ),
            width: selected ? 20 : 6,
            height: 5,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFC9A227)
                  : const Color(0x55C9A227),
              borderRadius:
                  BorderRadius.circular(99),
            ),
          );
        },
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
  });

  final CustomerBanner banner;

  @override
  Widget build(BuildContext context) {
    final hasText =
        banner.title?.trim().isNotEmpty == true ||
        banner.subtitle?.trim().isNotEmpty == true;

    const double radius = 16;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            BannerNavigator.open(context, banner),
        borderRadius:
            BorderRadius.circular(radius),
        child: Ink(
          decoration: const BoxDecoration(
            // لا يوجد border نهائياً.
            color: Colors.transparent,
            borderRadius:
                BorderRadius.all(
              Radius.circular(radius),
            ),
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // الصورة تملأ البنر بالكامل بدون إطار.
                GlNetworkImage(
                  imageUrl: banner.imageUrl,
                ),

                if (hasText)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:
                            Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [
                          0,
                          0.38,
                          0.72,
                          1,
                        ],
                        colors: [
                          Colors.black.withValues(
                            alpha: 0.68,
                          ),
                          Colors.black.withValues(
                            alpha: 0.28,
                          ),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                if (hasText)
                  PositionedDirectional(
                    start: 18,
                    end: 18,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (banner.title
                                ?.trim()
                                .isNotEmpty ==
                            true)
                          Text(
                            banner.title!.trim(),
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                          ),

                        if (banner.subtitle
                                ?.trim()
                                .isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 4),
                          Text(
                            banner.subtitle!.trim(),
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  Colors.white.withValues(
                                alpha: 0.90,
                              ),
                              fontSize: 12.5,
                              fontWeight:
                                  FontWeight.w300,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}