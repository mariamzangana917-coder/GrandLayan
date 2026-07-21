import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OffersBanner extends StatelessWidget {
  const OffersBanner({
    required this.onTap,
    super.key,
    this.imageAssetPath = 'assets/images/salon_offer_placeholder.jpg',
  });

  final VoidCallback onTap;
  final String imageAssetPath;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 170,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F1E9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
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
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return ColoredBox(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
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
                        Colors.black.withValues(alpha: isDark ? 0.78 : 0.60),
                        Colors.black.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(22),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'العروض الحالية',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'عروض مختارة لعنايتكِ وجمالكِ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'تابعي أحدث العروض والبكجات الخاصة بالصالون',
                        style: TextStyle(
                          color: Color(0xFFD6D6D6),
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
