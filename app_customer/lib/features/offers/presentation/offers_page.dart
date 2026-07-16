import 'package:flutter/material.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  int _selectedFilterIndex = 0;

  static const List<String> _filters = [
    'الكل',
    'العروض',
    'البكجات',
    'الكوبونات',
    'بطاقات الهدايا',
  ];

  static const List<_OfferItemData> _items = [
    _OfferItemData(
      type: _OfferType.offer,
      title: 'عرض العناية المتكاملة',
      description: 'مجموعة مختارة من خدمات الصالون ضمن عرض خاص.',
      imageAssetPath: 'assets/images/offer_salon_1.jpg',
      badge: 'عرض',
      valueText: 'خصم 20%',
      detailsText: 'لفترة محدودة',
    ),
    _OfferItemData(
      type: _OfferType.offer,
      title: 'عرض نضارة البشرة',
      description: 'جلسات عناية مختارة من خدمات العيادة.',
      imageAssetPath: 'assets/images/offer_clinic_1.jpg',
      badge: 'عرض',
      valueText: 'خصم 15%',
      detailsText: 'حسب توفر المواعيد',
    ),
    _OfferItemData(
      type: _OfferType.package,
      title: 'بكج العروس',
      description: 'تجربة متكاملة للحنة والعرس بخدمات مختارة.',
      imageAssetPath: 'assets/images/package_bride_1.jpg',
      badge: 'بكج',
      valueText: 'ابتداءً من 350 ألف',
      detailsText: 'متوفر حاليًا',
    ),
    _OfferItemData(
      type: _OfferType.coupon,
      title: 'كوبون ترحيبي',
      description: 'يُستخدم عند تأكيد الحجز لأول مرة.',
      imageAssetPath: 'assets/images/coupon_welcome.jpg',
      badge: 'كوبون',
      valueText: 'WELCOME20',
      detailsText: 'استخدام واحد فقط',
    ),
    _OfferItemData(
      type: _OfferType.giftCard,
      title: 'بطاقة هدية كراند ليان',
      description: 'أهدي شخصًا تحبينه تجربة عناية وجمال مميزة.',
      imageAssetPath: 'assets/images/gift_card_1.jpg',
      badge: 'هدية',
      valueText: 'اختاري القيمة',
      detailsText: 'تُطبق عليها الشروط',
    ),
  ];

  List<_OfferItemData> get _filteredItems {
    switch (_selectedFilterIndex) {
      case 1:
        return _items.where((item) => item.type == _OfferType.offer).toList();
      case 2:
        return _items.where((item) => item.type == _OfferType.package).toList();
      case 3:
        return _items.where((item) => item.type == _OfferType.coupon).toList();
      case 4:
        return _items.where((item) => item.type == _OfferType.giftCard).toList();
      default:
        return _items;
    }
  }

  void _showTemporaryMessage(String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('تفاصيل $title راح نربطها بالبيانات الحقيقية.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF050505) : const Color(0xFFFDFCFB);
    final surfaceColor = isDark ? const Color(0xFF121110) : const Color(0xFFFFFFFF);
    final primaryTextColor = isDark ? const Color(0xFFF5F2EF) : const Color(0xFF28231F);
    final secondaryTextColor = isDark ? const Color(0xFFA29C97) : const Color(0xFF77716C);
    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _OffersHeader(
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _OffersFilters(
              filters: _filters,
              selectedIndex: _selectedFilterIndex,
              isDark: isDark,
              onSelected: (index) => setState(() => _selectedFilterIndex = index),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredItems.isEmpty
                  ? _EmptyOffersState(
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                      itemCount: filteredItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _OfferCard(
                          item: item,
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _showTemporaryMessage(item.title),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OffersHeader extends StatelessWidget {
  const _OffersHeader({
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  final Color primaryTextColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'العروض والهدايا',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'اختيارات مميزة وتجارب مصممة لكِ',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF8D705A).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Color(0xFF8D705A),
                size: 23,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OffersFilters extends StatelessWidget {
  const _OffersFilters({
    required this.filters,
    required this.selectedIndex,
    required this.isDark,
    required this.onSelected,
  });

  final List<String> filters;
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedColor = isDark ? const Color(0xFFC9B19B) : const Color(0xFF8D705A);
    final selectedBackground = isDark ? const Color(0xFF2A2521) : const Color(0xFFEDE3DA);
    final inactiveBackground = isDark ? const Color(0xFF151413) : const Color(0xFFF3F0ED);
    final inactiveText = isDark ? const Color(0xFF9A9591) : const Color(0xFF77716C);

    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? selectedBackground : inactiveBackground,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: isSelected ? selectedColor : inactiveText,
                  fontSize: 12.2,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.item,
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
  });

  final _OfferItemData item;
  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? const Color(0xFFC9B19B) : const Color(0xFF8D705A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.045),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 172,
                      child: Image.asset(
                        item.imageAssetPath,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: isDark
                                    ? const [Color(0xFF211D1A), Color(0xFF121110)]
                                    : const [Color(0xFFEDE4DC), Color(0xFFF8F4F1)],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(_typeIcon(item.type), color: accentColor, size: 42),
                          );
                        },
                      ),
                    ),
                    PositionedDirectional(
                      top: 14,
                      start: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          item.badge,
                          style: const TextStyle(
                            color: Color(0xFFF0DDD0),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.valueText,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.description,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12.6,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(_typeIcon(item.type), color: accentColor, size: 17),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                item.detailsText,
                                style: TextStyle(color: secondaryTextColor, fontSize: 11.7),
                              ),
                            ),
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: isDark ? const Color(0xFF827C77) : const Color(0xFF88817B),
                              size: 15,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(_OfferType type) {
    switch (type) {
      case _OfferType.offer:
        return Icons.local_offer_outlined;
      case _OfferType.package:
        return Icons.inventory_2_outlined;
      case _OfferType.coupon:
        return Icons.confirmation_number_outlined;
      case _OfferType.giftCard:
        return Icons.card_giftcard_rounded;
    }
  }
}

class _EmptyOffersState extends StatelessWidget {
  const _EmptyOffersState({
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? const Color(0xFFC9B19B) : const Color(0xFF8D705A);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.local_offer_outlined, color: accentColor, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد عناصر حاليًا',
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'ستظهر هنا العناصر التي تضيفها المديرة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryTextColor, fontSize: 12.8),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OfferType { offer, package, coupon, giftCard }

class _OfferItemData {
  const _OfferItemData({
    required this.type,
    required this.title,
    required this.description,
    required this.imageAssetPath,
    required this.badge,
    required this.valueText,
    required this.detailsText,
  });

  final _OfferType type;
  final String title;
  final String description;
  final String imageAssetPath;
  final String badge;
  final String valueText;
  final String detailsText;
}
