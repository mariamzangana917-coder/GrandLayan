import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../salon/presentation/salon_service_details_page.dart';
import '../../../../shared/widgets/gl_network_image.dart';
import '../../data/models/favorite_item.dart';
import '../../providers/favorite_provider.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key, this.onBack});

  /// استخدميه عندما تكون الصفحة داخل BottomNavigationBar أو PageView
  /// ولا توجد Route سابقة يمكن إغلاقها بواسطة Navigator.pop.
  final VoidCallback? onBack;

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  final Set<int> _removingItemIds = <int>{};
  bool _isClearingAll = false;

  Future<void> _refresh() async {
    ref.invalidate(favoritesProvider);
    await ref.read(favoritesProvider.future);
  }

  Future<void> _removeFavorite(FavoriteItem favorite) async {
    final int catalogItemId = favorite.catalogItem.id;

    if (_isClearingAll || _removingItemIds.contains(catalogItemId)) {
      return;
    }

    setState(() {
      _removingItemIds.add(catalogItemId);
    });

    try {
      final repository = ref.read(favoriteRepositoryProvider);

      await repository.removeFavorite(catalogItemId);

      ref.invalidate(favoritesProvider);
      await ref.read(favoritesProvider.future);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('تعذر حذف الخدمة من المفضلة. حاولي مرة ثانية.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _removingItemIds.remove(catalogItemId);
        });
      }
    }
  }

  Future<void> _confirmAndClearAll(List<FavoriteItem> favorites) async {
    if (_isClearingAll || favorites.isEmpty) {
      return;
    }

    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _ClearFavoritesDialog(itemCount: favorites.length);
      },
    );

    if (shouldClear != true || !mounted) {
      return;
    }

    final List<int> catalogItemIds = favorites
        .map((FavoriteItem favorite) => favorite.catalogItem.id)
        .toList(growable: false);

    setState(() {
      _isClearingAll = true;
      _removingItemIds.addAll(catalogItemIds);
    });

    int removedCount = 0;
    int failedCount = 0;

    try {
      final repository = ref.read(favoriteRepositoryProvider);

      // نستخدم نفس دالة الحذف الحالية للحفاظ على الربط الموجود.
      // الحذف المتسلسل ألطف على الخادم ويمنع إرسال عدد كبير من الطلبات دفعة واحدة.
      for (final int catalogItemId in catalogItemIds) {
        try {
          await repository.removeFavorite(catalogItemId);
          removedCount++;
        } catch (_) {
          failedCount++;
        }
      }

      ref.invalidate(favoritesProvider);
      await ref.read(favoritesProvider.future);

      if (!mounted) {
        return;
      }

      final String message = failedCount == 0
          ? 'تم مسح جميع المفضلات.'
          : 'تم حذف $removedCount وتعذر حذف $failedCount. حاولي مرة ثانية.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('تعذر مسح المفضلات. تحققي من الاتصال وحاولي مجددًا.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isClearingAll = false;
          _removingItemIds.clear();
        });
      }
    }
  }

  Future<void> _changeFavoriteFromDetails({
    required int catalogItemId,
    required bool isFavorite,
  }) async {
    final repository = ref.read(favoriteRepositoryProvider);

    if (isFavorite) {
      await repository.addFavorite(catalogItemId);
    } else {
      await repository.removeFavorite(catalogItemId);
    }

    ref.invalidate(favoritesProvider);
  }

  Future<void> _openDetails(FavoriteItem favorite) async {
    if (_isClearingAll) {
      return;
    }

    final int catalogItemId = favorite.catalogItem.id;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return SalonServiceDetailsPage(
            item: favorite.catalogItem,
            onFavoriteChanged: (bool isFavorite) {
              return _changeFavoriteFromDetails(
                catalogItemId: catalogItemId,
                isFavorite: isFavorite,
              );
            },
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    ref.invalidate(favoritesProvider);
  }

  void _goBack() {
    // صفحة المفضلة موجودة داخل IndexedStack في CustomerMainShell،
    // لذلك الرجوع الصحيح يتم عبر callback من الصفحة الأم.
    final VoidCallback? customBack = widget.onBack;
    if (customBack != null) {
      customBack();
      return;
    }

    // احتياطًا إذا فُتحت الصفحة لاحقًا بواسطة Navigator.push.
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<FavoriteItem>> favoritesState = ref.watch(
      favoritesProvider,
    );
    final List<FavoriteItem> currentFavorites =
        favoritesState.asData?.value ?? const <FavoriteItem>[];

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark
        ? const Color(0xFF121212)
        : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _FavoritesHeader(
              itemCount: currentFavorites.length,
              isClearingAll: _isClearingAll,
              canClearAll: currentFavorites.isNotEmpty,
              onBack: _goBack,
              onClearAll: () {
                _confirmAndClearAll(currentFavorites);
              },
            ),
            Expanded(
              child: favoritesState.when(
                loading: () => const _FavoritesLoadingView(),
                error: (Object error, StackTrace stackTrace) {
                  return _FavoritesErrorView(
                    onRetry: () {
                      ref.invalidate(favoritesProvider);
                    },
                  );
                },
                data: (List<FavoriteItem> favorites) {
                  if (favorites.isEmpty) {
                    return RefreshIndicator(
                      color: const Color(0xFFC9A227),
                      onRefresh: _refresh,
                      child: const _EmptyFavoritesView(),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFFC9A227),
                    onRefresh: _isClearingAll ? () async {} : _refresh,
                    child: ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsetsDirectional.fromSTEB(
                        16,
                        10,
                        16,
                        24 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      itemCount: favorites.length,
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(height: 14);
                      },
                      itemBuilder: (BuildContext context, int index) {
                        final FavoriteItem favorite = favorites[index];
                        final int catalogItemId = favorite.catalogItem.id;

                        return _FavoriteServiceCard(
                          favorite: favorite,
                          isRemoving: _removingItemIds.contains(catalogItemId),
                          onTap: () {
                            _openDetails(favorite);
                          },
                          onRemove: () {
                            _removeFavorite(favorite);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({
    required this.itemCount,
    required this.isClearingAll,
    required this.canClearAll,
    required this.onBack,
    required this.onClearAll,
  });

  final int itemCount;
  final bool isClearingAll;
  final bool canClearAll;
  final VoidCallback onBack;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryTextColor = isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF1C1C1C);
    final Color secondaryTextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _HeaderBackButton(onPressed: onBack),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'المفضلة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ClearAllButton(
                isLoading: isClearingAll,
                onPressed: canClearAll && !isClearingAll ? onClearAll : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'الخدمات والبكجات التي أحببتِها',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FavoritesCountBadge(count: itemCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: 'رجوع',
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: Icon(
        Icons.arrow_forward_rounded,
        textDirection: TextDirection.ltr,
        color: isDark ? Colors.white : Colors.black,
        size: 25,
      ),
    );
  }
}

class _ClearAllButton extends StatelessWidget {
  const _ClearAllButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color deleteColor = Color(0xFFB85C55);

    return Material(
      color: onPressed == null
          ? Colors.transparent
          : deleteColor.withValues(alpha: isDark ? 0.14 : 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 42, maxWidth: 112),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: deleteColor,
                    ),
                  )
                else
                  Icon(
                    Icons.delete_sweep_outlined,
                    color: onPressed == null
                        ? (isDark
                              ? const Color(0xFF5F5F5F)
                              : const Color(0xFFBDBDBD))
                        : deleteColor,
                    size: 20,
                  ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'مسح الكل',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onPressed == null
                          ? (isDark
                                ? const Color(0xFF5F5F5F)
                                : const Color(0xFFBDBDBD))
                          : deleteColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
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

class _FavoritesCountBadge extends StatelessWidget {
  const _FavoritesCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A227).withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.055),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$count',
            style: TextStyle(
              color: isDark ? const Color(0xFFD7C46A) : const Color(0xFFA88412),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'محفوظة',
            style: TextStyle(
              color: isDark ? const Color(0xFFBDB8A6) : const Color(0xFF756D58),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearFavoritesDialog extends StatelessWidget {
  const _ClearFavoritesDialog({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    const Color deleteColor = Color(0xFFB85C55);

    return AlertDialog(
      backgroundColor: isDark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      titlePadding: const EdgeInsetsDirectional.fromSTEB(22, 22, 22, 0),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(22, 12, 22, 8),
      actionsPadding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
      title: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: deleteColor.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: deleteColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'مسح جميع المفضلات؟',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFF2F2F2)
                    : const Color(0xFF1C1C1C),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'سيتم حذف $itemCount من الخدمات والبكجات المحفوظة. لا يمكن التراجع عن هذه الخطوة.',
        style: TextStyle(
          color: isDark ? const Color(0xFFA7A7A7) : const Color(0xFF6B7280),
          fontSize: 13,
          height: 1.6,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          style: TextButton.styleFrom(
            foregroundColor: isDark
                ? const Color(0xFFE4E4E4)
                : const Color(0xFF3D3D3D),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'إلغاء',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: deleteColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.delete_sweep_outlined, size: 19),
          label: const Text(
            'مسح الكل',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _FavoriteServiceCard extends StatelessWidget {
  const _FavoriteServiceCard({
    required this.favorite,
    required this.isRemoving,
    required this.onTap,
    required this.onRemove,
  });

  final FavoriteItem favorite;
  final bool isRemoving;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final item = favorite.catalogItem;
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color surfaceColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFFFFFFF);

    final Color titleColor = isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF1C1C1C);

    final Color secondaryTextColor = isDark
        ? const Color(0xFFA7A7A7)
        : const Color(0xFF737373);

    final String description = item.description?.trim() ?? '';

    const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(16));

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: cardBorderRadius,
        // نفس حافة الكارد في الصورة: بدون خط Border واضح.
        // ظل محيطي خفيف مع ظل سفلي قصير يعطي بروزًا بسيطًا.
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.045),
            blurRadius: 3.5,
            spreadRadius: 0,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.18),
            blurRadius: 2.5,
            spreadRadius: 0,
            offset: const Offset(0, 2.5),
          ),
        ],
      ),
      child: Material(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        borderRadius: cardBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardBorderRadius,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double imageWidth = constraints.maxWidth < 310 ? 84 : 96;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: imageWidth,
                      height: 112,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: GlNetworkImage(
                          imageUrl: item.primaryImageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          0,
                          3,
                          0,
                          3,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 15.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _FavoriteRemoveButton(
                                  isLoading: isRemoving,
                                  onPressed: onRemove,
                                ),
                              ],
                            ),
                            if (description.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 7),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 12.5,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Color(0xFFC9A227),
                                  size: 17,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'عرض التفاصيل',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFD7C46A)
                                          : const Color(0xFFA88412),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteRemoveButton extends StatelessWidget {
  const _FavoriteRemoveButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: const Color(0xFFC9A227).withValues(alpha: isDark ? 0.16 : 0.11),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: 'إزالة من المفضلة',
        onPressed: isLoading ? null : onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        icon: isLoading
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFC9A227),
                ),
              )
            : const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFC9A227),
                size: 21,
              ),
      ),
    );
  }
}

class _FavoritesLoadingView extends StatelessWidget {
  const _FavoritesLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          color: Color(0xFFC9A227),
        ),
      ),
    );
  }
}

class _EmptyFavoritesView extends StatelessWidget {
  const _EmptyFavoritesView();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primaryTextColor = isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF1C1C1C);

    final Color secondaryTextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    final Color surfaceColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFFFFFFF);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.30 : 0.065,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.03 : 0.78,
                        ),
                        blurRadius: 8,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFC9A227,
                          ).withValues(alpha: isDark ? 0.16 : 0.11),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: Color(0xFFC9A227),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'لا توجد مفضلات بعد',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 19,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'احفظي الخدمات والبكجات التي تعجبك، وستظهر هنا لسهولة الوصول إليها لاحقًا.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13,
                          height: 1.65,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoritesErrorView extends StatelessWidget {
  const _FavoritesErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primaryTextColor = isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF1C1C1C);

    final Color secondaryTextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFC9A227,
                  ).withValues(alpha: isDark ? 0.16 : 0.11),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: Color(0xFFC9A227),
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'تعذر تحميل المفضلة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 19,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'تحققي من الاتصال بالخادم ثم حاولي مرة أخرى.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A227),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(170, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
