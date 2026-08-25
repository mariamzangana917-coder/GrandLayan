import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_url.dart';
import '../../../core/theme/theme_mode_notifier.dart';
import '../../auth/providers/customer_auth_provider.dart';
import '../../banners/presentation/customer_banner_carousel.dart';

class _CustomerHomePalette {
  const _CustomerHomePalette._();

  static const Color lightBackground = Color(0xFFFFFEFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSoftSurface = Color(0xFFF8F1DD);
  static const Color lightTopGold = Color(0xFFE4C568);
  static const Color lightTopCream = Color(0xFFF6EAC7);
  static const Color lightAccent = Color(0xFFC49A2E);
  static const Color lightAccentDark = Color(0xFF9A7420);
  static const Color lightPrimaryText = Color(0xFF29251D);
  static const Color lightSecondaryText = Color(0xFF777063);
  static const Color lightBorder = Color(0xFFE8DEC4);

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1D1D1D);
  static const Color darkSoftSurface = Color(0xFF27231A);
  static const Color darkTopGold = Color(0xFF6B5422);
  static const Color darkTopCream = Color(0xFF29251C);
  static const Color darkAccent = Color(0xFFD8B653);
  static const Color darkAccentDark = Color(0xFFB58B2B);
  static const Color darkPrimaryText = Color(0xFFF4F0E7);
  static const Color darkSecondaryText = Color(0xFFB6B0A4);
  static const Color darkBorder = Color(0xFF3A352B);

  static Color background(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  static Color surface(bool isDark) =>
      isDark ? darkSurface : lightSurface;

  static Color softSurface(bool isDark) =>
      isDark ? darkSoftSurface : lightSoftSurface;

  static Color topGold(bool isDark) =>
      isDark ? darkTopGold : lightTopGold;

  static Color topCream(bool isDark) =>
      isDark ? darkTopCream : lightTopCream;

  static Color accent(bool isDark) =>
      isDark ? darkAccent : lightAccent;

  static Color accentDark(bool isDark) =>
      isDark ? darkAccentDark : lightAccentDark;

  static Color primaryText(bool isDark) =>
      isDark ? darkPrimaryText : lightPrimaryText;

  static Color secondaryText(bool isDark) =>
      isDark ? darkSecondaryText : lightSecondaryText;

  static Color border(bool isDark) =>
      isDark ? darkBorder : lightBorder;
}

class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({
    super.key,
    this.customerName,
    this.customerAvatarUrl,
    this.showBottomNavigation = true,
  });

  final String? customerName;
  final String? customerAvatarUrl;
  final bool showBottomNavigation;

