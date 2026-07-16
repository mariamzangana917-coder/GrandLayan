import 'package:flutter/material.dart';

import '../../home/presentation/customer_home_page.dart';
import '../../offers/presentation/offers_page.dart';

class CustomerMainShell extends StatefulWidget {
  const CustomerMainShell({super.key});

  @override
  State<CustomerMainShell> createState() => _CustomerMainShellState();
}

class _CustomerMainShellState extends State<CustomerMainShell> {
  int _selectedIndex = 0;
  
void _onNavigationTap(int index) {
  setState(() {
    _selectedIndex = index;
  });
}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          CustomerHomePage(showBottomNavigation: false),
          OffersPage(),
          _TemporaryMainPage(
            title: 'المفضلة',
            description: 'ستظهر هنا الخدمات والبكجات التي حفظتِها في المفضلة.',
            icon: Icons.favorite_border_rounded,
          ),
          _TemporaryMainPage(
            title: 'المحادثة',
            description: 'التواصل المباشر مع خدمة عملاء كراند ليان.',
            icon: Icons.chat_bubble_outline_rounded,
          ),
          _TemporaryMainPage(
            title: 'حسابي',
            description: 'بياناتكِ، مواعيدكِ، فواتيركِ وإعدادات الحساب.',
            icon: Icons.person_outline_rounded,
          ),
        ],
      ),
      bottomNavigationBar: _MainBottomNavigation(
        selectedIndex: _selectedIndex,
        isDark: isDark,
        onTap: _onNavigationTap,
      ),
    );
  }
}

class _TemporaryMainPage extends StatelessWidget {
  const _TemporaryMainPage({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF050505) : const Color(0xFFFDFCFB);
    final surfaceColor = isDark ? const Color(0xFF121110) : const Color(0xFFF5F1ED);
    final primaryTextColor = isDark ? const Color(0xFFF5F3F1) : const Color(0xFF26221F);
    final secondaryTextColor = isDark ? const Color(0xFF9A9691) : const Color(0xFF77716C);
    final accentColor = isDark ? const Color(0xFFC9B19B) : const Color(0xFF8D705A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 58,
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: isDark ? 0.14 : 0.10),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(icon, color: accentColor, size: 34),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13,
                            height: 1.6,
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
    );
  }
}

class _MainBottomNavigation extends StatelessWidget {
  const _MainBottomNavigation({
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
  });

  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  static const List<_NavigationItem> _items = [
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
  Widget build(BuildContext context) {
    final backgroundColor = isDark ? const Color(0xFF11100F) : const Color(0xFFFFFDFC);
    final dividerColor = isDark ? const Color(0xFF24211F) : const Color(0xFFEAE5E0);
    final selectedColor = isDark ? const Color(0xFFC9B19B) : const Color(0xFF8D705A);
    final inactiveColor = isDark ? const Color(0xFF77736F) : const Color(0xFF96908B);
    final primaryBackgroundColor = isDark ? const Color(0xFF28231F) : const Color(0xFFF0E7DF);

    return Material(
      color: backgroundColor,
      child: SafeArea(
        top: false,
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(top: BorderSide(color: dividerColor, width: 1)),
          ),
          child: Row(
            children: _items.map((item) {
              final isSelected = selectedIndex == item.navigationIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(item.navigationIndex),
                  child: SizedBox.expand(
                    child: Transform.translate(
                      offset: Offset(0, item.isPrimary ? -8 : 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: item.isPrimary ? 50 : 36,
                            height: item.isPrimary ? 50 : 36,
                            decoration: item.isPrimary
                                ? BoxDecoration(
                                    color: primaryBackgroundColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: backgroundColor, width: 4),
                                  )
                                : null,
                            child: Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              color: item.isPrimary
                                  ? selectedColor
                                  : isSelected
                                      ? selectedColor
                                      : inactiveColor,
                              size: item.isPrimary ? 25 : 23,
                            ),
                          ),
                          SizedBox(height: item.isPrimary ? 1 : 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? selectedColor : inactiveColor,
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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
