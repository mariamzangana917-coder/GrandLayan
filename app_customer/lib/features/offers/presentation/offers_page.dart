import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/network/api_exception.dart';
import '../../catalog/data/models/catalog_item.dart';
import '../../catalog/data/repositories/catalog_repository.dart';
import '../data/customer_offer.dart';
import '../data/customer_offer_repository.dart';

typedef OfferBookingHandler = Future<void> Function(
  BuildContext context,
  CatalogItem item,
  CustomerOffer offer,
);

class OffersPage extends StatefulWidget {
  const OffersPage({
    this.department,
    this.repository,
    this.catalogRepository,
    this.onBookOffer,
    this.onBack,
    super.key,
  });

  final String? department;
  final CustomerOfferRepository? repository;
  final CatalogRepository? catalogRepository;

  /// إذا كان الحجز يحتاج offer_id استخدمي هذا الـ handler.
  /// إذا لم يتم تمريره، سيتم فتح مسار الحجز الحالي مع CatalogItem.
  final OfferBookingHandler? onBookOffer;

  /// الرجوع من صفحة العروض إلى التبويب السابق.
  final VoidCallback? onBack;

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  static const Color _gold = Color(0xFFC9A227);

  late final CustomerOfferRepository _repository;
  late final CatalogRepository _catalogRepository;

  List<CustomerOffer> _offers = <CustomerOffer>[];

  /// ربط offer.id بـ CatalogItem الكامل.
  Map<int, CatalogItem> _catalogItemsByOfferId =
      <int, CatalogItem>{};

  String? _department;
  String? _errorMessage;

  int? _bookingOfferId;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _repository =
        widget.repository ?? CustomerOfferApiRepository();

    _catalogRepository =
        widget.catalogRepository ?? CatalogRepository();

    _department = widget.department;

