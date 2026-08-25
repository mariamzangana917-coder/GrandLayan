import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../appointments/presentation/salon_booking_page.dart';
import 'salon_category_page.dart';
import '../../../shared/widgets/gl_empty_state.dart';
import '../../../shared/widgets/gl_error_state.dart';
import '../../../shared/widgets/gl_loading.dart';
import '../../../shared/widgets/gl_section_title.dart';
import '../../catalog/data/models/catalog_category.dart';
import '../../catalog/data/models/catalog_item.dart';
import '../../catalog/providers/catalog_provider.dart';
import 'widgets/fixed_booking_bar.dart';
import 'widgets/latest_posts_section.dart';
import 'widgets/salon_category_card.dart';
import 'widgets/salon_header.dart';
import '../../posts/providers/post_provider.dart';
import '../../posts/data/models/post_model.dart';
import '../../banners/presentation/customer_banner_carousel.dart';
import '../../banners/providers/banner_provider.dart';


class SalonPage extends ConsumerWidget {
  const SalonPage({super.key});

  static const CatalogFilter _salonFilter = CatalogFilter(department: 'salon');



  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('صفحة $feature راح نكملها بالخطوة القادمة.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    final AsyncValue<List<CatalogItem>> catalogState = ref.watch(
      catalogItemsProvider(_salonFilter),
    );
final AsyncValue<List<PostModel>> postsState = ref.watch(
  postsProvider('salon'),
);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SalonHeader(
              onBackPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed('home');
                }
              },
            ),
            Expanded(
              child: RefreshIndicator(
                  onRefresh: () async {
  await Future.wait([
    ref.refresh(catalogItemsProvider(_salonFilter).future),
    ref.refresh(postsProvider('salon').future),
    ref.refresh(bannersProvider('salon').future),
  ]);
},
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    const CustomerBannerCarousel(placement: 'salon', height: 178),
                      const SizedBox(height: 22),
                      const GlSectionTitle(title: 'آخر المنشورات'),
const SizedBox(height: 12),

postsState.when(
  loading: () => const SizedBox(
    height: 164,
    child: Center(
      child: CircularProgressIndicator(),
    ),
  ),
  error: (Object error, StackTrace stackTrace) {
    return GlErrorState(
      message: 'تعذر تحميل آخر المنشورات حالياً.',
      onRetry: () {
        ref.invalidate(postsProvider('salon'));
      },
    );
  },
  data: (List<PostModel> posts) {
    if (posts.isEmpty) {
      return const GlEmptyState(
        title: 'لا توجد منشورات حالياً',
        message: 'ستظهر آخر منشورات الصالون هنا.',
        icon: Icons.photo_library_outlined,
      );
    }

    return LatestPostsSection(
      posts: posts,
      onPostTap: (PostModel post) {
        // حالياً المنشور صورة فقط ولا يحتاج إجراء إضافياً.
      },
    );
  },
),
                      const SizedBox(height: 24),
                      const GlSectionTitle(title: 'الخدمات'),
                      const SizedBox(height: 12),
                      catalogState.when(
                        loading: () => const GlLoading(
                          message: 'جاري تحميل خدمات الصالون...',
                        ),
                        error: (Object error, StackTrace stackTrace) {
                          return GlErrorState(
                            message:
                                'تعذر تحميل خدمات الصالون. تأكدي من اتصال الخادم ثم أعيدي المحاولة.',
                            onRetry: () {
                              ref.invalidate(
                                catalogItemsProvider(_salonFilter),
                              );
                            },
                          );
                        },
                        data: (List<CatalogItem> items) {
                          final List<_SalonCategoryViewData> categories =
                              _buildCategories(items);

                          if (categories.isEmpty) {
                            return const GlEmptyState(
                              title: 'لا توجد خدمات حاليًا',
                              message:
                                  'ستظهر خدمات الصالون هنا بعد إضافتها من تطبيق الإدارة.',
                              icon: Icons.content_cut_rounded,
                            );
                          }

                          return Column(
                            children: List<Widget>.generate(categories.length, (
                              int index,
                            ) {
                              final _SalonCategoryViewData category =
                                  categories[index];

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == categories.length - 1
                                      ? 0
                                      : 12,
                                ),
                                child: SalonCategoryCard(
                                  title: category.title,
                                  subtitle: category.subtitle,
                                  itemCount: category.items.length,
                                  imageUrl: category.imageUrl,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (BuildContext context) {
                                          return SalonCategoryPage(
                                            categoryId: category.id,
                                            categoryName: category.title,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FixedBookingBar(
        onPressed: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (BuildContext context) {
                return const SalonBookingPage();
              },
            ),
          );
        },
      ),
    );
  }

  List<_SalonCategoryViewData> _buildCategories(List<CatalogItem> items) {
    final Map<int, List<CatalogItem>> groupedItems = <int, List<CatalogItem>>{};

    final Map<int, CatalogCategory> categories = <int, CatalogCategory>{};

    for (final CatalogItem item in items) {
      final CatalogCategory? category = item.category;

      if (!item.isActive || category == null || !category.isActive) {
        continue;
      }

      categories[category.id] = category;

      groupedItems.putIfAbsent(category.id, () => <CatalogItem>[]).add(item);
    }

    final List<int> categoryIds = groupedItems.keys.toList()..sort();

    return categoryIds
        .map((int categoryId) {
          final CatalogCategory category = categories[categoryId]!;
          final List<CatalogItem> categoryItems = groupedItems[categoryId]!;

          final String description =
              category.description?.trim().isNotEmpty == true
              ? category.description!.trim()
              : _fallbackDescription(categoryItems);

          String? imageUrl;

          for (final CatalogItem item in categoryItems) {
            final String? currentImage = item.primaryImageUrl;

            if (currentImage != null && currentImage.trim().isNotEmpty) {
              imageUrl = currentImage;
              break;
            }
          }

          return _SalonCategoryViewData(
            id: category.id,
            title: category.name,
            subtitle: description,
            imageUrl: imageUrl,
            items: categoryItems,
          );
        })
        .toList(growable: false);
  }

  String _fallbackDescription(List<CatalogItem> items) {
    final List<String> names = items
        .map((CatalogItem item) => item.name.trim())
        .where((String name) => name.isNotEmpty)
        .take(4)
        .toList(growable: false);

    if (names.isEmpty) {
      return 'خدمات وعناية متخصصة';
    }

    return names.join('، ');
  }
}

class _SalonCategoryViewData {
  const _SalonCategoryViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.items,
    this.imageUrl,
  });

  final int id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final List<CatalogItem> items;
}
