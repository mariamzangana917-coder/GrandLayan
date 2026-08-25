import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../data/admin_offer.dart';
import '../data/offer_repository.dart';
import 'offer_form_screen.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({
    required this.isDarkMode,
    this.repository = const OfferApiRepository(),
    super.key,
  });

  final bool isDarkMode;
  final OfferRepository repository;

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<AdminOffer> _offers = <AdminOffer>[];

  Timer? _searchDebounce;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _lastPage = 1;
  String? _department;
  String? _availability;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOffers({bool append = false}) async {
    if (append) {
      if (_isLoadingMore || _currentPage >= _lastPage) {
        return;
      }

      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final AdminOfferPage page = await widget.repository.fetchOffers(
        search: _searchController.text.trim(),
        department: _department,
        availability: _availability,
        page: append ? _currentPage + 1 : 1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (!append) {
          _offers.clear();
        }

        _offers.addAll(page.items);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'تعذر تحميل العروض.';
      });
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 450), _loadOffers);
  }

  Future<void> _openForm([AdminOffer? offer]) async {
    final AdminOffer? result = await Navigator.of(context).push<AdminOffer>(
      MaterialPageRoute<AdminOffer>(
        builder: (_) => OfferFormScreen(
          isDarkMode: widget.isDarkMode,
          offer: offer,
          repository: widget.repository,
        ),
      ),
    );

    if (result != null && mounted) {
      await _loadOffers();
    }
  }

  Future<void> _toggleActive(AdminOffer offer) async {
    try {
      await widget.repository.updateOffer(
        offerId: offer.id,
        fields: <String, dynamic>{'is_active': !offer.isActive},
      );

      if (mounted) {
        await _loadOffers();
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    }
  }

  Future<void> _confirmDelete(AdminOffer offer) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف العرض'),
            content: Text(
              'هل تريدين حذف عرض "${offer.title}"؟ '
              'سيختفي من تطبيق الزبونة أيضًا.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD84A4A),
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.repository.deleteOffer(offer.id);

      if (!mounted) {
        return;
      }

      _showMessage('تم حذف العرض.');
      await _loadOffers();
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _OfferColors colors = _OfferColors.from(widget.isDarkMode);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: colors.background,
          foregroundColor: colors.primaryText,
          title: const Text(
            'إدارة العروض',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          backgroundColor: widget.isDarkMode
              ? const Color(0xFFD3B06B)
              : const Color(0xFF171717),
          foregroundColor: widget.isDarkMode ? Colors.black : Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'إضافة عرض',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: Column(
          children: <Widget>[
            _buildFilters(colors),
            Expanded(child: _buildBody(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(_OfferColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: TextStyle(color: colors.primaryText),
            decoration: InputDecoration(
              hintText: 'ابحثي باسم العرض',
              hintStyle: TextStyle(color: colors.secondaryText),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colors.secondaryText,
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        _loadOffers();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFB89552),
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _filterChip(
                  label: 'الكل',
                  selected: _availability == null,
                  colors: colors,
                  onTap: () => _setAvailability(null),
                ),
                _filterChip(
                  label: 'الحالية',
                  selected: _availability == 'current',
                  colors: colors,
                  onTap: () => _setAvailability('current'),
                ),
                _filterChip(
                  label: 'تبدأ قريبًا',
                  selected: _availability == 'upcoming',
                  colors: colors,
                  onTap: () => _setAvailability('upcoming'),
                ),
                _filterChip(
                  label: 'المنتهية',
                  selected: _availability == 'expired',
                  colors: colors,
                  onTap: () => _setAvailability('expired'),
                ),
                _filterChip(
                  label: 'غير المفعلة',
                  selected: _availability == 'inactive',
                  colors: colors,
                  onTap: () => _setAvailability('inactive'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildDepartmentSelector(colors),
        ],
      ),
    );
  }

  Widget _buildDepartmentSelector(_OfferColors colors) {
    final String label = _departmentLabel(_department);
    final IconData icon = _departmentIcon(_department);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey<String>('offers-department-selector'),
        onTap: () => _showDepartmentPicker(colors),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _department == null
                  ? colors.border
                  : const Color(0xFFB89552),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: widget.isDarkMode ? 0.16 : 0.035,
                ),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFB89552).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF9B7738), size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'القسم',
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.secondaryText,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDepartmentPicker(_OfferColors colors) async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.88;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colors.border),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.border,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'اختاري القسم',
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'اعرضي عروض كل الأقسام أو قسمًا محددًا.',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _departmentOption(
                          sheetContext: sheetContext,
                          value: 'all',
                          title: 'كل الأقسام',
                          subtitle: 'عرض الصالون والعيادة معًا',
                          icon: Icons.grid_view_rounded,
                          selected: _department == null,
                          colors: colors,
                        ),
                        const SizedBox(height: 9),
                        _departmentOption(
                          sheetContext: sheetContext,
                          value: 'salon',
                          title: 'الصالون',
                          subtitle: 'عروض الشعر والجمال والعناية',
                          icon: Icons.content_cut_rounded,
                          selected: _department == 'salon',
                          colors: colors,
                        ),
                        const SizedBox(height: 9),
                        _departmentOption(
                          sheetContext: sheetContext,
                          value: 'clinic',
                          title: 'العيادة',
                          subtitle: 'عروض البشرة والعيادة التجميلية',
                          icon: Icons.spa_outlined,
                          selected: _department == 'clinic',
                          colors: colors,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    final String? department = selected == 'all' ? null : selected;

    if (department == _department) {
      return;
    }

    setState(() {
      _department = department;
    });
    await _loadOffers();
  }

  Widget _departmentOption({
    required BuildContext sheetContext,
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required _OfferColors colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>('department-$value'),
        onTap: () => Navigator.of(sheetContext).pop<String>(value),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFB89552).withValues(alpha: 0.12)
                : colors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? const Color(0xFFB89552) : colors.border,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFB89552)
                      : const Color(0xFFB89552).withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : const Color(0xFF9B7738),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFFB89552),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _departmentLabel(String? value) {
    if (value == 'salon') {
      return 'الصالون';
    }

    if (value == 'clinic') {
      return 'العيادة';
    }

    return 'كل الأقسام';
  }

  IconData _departmentIcon(String? value) {
    if (value == 'salon') {
      return Icons.content_cut_rounded;
    }

    if (value == 'clinic') {
      return Icons.spa_outlined;
    }

    return Icons.grid_view_rounded;
  }

  void _setAvailability(String? value) {
    setState(() {
      _availability = value;
    });
    _loadOffers();
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required _OfferColors colors,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFFB89552).withValues(alpha: 0.18),
        backgroundColor: colors.surface,
        side: BorderSide(
          color: selected ? const Color(0xFFB89552) : colors.border,
        ),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF9B7738) : colors.primaryText,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBody(_OfferColors colors) {
    if (_isLoading) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(height: 170),
          Center(child: CircularProgressIndicator(color: Color(0xFFB89552))),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 90),
          Icon(Icons.cloud_off_outlined, color: colors.secondaryText, size: 44),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.primaryText),
          ),
          const SizedBox(height: 14),
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadOffers,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    }

    if (_offers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 90),
          const Icon(
            Icons.local_offer_outlined,
            color: Color(0xFFB89552),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد عروض ضمن هذا الفلتر.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: _offers.length + (_currentPage < _lastPage ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 11),
      itemBuilder: (BuildContext context, int index) {
        if (index >= _offers.length) {
          return Center(
            child: OutlinedButton(
              onPressed: _isLoadingMore
                  ? null
                  : () => _loadOffers(append: true),
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFB89552),
                      ),
                    )
                  : const Text('تحميل المزيد'),
            ),
          );
        }

        return _buildOfferCard(_offers[index], colors);
      },
    );
  }

  Widget _buildOfferCard(AdminOffer offer, _OfferColors colors) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openForm(offer),
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: colors.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: widget.isDarkMode ? 0.22 : 0.055,
                ),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildOfferImage(offer, colors),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (offer.valueText != null &&
                                  offer.valueText!
                                      .trim()
                                      .isNotEmpty) ...<Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      width: 3,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: <Color>[
                                            Color(0xFFE0C17A),
                                            Color(0xFF9B7738),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        offer.valueText!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFB89552),
                                          fontSize: 18,
                                          height: 1.2,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 9),
                              ],
                              Text(
                                offer.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.primaryText,
                                  fontSize: 17,
                                  height: 1.35,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Icon(
                                    offer.catalogItem == null
                                        ? _departmentIcon(offer.department.code)
                                        : Icons.design_services_outlined,
                                    color: const Color(0xFFB89552),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      offer.catalogItem?.name ??
                                          offer.department.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.secondaryText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          tooltip: 'خيارات العرض',
                          color: colors.surface,
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: colors.secondaryText,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (String action) {
                            if (action == 'edit') {
                              _openForm(offer);
                            } else if (action == 'toggle') {
                              _toggleActive(offer);
                            } else if (action == 'delete') {
                              _confirmDelete(offer);
                            }
                          },
                          itemBuilder: (_) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.edit_outlined, size: 19),
                                  SizedBox(width: 9),
                                  Text('تعديل'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'toggle',
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    offer.isActive
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 9),
                                  Text(
                                    offer.isActive
                                        ? 'إيقاف العرض'
                                        : 'تفعيل العرض',
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFD84A4A),
                                    size: 19,
                                  ),
                                  SizedBox(width: 9),
                                  Text(
                                    'حذف',
                                    style: TextStyle(color: Color(0xFFD84A4A)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (offer.description != null &&
                        offer.description!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        offer.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 12,
                          height: 1.55,
                        ),
                      ),
                    ],
                    if (offer.detailsText != null &&
                        offer.detailsText!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFB89552,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFB89552),
                              size: 16,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                offer.detailsText!,
                                style: TextStyle(
                                  color: colors.primaryText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildDateFooter(offer, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferImage(AdminOffer offer, _OfferColors colors) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: 225,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (offer.imageUrl == null)
              ColoredBox(
                color: widget.isDarkMode
                    ? const Color(0xFF26221C)
                    : const Color(0xFFF1E6D5),
                child: const Icon(
                  Icons.image_outlined,
                  color: Color(0xFFB89552),
                  size: 52,
                ),
              )
            else
              CachedNetworkImage(
                imageUrl: offer.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(
                  color: Color(0xFFF1E6D5),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFB89552)),
                  ),
                ),
                errorWidget: (_, _, _) => const ColoredBox(
                  color: Color(0xFFF1E6D5),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFFB89552),
                    size: 40,
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0x33000000),
                    Color(0x00000000),
                    Color(0x66000000),
                  ],
                  stops: <double>[0, 0.54, 1],
                ),
              ),
            ),
            if (offer.badgeText != null && offer.badgeText!.trim().isNotEmpty)
              Positioned(
                top: 12,
                left: 12,
                child: _offerImageBadge(offer.badgeText!),
              ),
            Positioned(
              right: 12,
              bottom: 12,
              child: _statusOverlay(offer, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offerImageBadge(String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD8B66B).withValues(alpha: 0.92),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFE0C17A),
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusOverlay(AdminOffer offer, _OfferColors colors) {
    final _OfferStatus status = _statusFor(offer, colors);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: status.color.withValues(alpha: 0.55),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            shadows: <Shadow>[
              Shadow(
                color: Color(0x99000000),
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _OfferStatus _statusFor(AdminOffer offer, _OfferColors colors) {
    if (offer.availability == 'current') {
      return const _OfferStatus(label: 'متاح الآن', color: Color(0xFF43C07A));
    }

    if (offer.availability == 'upcoming') {
      return const _OfferStatus(label: 'يبدأ قريبًا', color: Color(0xFFE4B35A));
    }

    if (offer.availability == 'expired') {
      return const _OfferStatus(label: 'انتهى', color: Color(0xFFB8B8B8));
    }

    if (offer.availability == 'inactive') {
      return const _OfferStatus(label: 'متوقف', color: Color(0xFFE45D5D));
    }

    return _OfferStatus(label: offer.availability, color: colors.secondaryText);
  }

  Widget _buildDateFooter(AdminOffer offer, _OfferColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF171717)
            : const Color(0xFFFCFAF6),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: const Color(0xFFB89552).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF9B7738),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'من ${_formatDate(offer.startsAt)}'
              '  •  إلى ${_formatDate(offer.endsAt)}',
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final DateTime local = value.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OfferStatus {
  const _OfferStatus({required this.label, required this.color});

  final String label;
  final Color color;
}

class _OfferColors {
  const _OfferColors({
    required this.background,
    required this.surface,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color primaryText;
  final Color secondaryText;

  factory _OfferColors.from(bool isDarkMode) {
    return _OfferColors(
      background: isDarkMode ? Colors.black : Colors.white,
      surface: isDarkMode ? const Color(0xFF111111) : const Color(0xFFF8F8F8),
      border: isDarkMode ? const Color(0xFF2B2B2B) : const Color(0xFFE8E8E8),
      primaryText: isDarkMode ? Colors.white : const Color(0xFF171717),
      secondaryText: isDarkMode
          ? const Color(0xFFB8B8B8)
          : const Color(0xFF747474),
    );
  }
}
