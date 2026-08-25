import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/gl_empty_state.dart';
import '../../../shared/widgets/gl_error_state.dart';
import '../../../shared/widgets/gl_loading.dart';
import '../../../shared/widgets/gl_section_title.dart';
import '../../appointments/presentation/clinic_booking_page.dart';
import '../../catalog/data/models/catalog_category.dart';
import '../../catalog/data/models/catalog_item.dart';
import '../../catalog/providers/catalog_provider.dart';
import '../../posts/data/models/post_model.dart';
import '../../posts/providers/post_provider.dart';
import '../../salon/presentation/widgets/latest_posts_section.dart';
import '../../salon/presentation/widgets/salon_category_card.dart';
import 'clinic_category_page.dart';
import '../../banners/presentation/customer_banner_carousel.dart';
import '../../banners/providers/banner_provider.dart';

class ClinicPage extends ConsumerWidget {
  const ClinicPage({super.key});

  static const CatalogFilter _clinicFilter = CatalogFilter(
    department: 'clinic',
  );


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    final AsyncValue<List<CatalogItem>> catalogState = ref.watch(
      catalogItemsProvider(_clinicFilter),
    );

    final AsyncValue<List<PostModel>> postsState = ref.watch(
      postsProvider('clinic'),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _ClinicHeader(
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
                color: const Color(0xFFC9A227),
                onRefresh: () async {
                  await Future.wait(<Future<Object?>>[
                    ref.refresh(
                      catalogItemsProvider(_clinicFilter).future,
                    ),
                    ref.refresh(
                      postsProvider('clinic').future,
                    ),
                    ref.refresh(bannersProvider('clinic').future),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const CustomerBannerCarousel(placement: 'clinic', height: 178),

                      const SizedBox(height: 22),

                      const GlSectionTitle(
                        title: 'آخر المنشورات',
                      ),

                      const SizedBox(height: 12),

                      postsState.when(
                        loading: () => const SizedBox(
                          height: 164,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (
                          Object error,
                          StackTrace stackTrace,
                        ) {
                          return GlErrorState(
                            message:
                                'تعذر تحميل آخر منشورات العيادة.',
                            onRetry: () {
                              ref.invalidate(
                                postsProvider('clinic'),
                              );
                            },
                          );
                        },
                        data: (List<PostModel> posts) {
                          if (posts.isEmpty) {
                            return const GlEmptyState(
                              title: 'لا توجد منشورات حالياً',
                              message:
                                  'ستظهر آخر منشورات العيادة هنا.',
                              icon:
                                  Icons.photo_library_outlined,
                            );
                          }

                          return LatestPostsSection(
                            posts: posts,
                            onPostTap: (PostModel post) {
                              // المنشور صورة فقط ولا يحتاج إجراء إضافي حالياً.
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      const GlSectionTitle(
                        title: 'الخدمات',
                      ),

                      const SizedBox(height: 12),

                      catalogState.when(
                        loading: () => const GlLoading(
                          message:
                              'جاري تحميل خدمات العيادة...',
                        ),
                        error: (
                          Object error,
                          StackTrace stackTrace,
                        ) {
                          return GlErrorState(
                            message:
                                'تعذر تحميل خدمات العيادة. تأكدي من اتصال الخادم ثم أعيدي المحاولة.',
                            onRetry: () {
                              ref.invalidate(
                                catalogItemsProvider(
                                  _clinicFilter,
                                ),
                              );
                            },
                          );
                        },
                        data: (List<CatalogItem> items) {
                          final List<_ClinicCategoryViewData>
                              categories = _buildCategories(items);

                          if (categories.isEmpty) {
                            return const GlEmptyState(
                              title:
                                  'لا توجد خدمات حالياً',
                              message:
                                  'ستظهر خدمات العيادة هنا بعد إضافتها من تطبيق الإدارة.',
                              icon:
                                  Icons.medical_services_outlined,
                            );
                          }

                          return Column(
                            children: List<Widget>.generate(
                              categories.length,
                              (int index) {
                                final _ClinicCategoryViewData
                                    category =
                                    categories[index];

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        index ==
                                                categories.length -
                                                    1
                                            ? 0
                                            : 12,
                                  ),
                                  child: SalonCategoryCard(
                                    title: category.title,
                                    subtitle: category.subtitle,
                                    itemCount:
                                        category.items.length,
                                    imageUrl: category.imageUrl,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder:
                                              (
                                            BuildContext context,
                                          ) {
                                            return ClinicCategoryPage(
                                              categoryId:
                                                  category.id,
                                              categoryName:
                                                  category.title,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
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
      bottomNavigationBar: _ClinicBookingBar(
        onPressed: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (BuildContext context) {
                return const ClinicBookingPage();
              },
            ),
          );
        },
      ),
    );
  }

  List<_ClinicCategoryViewData> _buildCategories(
    List<CatalogItem> items,
  ) {
    final Map<int, List<CatalogItem>> groupedItems =
        <int, List<CatalogItem>>{};

    final Map<int, CatalogCategory> categories =
        <int, CatalogCategory>{};

    for (final CatalogItem item in items) {
      // الـ API يفترض أن يعيد فقط الخدمات التابعة للقسم المطلوب.
      // هنا نعرض فقط الخدمات الفعالة والمصنفة ضمن فئة.
      if (!item.isActive || !item.isService) {
        continue;
      }

      final CatalogCategory? category = item.category;

      if (category == null || category.id <= 0) {
        continue;
      }

      categories[category.id] = category;

      groupedItems
          .putIfAbsent(
            category.id,
            () => <CatalogItem>[],
          )
          .add(item);
    }

    final List<int> categoryIds =
        groupedItems.keys.toList()..sort();

    return categoryIds
        .map((int categoryId) {
          final CatalogCategory category =
              categories[categoryId]!;

          final List<CatalogItem> categoryItems =
              groupedItems[categoryId]!;

          final String description =
              category.description?.trim().isNotEmpty == true
                  ? category.description!.trim()
                  : _fallbackDescription(categoryItems);

          String? imageUrl;

          for (final CatalogItem item in categoryItems) {
            final String? currentImage =
                item.primaryImageUrl;

            if (currentImage != null &&
                currentImage.isNotEmpty) {
              imageUrl = currentImage;
              break;
            }
          }

          return _ClinicCategoryViewData(
            id: category.id,
            title: category.name,
            subtitle: description,
            imageUrl: imageUrl,
            items: categoryItems,
          );
        })
        .toList(growable: false);
  }

  String _fallbackDescription(
    List<CatalogItem> items,
  ) {
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

class _ClinicHeader extends StatelessWidget {
  const _ClinicHeader({
    required this.onBackPressed,
  });

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: 58,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Text(
            'العيادة',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                tooltip: 'رجوع',
                onPressed: onBackPressed,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicBookingBar extends StatelessWidget {
  const _ClinicBookingBar({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    final Color dividerColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE5E7EB);

    return Material(
      color: backgroundColor,
      elevation: 14,
      shadowColor: Colors.black.withValues(
        alpha: isDark ? 0.35 : 0.12,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            12,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: BorderSide(
                color: dividerColor,
              ),
            ),
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(
                Icons.calendar_month_outlined,
                size: 22,
              ),
              label: const Text(
                'احجزي الآن',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: isDark
                    ? const Color(0xFFC9A227)
                    : const Color(0xFF1C1C1C),
                foregroundColor: isDark
                    ? const Color(0xFF1C1C1C)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClinicCategoryViewData {
  const _ClinicCategoryViewData({
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
