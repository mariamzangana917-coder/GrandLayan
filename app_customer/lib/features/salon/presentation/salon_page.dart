import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class SalonPage extends StatelessWidget {
  const SalonPage({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'صفحة $feature راح نكملها ونربطها بالبيانات الحقيقية.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final surfaceColor =
        isDark ? const Color(0xFF101010) : const Color(0xFFFAF9F7);
    final primaryTextColor =
        isDark ? const Color(0xFFF7F7F7) : const Color(0xFF171717);
    final secondaryTextColor =
        isDark ? const Color(0xFFAAAAAA) : const Color(0xFF737373);

    const categories = <_SalonCategoryData>[
      _SalonCategoryData(
        title: 'الشعر',
        subtitle: 'قص، صبغ، معالج، سشوار وتسريحات',
        assetPath: 'assets/images/salon_hair.jpg',
      ),
      _SalonCategoryData(
        title: 'الأظافر',
        subtitle: 'جل، إدامة، تركيب وعناية متكاملة',
        assetPath: 'assets/images/salon_nails.jpg',
      ),
      _SalonCategoryData(
        title: 'المكياج',
        subtitle: 'إطلالات ناعمة وفخمة لكل مناسبة',
        assetPath: 'assets/images/salon_makeup.jpg',
      ),
      _SalonCategoryData(
        title: 'التسريحات',
        subtitle: 'تسريحات يومية ومناسبات وأعراس',
        assetPath: 'assets/images/salon_hairstyle.jpg',
      ),
      _SalonCategoryData(
        title: 'الرموش',
        subtitle: 'طرفية، كاملة، كثيفة وتقنيات متقدمة',
        assetPath: 'assets/images/salon_lashes.jpg',
      ),
      _SalonCategoryData(
        title: 'الحواجب',
        subtitle: 'فايبروز، نانو بروز، أومبري وعناية',
        assetPath: 'assets/images/salon_brows.jpg',
      ),
      _SalonCategoryData(
        title: 'بكجات العرايس',
        subtitle: 'بكجات متكاملة للحنة والعرس والمهر',
        assetPath: 'assets/images/salon_bridal.jpg',
      ),
    ];

    const posts = <_SalonPostData>[
      _SalonPostData(
        title: 'إطلالة جديدة',
        subtitle: 'أحدث أعمال الصالون',
        assetPath: 'assets/images/salon_post_1.jpg',
      ),
      _SalonPostData(
        title: 'بكجات مميزة',
        subtitle: 'اختيارات خاصة لكِ',
        assetPath: 'assets/images/salon_post_2.jpg',
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SalonHeader(
              title: 'الصالون',
              textColor: primaryTextColor,
              onBackPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed('home');
                }
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OffersBanner(
                      isDark: isDark,
                      imageAssetPath:
                          'assets/images/salon_offer_placeholder.jpg',
                      onTap: () {
                        _showComingSoon(context, 'العروض الحالية');
                      },
                    ),
                    const SizedBox(height: 22),
                    _SectionTitle(
                      title: 'آخر المنشورات',
                      textColor: primaryTextColor,
                    ),
                    const SizedBox(height: 12),
                    _LatestPostsSection(
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      posts: posts,
                      onPostTap: () {
                        _showComingSoon(context, 'تفاصيل المنشور');
                      },
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(
                      title: 'الخدمات',
                      textColor: primaryTextColor,
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(categories.length, (index) {
                      final category = categories[index];

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == categories.length - 1 ? 0 : 12,
                        ),
                        child: _SalonCategoryCard(
                          title: category.title,
                          subtitle: category.subtitle,
                          imageAssetPath: category.assetPath,
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () {
                            _showComingSoon(context, category.title);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _FixedBookingBar(
        isDark: isDark,
        backgroundColor: backgroundColor,
        onPressed: () {
          _showComingSoon(context, 'الحجز');
        },
      ),
    );
  }
}

class _SalonHeader extends StatelessWidget {
  const _SalonHeader({
    required this.title,
    required this.textColor,
    required this.onBackPressed,
  });

  final String title;
  final Color textColor;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          PositionedDirectional(
            start: 8,
            child: IconButton(
              tooltip: 'رجوع',
              onPressed: onBackPressed,
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                color: textColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersBanner extends StatelessWidget {
  const _OffersBanner({
    required this.isDark,
    required this.imageAssetPath,
    required this.onTap,
  });

  final bool isDark;
  final String imageAssetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 170,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF151515)
                : const Color(0xFFF5F1E9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.22 : 0.07,
                ),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imageAssetPath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return ColoredBox(
                      color: isDark
                          ? const Color(0xFF151515)
                          : const Color(0xFFF5F1E9),
                    );
                  },
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.black.withValues(
                          alpha: isDark ? 0.75 : 0.58,
                        ),
                        Colors.black.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'العروض الحالية',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'عروض مختارة لعنايتكِ وجمالكِ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'تابعي أحدث العروض والبكجات الخاصة بالصالون',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: 12.8,
                          height: 1.5,
                        ),
                      ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.textColor,
  });

  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _LatestPostsSection extends StatelessWidget {
  const _LatestPostsSection({
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.posts,
    required this.onPostTap,
  });

  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final List<_SalonPostData> posts;
  final VoidCallback onPostTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 164,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: posts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final post = posts[index];

          return SizedBox(
            width: 185,
            child: _PostCard(
              title: post.title,
              subtitle: post.subtitle,
              imageAssetPath: post.assetPath,
              isDark: isDark,
              surfaceColor: surfaceColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              onTap: onPostTap,
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.title,
    required this.subtitle,
    required this.imageAssetPath,
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageAssetPath;
  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.18 : 0.05,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Image.asset(
                      imageAssetPath,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.gold.withValues(
                            alpha: isDark ? 0.12 : 0.08,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_outlined,
                            color: AppColors.gold,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11.5,
                        ),
                      ),
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

class _SalonCategoryCard extends StatelessWidget {
  const _SalonCategoryCard({
    required this.title,
    required this.subtitle,
    required this.imageAssetPath,
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageAssetPath;
  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(21),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.16 : 0.045,
                ),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 74),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Image.asset(
                      imageAssetPath,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.gold.withValues(
                            alpha: isDark ? 0.14 : 0.09,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_outlined,
                            color: AppColors.gold,
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12.3,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark
                      ? const Color(0xFF8A8A8A)
                      : const Color(0xFF777777),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FixedBookingBar extends StatelessWidget {
  const _FixedBookingBar({
    required this.isDark,
    required this.backgroundColor,
    required this.onPressed,
  });

  final bool isDark;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        isDark ? const Color(0xFF202020) : const Color(0xFFECECEC);

    return Material(
      color: backgroundColor,
      elevation: 14,
      shadowColor: Colors.black.withValues(
        alpha: isDark ? 0.35 : 0.12,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: BorderSide(color: dividerColor),
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
                backgroundColor:
                    isDark ? AppColors.gold : AppColors.black,
                foregroundColor:
                    isDark ? AppColors.black : AppColors.lightGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SalonCategoryData {
  const _SalonCategoryData({
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });

  final String title;
  final String subtitle;
  final String assetPath;
}

class _SalonPostData {
  const _SalonPostData({
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });

  final String title;
  final String subtitle;
  final String assetPath;
}
