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
          content: Text('صفحة $feature راح نكملها ونربطها بالبيانات الحقيقية.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final surfaceColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAF9F7);
    final primaryTextColor = isDark ? const Color(0xFFF7F7F7) : const Color(0xFF171717);
    final secondaryTextColor = isDark ? const Color(0xFFAAAAAA) : const Color(0xFF737373);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _SalonHeader(
              title: 'الصالون',
              textColor: primaryTextColor,
              onBackPressed: () {
                if (context.canPop()) context.pop();
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
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      onTap: () => _showComingSoon(context, 'العروض الحالية'),
                    ),
                    const SizedBox(height: 16),
                    _BookNowButton(
                      isDark: isDark,
                      onPressed: () => _showComingSoon(context, 'الحجز'),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'آخر المنشورات', textColor: primaryTextColor),
                    const SizedBox(height: 12),
                    _LatestPostsSection(
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      onPostTap: () => _showComingSoon(context, 'تفاصيل المنشور'),
                    ),
                    const SizedBox(height: 26),
                    _SectionTitle(title: 'الخدمات', textColor: primaryTextColor),
                    const SizedBox(height: 12),
                    ...[
                      ('الشعر', 'قص، صبغ، معالج، سشوار وتسريحات', Icons.content_cut_rounded),
                      ('الأظافر', 'جل، إدامة، تركيب وعناية متكاملة', Icons.back_hand_outlined),
                      ('المكياج', 'إطلالات ناعمة وفخمة لكل مناسبة', Icons.brush_outlined),
                      ('التسريحات', 'تسريحات يومية ومناسبات وأعراس', Icons.auto_awesome_outlined),
                      ('الرموش', 'طرفية، كاملة، كثيفة وتقنيات متقدمة', Icons.remove_red_eye_outlined),
                      ('الحواجب', 'فايبروز، نانو بروز، أومبري وعناية', Icons.face_retouching_natural_outlined),
                      ('بكجات العرايس', 'بكجات متكاملة للحنة والعرس والمهر', Icons.diamond_outlined),
                    ].expand((item) sync* {
                      yield _SalonCategoryCard(
                        title: item.$1,
                        subtitle: item.$2,
                        icon: item.$3,
                        isDark: isDark,
                        surfaceColor: surfaceColor,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () => _showComingSoon(context, item.$1),
                      );
                      yield const SizedBox(height: 12);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalonHeader extends StatelessWidget {
  const _SalonHeader({required this.title, required this.textColor, required this.onBackPressed});
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
              style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          PositionedDirectional(
            start: 8,
            child: IconButton(
              tooltip: 'رجوع',
              onPressed: onBackPressed,
              icon: Icon(Icons.arrow_forward_ios_rounded, color: textColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersBanner extends StatelessWidget {
  const _OffersBanner({required this.isDark, required this.primaryTextColor, required this.secondaryTextColor, required this.onTap});
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 166,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? const [Color(0xFF191919), Color(0xFF0C0C0C)]
                  : const [Color(0xFFF7F0E3), Color(0xFFFFFFFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('العروض الحالية', style: TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text('عروض مختارة لعنايتكِ وجمالكِ', style: TextStyle(color: primaryTextColor, fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
                      const SizedBox(height: 7),
                      Text('تابعي أحدث العروض والبكجات الخاصة بالصالون', style: TextStyle(color: secondaryTextColor, fontSize: 12.8, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: isDark ? 0.17 : 0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.local_offer_outlined, color: AppColors.gold, size: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookNowButton extends StatelessWidget {
  const _BookNowButton({required this.isDark, required this.onPressed});
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.calendar_month_outlined, size: 22),
        label: const Text('احجزي الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isDark ? AppColors.gold : AppColors.black,
          foregroundColor: isDark ? AppColors.black : AppColors.lightGold,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.textColor});
  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w800));
  }
}

class _LatestPostsSection extends StatelessWidget {
  const _LatestPostsSection({required this.isDark, required this.surfaceColor, required this.primaryTextColor, required this.secondaryTextColor, required this.onPostTap});
  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onPostTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 152,
      child: Row(
        children: [
          Expanded(
            child: _PostCard(
              title: 'إطلالة جديدة',
              subtitle: 'أحدث أعمال الصالون',
              icon: Icons.photo_camera_outlined,
              isDark: isDark,
              surfaceColor: surfaceColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              onTap: onPostTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PostCard(
              title: 'بكجات مميزة',
              subtitle: 'اختيارات خاصة لكِ',
              icon: Icons.auto_awesome_outlined,
              isDark: isDark,
              surfaceColor: surfaceColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              onTap: onPostTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.title, required this.subtitle, required this.icon, required this.isDark, required this.surfaceColor, required this.primaryTextColor, required this.secondaryTextColor, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
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
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.gold, size: 22),
              ),
              const Spacer(),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: primaryTextColor, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: secondaryTextColor, fontSize: 11.8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalonCategoryCard extends StatelessWidget {
  const _SalonCategoryCard({required this.title, required this.subtitle, required this.icon, required this.isDark, required this.surfaceColor, required this.primaryTextColor, required this.secondaryTextColor, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(21),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.045),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: isDark ? 0.15 : 0.09),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: AppColors.gold, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: primaryTextColor, fontSize: 16.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: secondaryTextColor, fontSize: 12.3, height: 1.45)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? const Color(0xFF8A8A8A) : const Color(0xFF777777),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