  @override
  ConsumerState<CustomerHomePage> createState() =>
      _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
  int _selectedIndex = 0;

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'صفحة $feature راح نكملها بالخطوة الجاية.',
          ),
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
        setState(() => _selectedIndex = 0);
        break;

      case 1:
        context.pushNamed('offers');
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
    final isDark =
        ref.watch(themeModeProvider) == ThemeMode.dark;

    final authState = ref.watch(customerAuthProvider);

    final customer = authState.when(
      data: (value) => value,
      loading: () => null,
      error: (_, _) => null,
    );

    final customerName = customer?.name.isNotEmpty == true
        ? customer!.name
        : widget.customerName;

    final customerAvatarUrl = ApiUrl.resolveStorageUrl(
      customer?.avatar ?? widget.customerAvatarUrl,
    );

    final backgroundColor =
        _CustomerHomePalette.background(isDark);

    final surfaceColor =
        _CustomerHomePalette.surface(isDark);

    final softSurfaceColor =
        _CustomerHomePalette.softSurface(isDark);

    final accentColor =
        _CustomerHomePalette.accent(isDark);

    final accentDarkColor =
        _CustomerHomePalette.accentDark(isDark);

    final primaryTextColor =
        _CustomerHomePalette.primaryText(isDark);

    final secondaryTextColor =
        _CustomerHomePalette.secondaryText(isDark);

    final borderColor =
        _CustomerHomePalette.border(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: backgroundColor,
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 390,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _CustomerHomePalette.topGold(isDark),
                      _CustomerHomePalette.topCream(isDark),
                      backgroundColor,
                    ],
                    stops: const [
                      0.0,
                      0.58,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    14,
                    18,
                    30,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 560,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            _WelcomeHeader(
                              customerName: customerName,
                              customerAvatarUrl:
                                  customerAvatarUrl,
                              isDark: isDark,
                              accentColor: accentColor,
                              primaryTextColor:
                                  primaryTextColor,
                              isCompact: false,
                            ),

                            const SizedBox(height: 24),

                            const CustomerBannerCarousel(
                              placement: 'home',
                              aspectRatio: 1.58,
                            ),

                            const SizedBox(height: 30),

                            _SectionHeading(
                              title: 'اختر نوع الخدمة',
                              subtitle:
                                  'اختاري القسم المناسب لاحتياجك',
                              primaryTextColor:
                                  primaryTextColor,
                              secondaryTextColor:
                                  secondaryTextColor,
                            ),

                            const SizedBox(height: 15),

                            // الصالون
                            _DepartmentCard(
                              title: 'صالون',
                              subtitle:
                                  'جمالك وأناقتك في مكان واحد',
                              icon: Icons.content_cut_rounded,
                              isDark: isDark,
                              surfaceColor:
                                  softSurfaceColor,
                              accentColor: accentColor,
                              accentDarkColor:
                                  accentDarkColor,
                              primaryTextColor:
                                  primaryTextColor,
                              secondaryTextColor:
                                  secondaryTextColor,
                              borderColor: borderColor,
                              onTap: () =>
                                  context.pushNamed('salon'),
                            ),

                            const SizedBox(height: 13),

                            // العيادة
                            _DepartmentCard(
                              title: 'عيادة',
                              subtitle:
                                  'خدمات العناية والجمال الطبي',
                              icon:
                                  Icons.health_and_safety_outlined,
                              isDark: isDark,
                              surfaceColor:
                                  softSurfaceColor,
                              accentColor: accentColor,
                              accentDarkColor:
                                  accentDarkColor,
                              primaryTextColor:
                                  primaryTextColor,
                              secondaryTextColor:
                                  secondaryTextColor,
                              borderColor: borderColor,
                              onTap: () =>
                                  context.pushNamed('clinic'),
                            ),

                            const SizedBox(height: 16),

                            // اسأل كراند ليان - بوكس مستقل في النهاية
                            _AskGrandLayanCard(
                              isDark: isDark,
                              accentColor: accentColor,
                              accentDarkColor:
                                  accentDarkColor,
                              primaryTextColor:
                                  primaryTextColor,
                              secondaryTextColor:
                                  secondaryTextColor,
                              onTap: () => context.pushNamed(
                                'ask-grand-layan',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.customerName,
    required this.customerAvatarUrl,
    required this.isDark,
    required this.accentColor,
    required this.primaryTextColor,
    required this.isCompact,
  });

  final String? customerName;
  final String? customerAvatarUrl;
  final bool isDark;
  final Color accentColor;
  final Color primaryTextColor;
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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: isCompact ? 72 : 82,
            height: isCompact ? 72 : 82,
            child: ClipOval(
              child: _CustomerAvatar(
                imageUrl: customerAvatarUrl,
                isDark: isDark,
                accentColor: accentColor,
              ),
            ),
          ),

          SizedBox(
            width: isCompact ? 14 : 18,
          ),

          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحبا $_displayName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.tajawal(
                      color: primaryTextColor,
                      fontSize: isCompact ? 22 : 24,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    'أهلاً بكِ هنا .....',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.tajawal(
                      color: isDark
                          ? const Color(0xFFD8B653)
                          : const Color(0xFF9A7420),
                      fontSize: isCompact ? 12.5 : 13.5,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({
    required this.imageUrl,
    required this.isDark,
    required this.accentColor,
  });

  final String? imageUrl;
  final bool isDark;
  final Color accentColor;

  Widget _fallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(
              alpha: isDark ? 0.28 : 0.18,
            ),
            accentColor.withValues(
              alpha: isDark ? 0.10 : 0.06,
            ),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: accentColor,
          size: 36,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();

    if (normalizedUrl == null ||
        normalizedUrl.isEmpty) {
      return _fallback();
    }

    return Image.network(
      normalizedUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
      loadingBuilder: (
        context,
        child,
        progress,
      ) {
        if (progress == null) {
          return child;
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: accentColor.withValues(
              alpha: isDark ? 0.12 : 0.07,
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: accentColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: GoogleFonts.tajawal(
              color: primaryTextColor,
              fontSize: 19,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.right,
              style: GoogleFonts.tajawal(
                color: secondaryTextColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ],
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
    required this.accentColor,
    required this.accentDarkColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final Color surfaceColor;
  final Color accentColor;
  final Color accentDarkColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? const Color(0xFF211F1A)
        : Colors.white;

    final iconSurface = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF8F1DD);

    final arrowSurface = isDark
        ? Colors.white.withValues(alpha: 0.055)
        : const Color(0xFFF7F3E8);

    return SizedBox(
      height: 112,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor.withValues(
                  alpha: isDark ? 0.70 : 0.65,
                ),
                width: 1,
              ),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: iconSurface,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: isDark
                            ? accentColor
                            : accentDarkColor,
                        size: 27,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.tajawal(
                              color: primaryTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: GoogleFonts.tajawal(
                              color: isDark
                                  ? secondaryTextColor
                                  : const Color(0xFF777063),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: arrowSurface,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: isDark
                            ? accentColor
                            : accentDarkColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AskGrandLayanCard extends StatelessWidget {
  const _AskGrandLayanCard({
    required this.isDark,
    required this.accentColor,
    required this.accentDarkColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
  });

  final bool isDark;
  final Color accentColor;
  final Color accentDarkColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? const Color(0xFF211F1A)
        : Colors.white;

    final accentSoft = accentColor.withValues(
      alpha: isDark ? 0.10 : 0.08,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 82,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(
                alpha: isDark ? 0.28 : 0.18,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.17 : 0.045,
                ),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accentSoft,
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: isDark
                          ? accentColor
                          : accentDarkColor,
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اسأل كراند ليان',
                          style: GoogleFonts.tajawal(
                            color: primaryTextColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'اسألي عن خدماتنا واختاري الأنسب لكِ',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            color: secondaryTextColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: accentSoft,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: isDark
                          ? accentColor
                          : accentDarkColor,
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

class _OfficialBottomNavigation
    extends StatelessWidget {
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
    final backgroundColor =
        _CustomerHomePalette.surface(isDark);

    final accentColor =
        _CustomerHomePalette.accent(isDark);

    final dividerColor = isDark
        ? const Color(0xFF303030)
        : const Color(0xFFECE4D0);

    final inactiveColor = isDark
        ? const Color(0xFF99958D)
        : const Color(0xFF777166);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          height: 74,
          margin: const EdgeInsets.fromLTRB(
            14,
            0,
            14,
            10,
          ),
          decoration: BoxDecoration(
            color: backgroundColor.withValues(
              alpha: isDark ? 0.97 : 0.98,
            ),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              color: dividerColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.32 : 0.11,
                ),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Row(
              children:
                  List.generate(_items.length, (index) {
                final item = _items[index];

                final isSelected =
                    selectedIndex ==
                        item.navigationIndex;

                return Expanded(
                  child: InkWell(
                    onTap: () =>
                        onTap(item.navigationIndex),
                    child: SizedBox.expand(
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          item.isPrimary ? -7 : 0,
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration:
                                  const Duration(
                                milliseconds: 220,
                              ),
                              curve: Curves.easeOut,
                              width: item.isPrimary
                                  ? 49
                                  : 34,
                              height: item.isPrimary
                                  ? 49
                                  : 34,
                              decoration:
                                  item.isPrimary
                                      ? BoxDecoration(
                                          color: isSelected
                                              ? accentColor
                                              : accentColor
                                                  .withValues(
                                                  alpha:
                                                      0.10,
                                                ),
                                          shape:
                                              BoxShape.circle,
                                          border:
                                              Border.all(
                                            color:
                                                backgroundColor,
                                            width: 4,
                                          ),
                                          boxShadow:
                                              isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color:
                                                            accentColor.withValues(
                                                          alpha:
                                                              0.30,
                                                        ),
                                                        blurRadius:
                                                            16,
                                                        offset:
                                                            const Offset(
                                                          0,
                                                          6,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                        )
                                      : null,
                              child: Icon(
                                isSelected
                                    ? item.selectedIcon
                                    : item.icon,
                                color: item.isPrimary &&
                                        isSelected
                                    ? Colors.white
                                    : isSelected
                                        ? accentColor
                                        : inactiveColor,
                                size: item.isPrimary
                                    ? 23
                                    : 22,
                              ),
                            ),
                            SizedBox(
                              height:
                                  item.isPrimary ? 0 : 1,
                            ),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: GoogleFonts.tajawal(
                                color: isSelected
                                    ? accentColor
                                    : inactiveColor,
                                fontSize: 10.2,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
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