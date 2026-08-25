import 'package:flutter/material.dart';

import '../../offers/presentation/offers_screen.dart';
import 'coupons_screen.dart';

class PromotionManagementScreen extends StatelessWidget {
  const PromotionManagementScreen({required this.isDarkMode, super.key});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final _PromotionColors colors = _PromotionColors.from(isDarkMode);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 18,
          title: Text(
            'العروض والكوبونات',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _MessageCard(colors: colors),
                const SizedBox(height: 14),
                Expanded(
                  child: _ManagementCard(
                    key: const ValueKey<String>('promotion-offers-card'),
                    title: 'إدارة العروض',
                    subtitle:
                        'إنشاء وتحديث المحتوى الترويجي والصور ومواعيد العرض.',
                    smallLabel: 'العروض',
                    icon: Icons.local_offer_outlined,
                    colors: colors,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OffersScreen(isDarkMode: isDarkMode),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _ManagementCard(
                    key: const ValueKey<String>('promotion-coupons-card'),
                    title: 'إدارة الكوبونات',
                    subtitle:
                        'إدارة أكواد الخصم والشروط وحدود الاستخدام بنظام واضح.',
                    smallLabel: 'الكوبونات',
                    icon: Icons.confirmation_number_outlined,
                    colors: colors,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CouponsScreen(isDarkMode: isDarkMode),
                        ),
                      );
                    },
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.colors});

  final _PromotionColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.shadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'اختاري نوع الإدارة للمتابعة.',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 13.2,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.softAccent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: Color(0xFFB89552),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.title,
    required this.subtitle,
    required this.smallLabel,
    required this.icon,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final String smallLabel;
  final IconData icon;
  final _PromotionColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.softAccent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            smallLabel,
                            style: const TextStyle(
                              color: Color(0xFF9B7738),
                              fontSize: 11.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.softSurface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFFB89552),
                        size: 25,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.65,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: colors.softSurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'فتح الإدارة',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 13.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_left_rounded,
                        color: colors.primaryText,
                        size: 22,
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

class _PromotionColors {
  const _PromotionColors({
    required this.background,
    required this.surface,
    required this.softSurface,
    required this.softAccent,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color softSurface;
  final Color softAccent;
  final Color border;
  final Color primaryText;
  final Color secondaryText;
  final Color shadow;

  factory _PromotionColors.from(bool isDark) {
    return _PromotionColors(
      background: isDark ? const Color(0xFF101011) : const Color(0xFFF8F7F4),
      surface: isDark ? const Color(0xFF181819) : Colors.white,
      softSurface: isDark ? const Color(0xFF232220) : const Color(0xFFFBF7EE),
      softAccent: isDark ? const Color(0xFF2C261D) : const Color(0xFFF2E7D2),
      border: isDark ? const Color(0xFF2A2A2D) : const Color(0xFFE7DFD3),
      primaryText: isDark ? const Color(0xFFF3F1EC) : const Color(0xFF1C1B18),
      secondaryText: isDark ? const Color(0xFFB9B2A8) : const Color(0xFF6C665E),
      shadow: isDark
          ? Colors.black.withValues(alpha: 0.16)
          : const Color(0xFFC4AD7A).withValues(alpha: 0.08),
    );
  }
}