    _loadOffers();
  }

  // ===========================================================================
  // Loading
  // ===========================================================================

  Future<void> _loadOffers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<CustomerOffer> offers =
          await _repository.fetchOffers(
        department: _department,
      );

      final Map<int, CatalogItem> catalogItems =
          await _loadCatalogItemsForOffers(offers);

      if (!mounted) {
        return;
      }

      setState(() {
        _offers = offers;
        _catalogItemsByOfferId = catalogItems;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'تعذر تحميل العروض حاليًا. حاولي مرة ثانية.';
        _isLoading = false;
      });
    }
  }

  Future<Map<int, CatalogItem>> _loadCatalogItemsForOffers(
    List<CustomerOffer> offers,
  ) async {
    final Map<int, CatalogItem> items =
        <int, CatalogItem>{};

    await Future.wait(
      offers.map(
        (CustomerOffer offer) async {
          final int? catalogItemId =
              offer.catalogItem?.id;

          if (catalogItemId == null ||
              catalogItemId <= 0) {
            return;
          }

          try {
            final CatalogItem item =
                await _catalogRepository.getCatalogItem(
              catalogItemId,
            );

            items[offer.id] = item;
          } catch (_) {
            // العرض يبقى ظاهرًا حتى لو تعذر تحميل
            // بيانات الخدمة أو البكج.
          }
        },
      ),
    );

    return items;
  }

  Future<void> _selectDepartment(
    String? department,
  ) async {
    if (_department == department || _isLoading) {
      return;
    }

    setState(() {
      _department = department;
    });

    await _loadOffers();
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  String _formatDate(DateTime value) {
    return intl.DateFormat(
      'dd/MM/yyyy',
      'ar',
    ).format(value.toLocal());
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.w500,
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ===========================================================================
  // Booking
  // ===========================================================================

  Future<CatalogItem?> _loadBookableItem(
    CustomerOffer offer,
  ) async {
    final int? catalogItemId =
        offer.catalogItem?.id;

    if (catalogItemId == null ||
        catalogItemId <= 0) {
      _showMessage(
        'هذا العرض غير مرتبط بخدمة أو بكج قابل للحجز حاليًا.',
      );
      return null;
    }

    try {
      return await _catalogRepository.getCatalogItem(
        catalogItemId,
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
      return null;
    } catch (_) {
      _showMessage(
        'تعذر فتح الحجز حاليًا. حاولي مرة ثانية.',
      );
      return null;
    }
  }

  Future<void> _navigateToBooking({
    required CatalogItem item,
    required CustomerOffer offer,
  }) async {
    final OfferBookingHandler? handler =
        widget.onBookOffer;

    if (handler != null) {
      await handler(
        context,
        item,
        offer,
      );
      return;
    }

    if (!mounted) {
      return;
    }

    context.pushNamed(
      'booking',
      extra: item,
    );
  }

  Future<void> _bookOffer(
    CustomerOffer offer,
  ) async {
    if (_bookingOfferId != null) {
      return;
    }

    setState(() {
      _bookingOfferId = offer.id;
    });

    try {
      final CatalogItem? item =
          await _loadBookableItem(offer);

      if (item == null || !mounted) {
        return;
      }

      await _navigateToBooking(
        item: item,
        offer: offer,
      );
    } finally {
      if (mounted) {
        setState(() {
          _bookingOfferId = null;
        });
      }
    }
  }

  // ===========================================================================
  // Offer details
  // ===========================================================================

  Future<void> _showOfferDetails(
    CustomerOffer offer,
  ) async {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final _OffersPalette palette =
        _OffersPalette.fromBrightness(isDark);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .52),
      builder: (BuildContext sheetContext) {
        return _OfferDetailsSheet(
          offer: offer,
          catalogItem:
              _catalogItemsByOfferId[offer.id],
          palette: palette,
          startDateText:
              _formatDate(offer.startsAt),
          endDateText:
              _formatDate(offer.endsAt),
          onBook: () async {
            final CatalogItem? item =
                await _loadBookableItem(offer);

            if (item == null || !mounted) {
              return;
            }

            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }

            await _navigateToBooking(
              item: item,
              offer: offer,
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // UI
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final _OffersPalette palette =
        _OffersPalette.fromBrightness(isDark);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          bottom: false,
          child: _buildBody(palette),
        ),
      ),
    );
  }

  Widget _buildBody(
    _OffersPalette palette,
  ) {
    // Loading
    if (_isLoading) {
      return Column(
        children: <Widget>[
          _PageHeader(
            palette: palette,
            onBack: widget.onBack,
          ),
          _DepartmentSelector(
            selectedDepartment: _department,
            palette: palette,
            onSelected: _selectDepartment,
          ),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: _gold,
                strokeWidth: 2.2,
              ),
            ),
          ),
        ],
      );
    }

    // Error
    if (_errorMessage != null) {
      return Column(
        children: <Widget>[
          _PageHeader(
            palette: palette,
            onBack: widget.onBack,
          ),
          _DepartmentSelector(
            selectedDepartment: _department,
            palette: palette,
            onSelected: _selectDepartment,
          ),
          Expanded(
            child: _OffersErrorState(
              message: _errorMessage!,
              palette: palette,
              onRetry: _loadOffers,
            ),
          ),
        ],
      );
    }

    // Empty
    if (_offers.isEmpty) {
      return RefreshIndicator(
        color: _gold,
        onRefresh: _loadOffers,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _PageHeader(
                palette: palette,
                onBack: widget.onBack,
              ),
            ),
            SliverToBoxAdapter(
              child: _DepartmentSelector(
                selectedDepartment: _department,
                palette: palette,
                onSelected: _selectDepartment,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyOffersState(
                palette: palette,
              ),
            ),
          ],
        ),
      );
    }

    final List<CustomerOffer> bookableOffers =
        _offers
            .where(
              (CustomerOffer offer) =>
                  offer.catalogItem != null,
            )
            .toList(growable: false);

    return RefreshIndicator(
      color: _gold,
      onRefresh: _loadOffers,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _PageHeader(
              palette: palette,
              onBack: widget.onBack,
            ),
          ),

          SliverToBoxAdapter(
            child: _DepartmentSelector(
              selectedDepartment: _department,
              palette: palette,
              onSelected: _selectDepartment,
            ),
          ),

          // خدمات وبكجات عليها عروض
          if (bookableOffers.isNotEmpty) ...<Widget>[
            SliverToBoxAdapter(
              child: _SectionTitle(
                title: 'خدمات وبكجات عليها عرض',
                subtitle:
                    'اختاري الخدمة وانتقلي للحجز مباشرة',
                palette: palette,
              ),
            ),
            SliverToBoxAdapter(
              child: _DiscountedServicesCarousel(
                offers: bookableOffers,
                palette: palette,
                bookingOfferId: _bookingOfferId,
                catalogItemsByOfferId:
                    _catalogItemsByOfferId,
                onTap: _bookOffer,
              ),
            ),
          ],

          // جميع العروض
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: 'العروض الحالية',
              subtitle:
                  'اضغطي على الصورة حتى تشوفين التفاصيل',
              palette: palette,
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              18,
              0,
              18,
              30,
            ),
            sliver: SliverList.separated(
              itemCount: _offers.length,
              separatorBuilder:
                  (BuildContext context, int index) {
                return const SizedBox(height: 14);
              },
              itemBuilder:
                  (BuildContext context, int index) {
                final CustomerOffer offer =
                    _offers[index];

                return _OfferImageCard(
                  offer: offer,
                  palette: palette,
                  onTap: () =>
                      _showOfferDetails(offer),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Header
// =============================================================================

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.palette,
    this.onBack,
  });

  final _OffersPalette palette;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        20,
        10,
      ),
      child: Row(
        children: <Widget>[
          if (onBack != null) ...<Widget>[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBack,
                borderRadius:
                    BorderRadius.circular(14),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: palette.primaryText,
                    size: 19,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'العروض',
                  style: GoogleFonts.tajawal(
                    color: palette.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اختيارات مميزة من كراند ليان',
                  style: GoogleFonts.tajawal(
                    color: palette.secondaryText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.goldSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              color: _OffersPageState._gold,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Department selector
// =============================================================================

class _DepartmentSelector extends StatelessWidget {
  const _DepartmentSelector({
    required this.selectedDepartment,
    required this.palette,
    required this.onSelected,
  });

  final String? selectedDepartment;
  final _OffersPalette palette;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        12,
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: palette.border,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(
                alpha: palette.isDark ? .16 : .035,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _DepartmentButton(
                label: 'الكل',
                icon: Icons.grid_view_rounded,
                isSelected:
                    selectedDepartment == null,
                palette: palette,
                onTap: () => onSelected(null),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _DepartmentButton(
                label: 'الصالون',
                icon: Icons.auto_awesome_rounded,
                isSelected:
                    selectedDepartment == 'salon',
                palette: palette,
                onTap: () =>
                    onSelected('salon'),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _DepartmentButton(
                label: 'العيادة',
                icon: Icons.spa_outlined,
                isSelected:
                    selectedDepartment == 'clinic',
                palette: palette,
                onTap: () =>
                    onSelected('clinic'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentButton extends StatelessWidget {
  const _DepartmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final _OffersPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 48,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: <Color>[
                      _OffersPageState._gold,
                      Color(0xFFB68C18),
                    ],
                  )
                : null,
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : palette.secondaryText,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.tajawal(
                  color: isSelected
                      ? Colors.white
                      : palette.primaryText,
                  fontSize: 12.5,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Section title
// =============================================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  final String title;
  final String subtitle;
  final _OffersPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        12,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: GoogleFonts.tajawal(
              color: palette.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.tajawal(
              color: palette.secondaryText,
              fontSize: 10.8,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Discounted services carousel
// =============================================================================

class _DiscountedServicesCarousel
    extends StatelessWidget {
  const _DiscountedServicesCarousel({
    required this.offers,
    required this.palette,
    required this.bookingOfferId,
    required this.catalogItemsByOfferId,
    required this.onTap,
  });

  final List<CustomerOffer> offers;
  final _OffersPalette palette;
  final int? bookingOfferId;

  final Map<int, CatalogItem>
      catalogItemsByOfferId;

  final ValueChanged<CustomerOffer> onTap;

  @override
  Widget build(BuildContext context) {
    final double screenWidth =
        MediaQuery.sizeOf(context).width;

    final double cardWidth =
        (screenWidth * .46)
            .clamp(164.0, 190.0)
            .toDouble();

    return SizedBox(
      height: 318,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
        ),
        itemCount: offers.length,
        separatorBuilder:
            (BuildContext context, int index) {
          return const SizedBox(width: 12);
        },
        itemBuilder:
            (BuildContext context, int index) {
          final CustomerOffer offer =
              offers[index];

          return SizedBox(
            width: cardWidth,
            child: _DiscountedServiceCard(
              offer: offer,
              palette: palette,
              catalogItem:
                  catalogItemsByOfferId[
                      offer.id],
              isLoading:
                  bookingOfferId == offer.id,
              onTap: () => onTap(offer),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Discounted service card
// =============================================================================

class _DiscountedServiceCard
    extends StatelessWidget {
  const _DiscountedServiceCard({
    required this.offer,
    required this.palette,
    required this.catalogItem,
    required this.isLoading,
    required this.onTap,
  });

  final CustomerOffer offer;
  final _OffersPalette palette;
  final CatalogItem? catalogItem;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String title =
        catalogItem?.name ??
        offer.catalogItem?.name ??
        offer.title;

    final String? description =
        catalogItem?.description
                    ?.trim()
                    .isNotEmpty ==
                true
            ? catalogItem!.description!.trim()
            : offer.description
                    ?.trim();

    final String? serviceImageUrl =
        catalogItem?.primaryImageUrl ??
        offer.imageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.zero,
        child: Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                _OffersPageState._gold
                    .withValues(alpha: .65),
                _OffersPageState._gold
                    .withValues(alpha: .25),
                Colors.transparent,
              ],
            ),
          ),
          child: Container(
            clipBehavior:
                Clip.antiAlias,
            decoration: BoxDecoration(
              color: palette.surface,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color:
                      Colors.black.withValues(
                    alpha: palette.isDark
                        ? .16
                        : .045,
                  ),
                  blurRadius: 12,
                  offset:
                      const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      _NetworkOfferImage(
                        imageUrl:
                            serviceImageUrl,
                        palette: palette,
                        fit: BoxFit.cover,
                      ),

                      Positioned.fill(
                        child: DecoratedBox(
                          decoration:
                              BoxDecoration(
                            gradient:
                                LinearGradient(
                              begin:
                                  Alignment.topCenter,
                              end:
                                  Alignment.bottomCenter,
                              colors:
                                  <Color>[
                                Colors.transparent,
                                Colors.black
                                    .withValues(
                                        alpha: .04),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (offer.valueText
                              ?.trim()
                              .isNotEmpty ==
                          true)
                        PositionedDirectional(
                          start: 10,
                          bottom: 10,
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration:
                                BoxDecoration(
                              color: Colors.black
                                  .withValues(
                                      alpha: .58),
                            ),
                            child: Text(
                              offer.valueText!
                                  .trim(),
                              style:
                                  GoogleFonts
                                      .tajawal(
                                color:
                                    Colors.white,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),
                        ),

                      if (isLoading)
                        ColoredBox(
                          color: Colors.black
                              .withValues(
                                  alpha: .28),
                          child:
                              const Center(
                            child: SizedBox(
                              width: 25,
                              height: 25,
                              child:
                                  CircularProgressIndicator(
                                color: Colors
                                    .white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  flex: 28,
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      13,
                      10,
                      13,
                      11,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              GoogleFonts.tajawal(
                            color:
                                palette.primaryText,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        if (description != null &&
                            description.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                GoogleFonts.tajawal(
                              color:
                                  palette.secondaryText,
                              fontSize: 10.5,
                              fontWeight:
                                  FontWeight.w300,
                            ),
                          ),
                        ],

                        const Spacer(),

                        Row(
                          children: <Widget>[
                            Text(
                              'احجزي العرض',
                              style:
                                  GoogleFonts
                                      .tajawal(
                                color:
                                    _OffersPageState
                                        ._gold,
                                fontSize: 11.5,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            const Icon(
                              Icons
                                  .arrow_back_rounded,
                              color:
                                  _OffersPageState
                                      ._gold,
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
}

// =============================================================================
// Offer image card
// =============================================================================

class _OfferImageCard
    extends StatelessWidget {
  const _OfferImageCard({
    required this.offer,
    required this.palette,
    required this.onTap,
  });

  final CustomerOffer offer;
  final _OffersPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 1.62,
          child: Container(
            clipBehavior:
                Clip.antiAlias,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius:
                  BorderRadius.circular(10),
              border: Border.all(
                color: palette.border,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color:
                      Colors.black.withValues(
                    alpha: palette.isDark
                        ? .18
                        : .05,
                  ),
                  blurRadius: 16,
                  offset:
                      const Offset(0, 6),
                ),
              ],
            ),
            child: _NetworkOfferImage(
              imageUrl: offer.imageUrl,
              palette: palette,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Offer details
// =============================================================================

class _OfferDetailsSheet
    extends StatefulWidget {
  const _OfferDetailsSheet({
    required this.offer,
    required this.catalogItem,
    required this.palette,
    required this.startDateText,
    required this.endDateText,
    required this.onBook,
  });

  final CustomerOffer offer;
  final CatalogItem? catalogItem;
  final _OffersPalette palette;
  final String startDateText;
  final String endDateText;
  final Future<void> Function() onBook;

  @override
  State<_OfferDetailsSheet> createState() =>
      _OfferDetailsSheetState();
}

class _OfferDetailsSheetState
    extends State<_OfferDetailsSheet> {
  bool _isBooking = false;

  Future<void> _book() async {
    if (_isBooking) {
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      await widget.onBook();
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  bool _isUpcoming(
    CustomerOffer offer,
  ) {
    return DateTime.now().isBefore(
      offer.startsAt.toLocal(),
    );
  }

  bool _isExpired(
    CustomerOffer offer,
  ) {
    return DateTime.now().isAfter(
      offer.endsAt.toLocal(),
    );
  }

  bool _isActive(
    CustomerOffer offer,
  ) {
    final DateTime now =
        DateTime.now();

    return !now.isBefore(
          offer.startsAt.toLocal(),
        ) &&
        !now.isAfter(
          offer.endsAt.toLocal(),
        );
  }

  String _statusText(
    CustomerOffer offer,
  ) {
    if (_isUpcoming(offer)) {
      return 'قريبًا';
    }

    if (_isExpired(offer)) {
      return 'منتهي';
    }

    return 'متوفر الآن';
  }

  IconData _statusIcon(
    CustomerOffer offer,
  ) {
    if (_isUpcoming(offer)) {
      return Icons.upcoming_outlined;
    }

    if (_isExpired(offer)) {
      return Icons.event_busy_outlined;
    }

    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final CustomerOffer offer =
        widget.offer;

    final _OffersPalette palette =
        widget.palette;

    final bool canBook =
        _isActive(offer) &&
        offer.catalogItem != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context)
                    .height *
                .88,
      ),
      margin:
          const EdgeInsets.fromLTRB(
        10,
        0,
        10,
        10,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: palette.border,
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: SingleChildScrollView(
        physics:
            const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1.55,
              child: _NetworkOfferImage(
                imageUrl: offer.imageUrl,
                palette: palette,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                20,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _OfferInfoChip(
                        icon: Icons
                            .workspace_premium_rounded,
                        label: offer.badgeText
                                    ?.trim()
                                    .isNotEmpty ==
                                true
                            ? offer.badgeText!
                                .trim()
                            : 'VIP',
                        palette: palette,
                        highlighted: true,
                      ),
                      _OfferInfoChip(
                        icon:
                            _statusIcon(offer),
                        label:
                            _statusText(offer),
                        palette: palette,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (offer.valueText
                          ?.trim()
                          .isNotEmpty ==
                      true) ...<Widget>[
                    Text(
                      offer.valueText!.trim(),
                      style:
                          GoogleFonts.tajawal(
                        color:
                            _OffersPageState
                                ._gold,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                  ],

                  Text(
                    offer.title,
                    style:
                        GoogleFonts.tajawal(
                      color:
                          palette.primaryText,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w600,
                      height: 1.3,
                    ),
                  ),

                  if (offer.description
                          ?.trim()
                          .isNotEmpty ==
                      true) ...<Widget>[
                    const SizedBox(height: 9),
                    Text(
                      offer.description!.trim(),
                      style:
                          GoogleFonts.tajawal(
                        color:
                            palette.secondaryText,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w300,
                        height: 1.65,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  _DetailRow(
                    icon: Icons
                        .storefront_outlined,
                    text:
                        'القسم: ${offer.department.name}',
                    palette: palette,
                  ),

                  if (offer.catalogItem !=
                      null) ...<Widget>[
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: offer
                                  .catalogItem!
                                  .type ==
                              'package'
                          ? Icons
                              .inventory_2_outlined
                          : Icons
                              .spa_outlined,
                      text:
                          '${offer.catalogItem!.type == 'package' ? 'البكج' : 'الخدمة'}: ${offer.catalogItem!.name}',
                      palette: palette,
                    ),
                  ],

                  const SizedBox(height: 10),

                  _DetailRow(
                    icon: Icons
                        .date_range_outlined,
                    text:
                        'من ${widget.startDateText} إلى ${widget.endDateText}',
                    palette: palette,
                  ),

                  if (widget.catalogItem
                          ?.durationMinutes !=
                      null) ...<Widget>[
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons
                          .schedule_outlined,
                      text:
                          'المدة: ${widget.catalogItem!.durationMinutes} دقيقة',
                      palette: palette,
                    ),
                  ],

                  if (widget.catalogItem !=
                      null) ...<Widget>[
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons
                          .payments_outlined,
                      text:
                          'السعر الأساسي: ${widget.catalogItem!.displayPrice}',
                      palette: palette,
                    ),
                  ],

                  if (offer.detailsText
                          ?.trim()
                          .isNotEmpty ==
                      true) ...<Widget>[
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons
                          .info_outline_rounded,
                      text:
                          offer.detailsText!
                              .trim(),
                      palette: palette,
                    ),
                  ],

                  const SizedBox(height: 22),

                  Row(
                    children: <Widget>[
                      Expanded(
                        child:
                            OutlinedButton(
                          onPressed: _isBooking
                              ? null
                              : () =>
                                  Navigator.of(
                                    context,
                                  ).pop(),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                palette
                                    .primaryText,
                            side: BorderSide(
                              color:
                                  palette
                                      .border,
                            ),
                            minimumSize:
                                const Size
                                    .fromHeight(
                              48,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                          ),
                          child: Text(
                            'إلغاء',
                            style:
                                GoogleFonts
                                    .tajawal(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        flex: 2,
                        child:
                            FilledButton(
                          onPressed:
                              _isBooking ||
                                      !canBook
                                  ? null
                                  : _book,
                          style:
                              FilledButton
                                  .styleFrom(
                            backgroundColor:
                                _OffersPageState
                                    ._gold,
                            foregroundColor:
                                Colors.white,
                            disabledBackgroundColor:
                                _OffersPageState
                                    ._gold
                                    .withValues(
                                        alpha: .35),
                            minimumSize:
                                const Size
                                    .fromHeight(
                              48,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                          ),
                          child: _isBooking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    color:
                                        Colors
                                            .white,
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : Text(
                                  !canBook &&
                                          _isExpired(
                                            offer,
                                          )
                                      ? 'العرض منتهي'
                                      : !canBook &&
                                              _isUpcoming(
                                                offer,
                                              )
                                          ? 'سيصبح متاحًا قريبًا'
                                          : !canBook
                                              ? 'غير قابل للحجز'
                                              : 'احجزي الآن',
                                  textAlign:
                                      TextAlign
                                          .center,
                                  style:
                                      GoogleFonts
                                          .tajawal(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
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

// =============================================================================
// Info chip
// =============================================================================

class _OfferInfoChip
    extends StatelessWidget {
  const _OfferInfoChip({
    required this.icon,
    required this.label,
    required this.palette,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final _OffersPalette palette;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? palette.goldSoft
            : palette.background,
        border: Border.all(
          color: highlighted
              ? _OffersPageState._gold
              : palette.border,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 15,
            color: highlighted
                ? _OffersPageState._gold
                : palette.secondaryText,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style:
                GoogleFonts.tajawal(
              color: highlighted
                  ? _OffersPageState._gold
                  : palette.primaryText,
              fontSize: 11.5,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Detail row
// =============================================================================

class _DetailRow
    extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.text,
    required this.palette,
  });

  final IconData icon;
  final String text;
  final _OffersPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 30,
          height: 30,
          decoration:
              BoxDecoration(
            color:
                palette.goldSoft,
            borderRadius:
                BorderRadius.circular(
              9,
            ),
          ),
          child: Icon(
            icon,
            color:
                _OffersPageState._gold,
            size: 16,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(
              top: 6,
            ),
            child: Text(
              text,
              style:
                  GoogleFonts.tajawal(
                color:
                    palette.primaryText,
                fontSize: 11.7,
                fontWeight:
                    FontWeight.w400,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Network image
// =============================================================================

class _NetworkOfferImage
    extends StatelessWidget {
  const _NetworkOfferImage({
    required this.imageUrl,
    required this.palette,
    required this.fit,
  });

  final String? imageUrl;
  final _OffersPalette palette;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final String? normalizedUrl =
        imageUrl?.trim();

    if (normalizedUrl == null ||
        normalizedUrl.isEmpty) {
      return _placeholder();
    }

    return Image.network(
      normalizedUrl,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      filterQuality:
          FilterQuality.high,
      loadingBuilder: (
        BuildContext context,
        Widget child,
        ImageChunkEvent?
            loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _placeholder(),
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child:
                    CircularProgressIndicator(
                  color:
                      _OffersPageState
                          ._gold,
                  strokeWidth: 2,
                ),
              ),
            ),
          ],
        );
      },
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin:
              Alignment.topRight,
          end:
              Alignment.bottomLeft,
          colors: palette.isDark
              ? const <Color>[
                  Color(0xFF24211D),
                  Color(0xFF151412),
                ]
              : const <Color>[
                  Color(0xFFF0E9DF),
                  Color(0xFFFBF8F4),
                ],
        ),
      ),
      alignment:
          Alignment.center,
      child: Icon(
        Icons
            .local_offer_outlined,
        color:
            _OffersPageState
                ._gold
                .withValues(alpha: .75),
        size: 36,
      ),
    );
  }
}

// =============================================================================
// Error state
// =============================================================================

class _OffersErrorState
    extends StatelessWidget {
  const _OffersErrorState({
    required this.message,
    required this.palette,
    required this.onRetry,
  });

  final String message;
  final _OffersPalette palette;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 62,
              height: 62,
              decoration:
                  BoxDecoration(
                color:
                    palette.goldSoft,
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .cloud_off_outlined,
                color:
                    _OffersPageState
                        ._gold,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.tajawal(
                color:
                    palette.primaryText,
                fontSize: 13,
                fontWeight:
                    FontWeight.w400,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons
                    .refresh_rounded,
                size: 18,
              ),
              label: Text(
                'إعادة المحاولة',
                style:
                    GoogleFonts.tajawal(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
              style:
                  TextButton.styleFrom(
                foregroundColor:
                    _OffersPageState
                        ._gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Empty state
// =============================================================================

class _EmptyOffersState
    extends StatelessWidget {
  const _EmptyOffersState({
    required this.palette,
  });

  final _OffersPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 66,
              height: 66,
              decoration:
                  BoxDecoration(
                color:
                    palette.goldSoft,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: const Icon(
                Icons
                    .local_offer_outlined,
                color:
                    _OffersPageState
                        ._gold,
                size: 30,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'لا توجد عروض متاحة حاليًا',
              style:
                  GoogleFonts.tajawal(
                color:
                    palette.primaryText,
                fontSize: 15,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ستظهر العروض هنا تلقائيًا عند تفعيلها من الإدارة.',
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.tajawal(
                color:
                    palette.secondaryText,
                fontSize: 11.5,
                fontWeight:
                    FontWeight.w300,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Palette
// =============================================================================

class _OffersPalette {
  const _OffersPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.primaryText,
    required this.secondaryText,
    required this.border,
    required this.goldSoft,
  });

  final bool isDark;
  final Color background;
  final Color surface;
  final Color primaryText;
  final Color secondaryText;
  final Color border;
  final Color goldSoft;

  factory _OffersPalette.fromBrightness(
    bool isDark,
  ) {
    if (isDark) {
      return const _OffersPalette(
        isDark: true,
        background:
            Color(0xFF121212),
        surface:
            Color(0xFF1E1E1E),
        primaryText:
            Color(0xFFEAEAEA),
        secondaryText:
            Color(0xFF9CA3AF),
        border:
            Color(0xFF2A2A2A),
        goldSoft:
            Color(0x26C9A227),
      );
    }

    return const _OffersPalette(
      isDark: false,
      background:
          Color(0xFFF5F5F5),
      surface:
          Colors.white,
      primaryText:
          Color(0xFF1C1C1C),
      secondaryText:
          Color(0xFF6B7280),
      border:
          Color(0xFFE5E7EB),
      goldSoft:
          Color(0x1FC9A227),
    );
  }
}