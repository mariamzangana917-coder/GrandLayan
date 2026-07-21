import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/luxury_theme_toggle.dart';
import '../../../core/theme/theme_mode_notifier.dart';
import '../../auth/providers/customer_auth_provider.dart';
import '../../../core/network/api_url.dart';

class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({
    super.key,
    this.customerName,
    this.customerAvatarUrl,
    this.showBottomNavigation = true,
  });

  /// اسم الزبونة القادم من بيانات تسجيل الدخول.
  /// الحقل اختياري حتى لا يتأثر أي استدعاء حالي للصفحة.
  final String? customerName;
  final bool showBottomNavigation;

  /// رابط صورة الزبونة القادمة من الـ API.
  /// إذا لم توجد صورة، يظهر رمز افتراضي مرتب.
  final String? customerAvatarUrl;

  @override
  ConsumerState<CustomerHomePage> createState() {
    return _CustomerHomePageState();
  }
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
  int _selectedIndex = 0;

  /*
   * تبقى النقطة مخفية حاليًا.
   * لاحقًا تظهر فقط عندما يكون لدى الزبونة إشعار غير مقروء.
   */
  bool get _hasUnreadNotifications => false;

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('صفحة $feature راح نكملها بالخطوة الجاية.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _onNavigationTap(int index) {
    if (!widget.showBottomNavigation) {
      return;
    }

    switch (index) {
      case 0:
        setState(() {
          _selectedIndex = 0;
        });
        break;

      case 1:
        _showComingSoon('العروض');
        break;

      case 2:
        _showComingSoon('المفضلة');
        break;

      case 3:
        context.pushNamed('ask-grand-layan');
        break;

      case 4:
        _showComingSoon('حسابي');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final authState = ref.watch(customerAuthProvider);

    final customer = authState.when(
      data: (value) => value,
      loading: () => null,
      error: (_, _) => null,
    );

    final customerName = customer?.name.isNotEmpty == true
        ? customer!.name
        : widget.customerName;

    final String? customerAvatarUrl = ApiUrl.resolveStorageUrl(
      customer?.avatar ?? widget.customerAvatarUrl,
    );

    final backgroundColor = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    final primaryTextColor = isDark
        ? const Color(0xFFF7F7F7)
        : const Color(0xFF171717);

    final secondaryTextColor = isDark
        ? const Color(0xFFAAAAAA)
        : const Color(0xFF727272);

    final surfaceColor = isDark
        ? const Color(0xFF0D0D0D)
        : const Color(0xFFFAF9F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: backgroundColor)),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HomeBackgroundPainter(isDark: isDark),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 690;

                final horizontalPadding = constraints.maxWidth < 380
                    ? 18.0
                    : 21.0;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    7,
                    horizontalPadding,
                    isCompact ? 9 : 13,
                  ),
                  child: Column(
                    children: [
                      _HomeTopBar(
                        textColor: primaryTextColor,
                        hasUnreadNotifications: _hasUnreadNotifications,
                        onNotificationsPressed: () {
                          _showComingSoon('الإشعارات');
                        },
                      ),

                      SizedBox(height: isCompact ? 8 : 11),

                      _WelcomeCard(
                        customerName: customerName,
                        customerAvatarUrl: customerAvatarUrl,
                        isDark: isDark,
                        surfaceColor: surfaceColor,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        isCompact: isCompact,
                      ),

                      SizedBox(height: isCompact ? 12 : 16),

                      _AskGrandLayanCard(
                        isDark: isDark,
                        surfaceColor: surfaceColor,
                        primaryTextColor: primaryTextColor,
                        isCompact: isCompact,
                        onTap: () {
                          context.pushNamed('ask-grand-layan');
                        },
                      ),

                      SizedBox(height: isCompact ? 16 : 21),

                      _SectionHeader(
                        title: 'اختاري القسم',
                        subtitle:
                            'كل ما تحتاجينه من العناية والجمال في مكان واحد',
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      ),

                      SizedBox(height: isCompact ? 9 : 12),

                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _DepartmentCard(
                                title: 'الصالون',
                                subtitle: 'الشعر، الأظافر، العناية والباقات',
                                icon: Icons.content_cut_rounded,
                                isDark: isDark,
                                surfaceColor: surfaceColor,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                                isCompact: isCompact,
                                onTap: () {
                                  context.pushNamed('salon');
                                },
                              ),
                            ),
                            SizedBox(height: isCompact ? 10 : 12),
                            Expanded(
                              child: _DepartmentCard(
                                title: 'العيادة',
                                subtitle: 'خدمات العناية والجمال المتخصصة',
                                icon: Icons.spa_outlined,
                                isDark: isDark,
                                surfaceColor: surfaceColor,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                                isCompact: isCompact,
                                onTap: () {
                                  context.pushNamed('clinic');
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNavigation
          ? _OfficialBottomNavigation(
              selectedIndex: _selectedIndex,
              isDark: isDark,
              onTap: _onNavigationTap,
            )
          : null,
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.textColor,
    required this.hasUnreadNotifications,
    required this.onNotificationsPressed,
  });

  final Color textColor;
  final bool hasUnreadNotifications;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          IconButton(
            tooltip: 'الإشعارات',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
            onPressed: onNotificationsPressed,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 27,
                  color: textColor,
                ),
                if (hasUnreadNotifications)
                  PositionedDirectional(
                    top: 0,
                    end: -1,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          const LuxuryThemeToggle(size: 34),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.customerName,
    required this.customerAvatarUrl,
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.isCompact,
  });

  final String? customerName;
  final String? customerAvatarUrl;
  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool isCompact;

  String get _displayName {
    final name = customerName?.trim();
    if (name == null || name.isEmpty) {
      return 'ضيفتنا الجميلة';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 17 : 20,
        isCompact ? 15 : 18,
        isCompact ? 17 : 20,
        isCompact ? 15 : 18,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: isDark ? 0.40 : 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.055),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: isCompact ? 54 : 60,
              height: isCompact ? 54 : 60,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 1.4),
              ),
              child: ClipOval(
                child: _CustomerAvatar(
                  imageUrl: customerAvatarUrl,
                  isDark: isDark,
                ),
              ),
            ),
            SizedBox(width: isCompact ? 13 : 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أهلًا بكِ، $_displayName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: isCompact ? 18 : 20,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'اختاري تجربتكِ ودعي جمالكِ يبدأ مع كراند ليان',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: isCompact ? 11.8 : 12.7,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({required this.imageUrl, required this.isDark});

  final String? imageUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();

    if (normalizedUrl == null || normalizedUrl.isEmpty) {
      return Container(
        color: AppColors.gold.withValues(alpha: isDark ? 0.16 : 0.10),
        alignment: Alignment.center,
        child: const Icon(
          Icons.person_rounded,
          color: AppColors.gold,
          size: 29,
        ),
      );
    }

    return Image.network(
      normalizedUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.gold.withValues(alpha: isDark ? 0.16 : 0.10),
          alignment: Alignment.center,
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.gold,
            size: 29,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: AppColors.gold.withValues(alpha: isDark ? 0.12 : 0.08),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: AppColors.gold,
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  final String title;
  final String subtitle;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: secondaryTextColor, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: AppColors.gold,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _AskGrandLayanCard extends StatelessWidget {
  const _AskGrandLayanCard({
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.isCompact,
    required this.onTap,
  });

  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? const Color(0xFF1A1715)
        : const Color(0xFFF3ECE6);

    final iconBackgroundColor = isDark
        ? const Color(0xFF2B2520)
        : const Color(0xFFE5D8CD);

    final accentColor = isDark
        ? const Color(0xFFD0B89F)
        : const Color(0xFF91725B);

    final textColor = isDark
        ? const Color(0xFFF4F0EC)
        : const Color(0xFF302A26);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: isCompact ? 66 : 72,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF302B27) : const Color(0xFFE8DED6),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Container(
                  width: isCompact ? 42 : 46,
                  height: isCompact ? 42 : 46,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'اسأل كراند ليان',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: textColor,
                      fontSize: isCompact ? 15.8 : 16.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.search_rounded, color: accentColor, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.isCompact,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Ink(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: isDark ? 0.36 : 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                blurRadius: 17,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 14 : 17,
              vertical: isCompact ? 12 : 15,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Container(
                    width: isCompact ? 58 : 64,
                    height: isCompact ? 58 : 64,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(
                        alpha: isDark ? 0.16 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.gold,
                      size: isCompact ? 28 : 31,
                    ),
                  ),
                  SizedBox(width: isCompact ? 14 : 17),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: isCompact ? 19 : 21,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: isCompact ? 11.2 : 12.2,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: isCompact ? 34 : 38,
                    height: isCompact ? 34 : 38,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(
                        alpha: isDark ? 0.14 : 0.09,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.gold,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfficialBottomNavigation extends StatelessWidget {
  const _OfficialBottomNavigation({
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
  });

  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  static const List<_BottomNavigationItem> _items = [
    _BottomNavigationItem(
      navigationIndex: 1,
      label: 'العروض',
      icon: Icons.local_offer_outlined,
      selectedIcon: Icons.local_offer_rounded,
    ),
    _BottomNavigationItem(
      navigationIndex: 2,
      label: 'المفضلة',
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
    ),
    _BottomNavigationItem(
      navigationIndex: 0,
      label: 'الرئيسية',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      isPrimary: true,
    ),
    _BottomNavigationItem(
      navigationIndex: 3,
      label: 'المحادثة',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
    ),
    _BottomNavigationItem(
      navigationIndex: 4,
      label: 'حسابي',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? const Color(0xFF0C0C0C)
        : const Color(0xFFFFFFFF);

    final dividerColor = isDark
        ? const Color(0xFF202020)
        : const Color(0xFFECECEC);

    return Material(
      color: backgroundColor,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(top: BorderSide(color: dividerColor, width: 1)),
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = selectedIndex == item.navigationIndex;

              final inactiveColor = isDark
                  ? const Color(0xFF858585)
                  : const Color(0xFF777777);

              return Expanded(
                child: InkWell(
                  onTap: () {
                    onTap(item.navigationIndex);
                  },
                  child: SizedBox.expand(
                    child: Transform.translate(
                      offset: Offset(0, item.isPrimary ? -10 : 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: item.isPrimary ? 52 : 34,
                            height: item.isPrimary ? 52 : 34,
                            decoration: item.isPrimary
                                ? BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: backgroundColor,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold.withValues(
                                          alpha: isDark ? 0.23 : 0.30,
                                        ),
                                        blurRadius: 17,
                                        offset: const Offset(0, 7),
                                      ),
                                    ],
                                  )
                                : null,
                            child: Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              color: item.isPrimary
                                  ? const Color(0xFF171717)
                                  : isSelected
                                  ? AppColors.gold
                                  : inactiveColor,
                              size: item.isPrimary ? 25 : 24,
                            ),
                          ),
                          SizedBox(height: item.isPrimary ? 2 : 1),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.gold
                                  : inactiveColor,
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavigationItem {
  const _BottomNavigationItem({
    required this.navigationIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.isPrimary = false,
  });

  final int navigationIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isPrimary;
}

class _HomeBackgroundPainter extends CustomPainter {
  const _HomeBackgroundPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: isDark ? 0.045 : 0.028)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    for (var index = 0; index < 3; index++) {
      final topPath = Path()
        ..moveTo(size.width * 0.62, -20 + index * 10)
        ..cubicTo(
          size.width * 0.78,
          size.height * 0.03,
          size.width * 0.94,
          size.height * 0.02,
          size.width + 25,
          size.height * 0.11 + index * 12,
        );

      canvas.drawPath(topPath, paint);
    }

    for (var index = 0; index < 3; index++) {
      final bottomPath = Path()
        ..moveTo(-25, size.height * (0.83 + index * 0.02))
        ..cubicTo(
          size.width * 0.21,
          size.height * (0.77 + index * 0.018),
          size.width * 0.45,
          size.height * (0.91 + index * 0.01),
          size.width * 0.68,
          size.height + 18,
        );

      canvas.drawPath(bottomPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HomeBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
