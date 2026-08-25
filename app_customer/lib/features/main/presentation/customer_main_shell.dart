import 'package:flutter/material.dart';

import '../../account/presentation/pages/account_page.dart';
import '../../chat/presentation/grand_layan_chat_page.dart';
import '../../favorites/presentation/pages/favorites_page.dart';
import '../../home/presentation/customer_home_page.dart';
import '../../offers/presentation/offers_page.dart';

class CustomerMainShell extends StatefulWidget {
  const CustomerMainShell({
    super.key,
  });

  @override
  State<CustomerMainShell> createState() =>
      _CustomerMainShellState();
}

class _CustomerMainShellState
    extends State<CustomerMainShell> {
  static const int _homeIndex = 0;
  static const int _favoritesIndex = 2;
  static const int _chatIndex = 3;

  int _selectedIndex = _homeIndex;

  /// آخر تبويب حقيقي قبل الدخول إلى المفضلة.
  int _lastNonFavoritesIndex = _homeIndex;

  /// الانتقال من أي مكان إلى الرئيسية.

  /// الرجوع من العروض إلى الصفحة الرئيسية.
  void _goBackFromOffers() {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedIndex = _homeIndex;
    });
  }

  /// الرجوع من المفضلة إلى آخر تبويب كان مفتوحًا.
  void _goBackFromFavorites() {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedIndex =
          _lastNonFavoritesIndex == _favoritesIndex
              ? _homeIndex
              : _lastNonFavoritesIndex;
    });
  }

  Future<void> _onNavigationTap(
    int index,
  ) async {
    /// المحادثة تفتح كصفحة مستقلة.
    if (index == _chatIndex) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const GrandLayanChatPage(
            showBackButton: true,
          ),
        ),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      /// عند الدخول للمفضلة نحفظ التبويب السابق.
      if (index == _favoritesIndex &&
          _selectedIndex != _favoritesIndex) {
        _lastNonFavoritesIndex = _selectedIndex;
      }

      /// أي تبويب غير المفضلة يصبح هو آخر تبويب صالح للرجوع.
      if (index != _favoritesIndex) {
        _lastNonFavoritesIndex = index;
      }

      _selectedIndex = index;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          /// 0 - الرئيسية
          const CustomerHomePage(
            showBottomNavigation: false,
          ),

          /// 1 - العروض
          OffersPage(
            onBack: _goBackFromOffers,
          ),

          /// 2 - المفضلة
          FavoritesPage(
            onBack: _goBackFromFavorites,
          ),

          /// 3 - المحادثة
          const SizedBox.shrink(),

          /// 4 - الحساب
          const AccountPage(),
        ],
      ),

      /// الشريط السفلي يبقى ظاهرًا داخل الـ Shell.
      bottomNavigationBar: _MainBottomNavigation(
        selectedIndex: _selectedIndex,
        isDark: isDark,
        onTap: _onNavigationTap,
      ),
    );
  }
}

class _MainBottomNavigation
    extends StatelessWidget {
  const _MainBottomNavigation({
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
  });

  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  static const List<_NavigationItem> _items =
      <_NavigationItem>[
    _NavigationItem(
      navigationIndex: 1,
      label: 'العروض',
      icon: Icons.local_offer_outlined,
      selectedIcon: Icons.local_offer_rounded,
    ),
    _NavigationItem(
      navigationIndex: 2,
      label: 'المفضلة',
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
    ),
    _NavigationItem(
      navigationIndex: 0,
      label: 'الرئيسية',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      isPrimary: true,
    ),
    _NavigationItem(
      navigationIndex: 3,
      label: 'المحادثة',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
    ),
    _NavigationItem(
      navigationIndex: 4,
      label: 'حسابي',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(
    BuildContext context,
  ) {
    final Color backgroundColor = isDark
        ? const Color(0xFF11100F)
        : const Color(0xFFFFFDFC);

    final Color dividerColor = isDark
        ? const Color(0xFF24211F)
        : const Color(0xFFEAE5E0);

    final Color selectedColor = isDark
        ? const Color(0xFFC9B19B)
        : const Color(0xFF8D705A);

    final Color inactiveColor = isDark
        ? const Color(0xFF77736F)
        : const Color(0xFF96908B);

    final Color primaryBackgroundColor = isDark
        ? const Color(0xFF28231F)
        : const Color(0xFFF0E7DF);

    return Material(
      color: backgroundColor,
      child: SafeArea(
        top: false,
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: BorderSide(
                color: dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: _items
                .map(
                  (_NavigationItem item) {
                    final bool isSelected =
                        selectedIndex ==
                            item.navigationIndex;

                    return Expanded(
                      child: InkWell(
                        onTap: () => onTap(
                          item.navigationIndex,
                        ),
                        child: SizedBox.expand(
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              item.isPrimary
                                  ? -8
                                  : 0,
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: <Widget>[
                                Container(
                                  width:
                                      item.isPrimary
                                          ? 50
                                          : 36,
                                  height:
                                      item.isPrimary
                                          ? 50
                                          : 36,
                                  decoration:
                                      item.isPrimary
                                          ? BoxDecoration(
                                              color:
                                                  primaryBackgroundColor,
                                              shape:
                                                  BoxShape.circle,
                                              border:
                                                  Border.all(
                                                color:
                                                    backgroundColor,
                                                width:
                                                    4,
                                              ),
                                            )
                                          : null,
                                  child: Icon(
                                    isSelected
                                        ? item
                                            .selectedIcon
                                        : item.icon,
                                    color: item.isPrimary
                                        ? selectedColor
                                        : isSelected
                                            ? selectedColor
                                            : inactiveColor,
                                    size:
                                        item.isPrimary
                                            ? 25
                                            : 23,
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      item.isPrimary
                                          ? 1
                                          : 2,
                                ),
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      TextStyle(
                                    color:
                                        isSelected
                                            ? selectedColor
                                            : inactiveColor,
                                    fontSize: 10.5,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight
                                                .w700
                                            : FontWeight
                                                .w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
                .toList(
                  growable: false,
                ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem({
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

