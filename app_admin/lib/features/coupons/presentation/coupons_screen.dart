import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../data/admin_coupon.dart';
import '../data/coupon_repository.dart';
import 'coupon_form_screen.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({
    required this.isDarkMode,
    this.repository = const CouponApiRepository(),
    super.key,
  });

  final bool isDarkMode;
  final CouponRepository repository;

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<AdminCoupon> _coupons = <AdminCoupon>[];

  Timer? _searchDebounce;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _lastPage = 1;
  int? _departmentId;
  String? _discountType;
  String? _availability;
  bool? _isActive;

  List<CouponDepartment> _departments = <CouponDepartment>[];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await Future.wait<void>(<Future<void>>[_loadCoupons(), _loadDepartments()]);
  }

  Future<void> _loadDepartments() async {
    try {
      final List<CouponDepartment> departments = await widget.repository
          .fetchDepartments();

      if (!mounted) {
        return;
      }

      setState(() {
        _departments = departments;
      });
    } catch (_) {
      // Filters still work without the optional department list.
    }
  }

  Future<void> _loadCoupons({bool append = false}) async {
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
      final AdminCouponPage page = await widget.repository.fetchCoupons(
        search: _searchController.text.trim(),
        departmentId: _departmentId,
        discountType: _discountType,
        availability: _availability,
        isActive: _isActive,
        page: append ? _currentPage + 1 : 1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (!append) {
          _coupons.clear();
        }

        _coupons.addAll(page.items);
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
        _errorMessage = 'تعذر تحميل الكوبونات.';
      });
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _loadCoupons);
  }

  Future<void> _openForm([AdminCoupon? coupon]) async {
    AdminCoupon? fullCoupon = coupon;

    if (coupon != null) {
      try {
        fullCoupon = await widget.repository.fetchCoupon(coupon.id);
      } on ApiException catch (error) {
        if (mounted) {
          _showMessage(error.message);
        }
        return;
      }
    }

    if (!mounted) {
      return;
    }

    final AdminCoupon? result = await Navigator.of(context).push<AdminCoupon>(
      MaterialPageRoute<AdminCoupon>(
        builder: (_) => CouponFormScreen(
          isDarkMode: widget.isDarkMode,
          repository: widget.repository,
          coupon: fullCoupon,
        ),
      ),
    );

    if (result != null && mounted) {
      await _loadCoupons();
    }
  }

  Future<void> _toggleActive(AdminCoupon coupon) async {
    try {
      await widget.repository.updateCoupon(
        couponId: coupon.id,
        fields: coupon.toPayload(isActiveOverride: !coupon.isActive),
      );

      if (mounted) {
        _showMessage(
          coupon.isActive ? 'تم إيقاف الكوبون.' : 'تم تفعيل الكوبون.',
        );
        await _loadCoupons();
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    }
  }

  Future<void> _confirmDelete(AdminCoupon coupon) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف الكوبون'),
            content: Text(
              'هل تريدين حذف كوبون "${coupon.name}"؟ '
              'إذا كان مستخدمًا سابقًا سيتم إيقافه بدل حذفه.',
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
                child: const Text('تأكيد'),
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
      final CouponDeleteResult result = await widget.repository.deleteCoupon(
        coupon.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);
      await _loadCoupons();
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _CouponColors colors = _CouponColors.from(widget.isDarkMode);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'الكوبونات',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              _buildHeader(colors),
              _buildFilters(colors),
              Expanded(child: _buildBody(colors)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_CouponColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'إدارة أكواد الخصم',
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_coupons.length} كوبون ظاهر',
                  style: TextStyle(color: colors.secondaryText, fontSize: 11.5),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            key: const ValueKey<String>('add-coupon-button'),
            onPressed: _openForm,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('إضافة كوبون'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB89552),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(_CouponColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: TextStyle(color: colors.primaryText),
            decoration: InputDecoration(
              hintText: 'ابحثي باسم الكوبون أو الكود',
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
                        _loadCoupons();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: colors.surface,
              border: _inputBorder(colors.border),
              enabledBorder: _inputBorder(colors.border),
              focusedBorder: _inputBorder(const Color(0xFFB89552), width: 1.4),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _filterChip(
                  label: 'الكل',
                  selected: _availability == null && _isActive == null,
                  colors: colors,
                  onTap: () {
                    setState(() {
                      _availability = null;
                      _isActive = null;
                    });
                    _loadCoupons();
                  },
                ),
                _filterChip(
                  label: 'المتاحة',
                  selected: _availability == 'available',
                  colors: colors,
                  onTap: () => _setAvailability('available'),
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
                  label: 'المستنفدة',
                  selected: _availability == 'exhausted',
                  colors: colors,
                  onTap: () => _setAvailability('exhausted'),
                ),
                _filterChip(
                  label: 'غير المفعلة',
                  selected: _isActive == false,
                  colors: colors,
                  onTap: () {
                    setState(() {
                      _availability = null;
                      _isActive = false;
                    });
                    _loadCoupons();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _selectorButton(
                  key: const ValueKey<String>('coupon-type-filter'),
                  icon: Icons.percent_rounded,
                  label: _discountTypeLabel,
                  colors: colors,
                  onTap: () => _showDiscountTypePicker(colors),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _selectorButton(
                  key: const ValueKey<String>('coupon-department-filter'),
                  icon: Icons.grid_view_rounded,
                  label: _departmentLabel,
                  colors: colors,
                  onTap: () => _showDepartmentPicker(colors),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  void _setAvailability(String value) {
    setState(() {
      _availability = value;
      _isActive = null;
    });
    _loadCoupons();
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required _CouponColors colors,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFFB89552),
        backgroundColor: colors.surface,
        side: BorderSide(
          color: selected ? const Color(0xFFB89552) : colors.border,
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : colors.primaryText,
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _selectorButton({
    required Key key,
    required IconData icon,
    required String label,
    required _CouponColors colors,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: const Color(0xFFB89552), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.secondaryText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _discountTypeLabel {
    return switch (_discountType) {
      'percentage' => 'خصم نسبي',
      'fixed' => 'خصم ثابت',
      _ => 'كل أنواع الخصم',
    };
  }

  String get _departmentLabel {
    for (final CouponDepartment department in _departments) {
      if (department.id == _departmentId) {
        return department.name;
      }
    }

    return 'كل الأقسام';
  }

  Future<void> _showDiscountTypePicker(_CouponColors colors) async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return _pickerSheet(
          colors: colors,
          title: 'نوع الخصم',
          options: <_PickerOption>[
            _PickerOption(
              value: 'all',
              title: 'كل الأنواع',
              icon: Icons.grid_view_rounded,
              selected: _discountType == null,
            ),
            _PickerOption(
              value: 'percentage',
              title: 'نسبة مئوية',
              icon: Icons.percent_rounded,
              selected: _discountType == 'percentage',
            ),
            _PickerOption(
              value: 'fixed',
              title: 'مبلغ ثابت',
              icon: Icons.payments_outlined,
              selected: _discountType == 'fixed',
            ),
          ],
          onSelected: (String value) {
            Navigator.of(sheetContext).pop(value);
          },
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _discountType = selected == 'all' ? null : selected;
    });
    await _loadCoupons();
  }

  Future<void> _showDepartmentPicker(_CouponColors colors) async {
    final int? selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _pickerSheet(
          colors: colors,
          title: 'القسم',
          options: <_PickerOption>[
            _PickerOption(
              value: '-1',
              title: 'كل الأقسام',
              icon: Icons.grid_view_rounded,
              selected: _departmentId == null,
            ),
            ..._departments.map(
              (CouponDepartment department) => _PickerOption(
                value: department.id.toString(),
                title: department.name,
                icon: department.code == 'salon'
                    ? Icons.content_cut_rounded
                    : Icons.spa_outlined,
                selected: _departmentId == department.id,
              ),
            ),
          ],
          onSelected: (String value) {
            Navigator.of(sheetContext).pop(int.tryParse(value));
          },
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _departmentId = selected == -1 ? null : selected;
    });
    await _loadCoupons();
  }

  Widget _pickerSheet({
    required _CouponColors colors,
    required String title,
    required List<_PickerOption> options,
    required ValueChanged<String> onSelected,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: colors.border),
          ),
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
              const SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, int index) {
                    final _PickerOption option = options[index];

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSelected(option.value),
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: option.selected
                                ? const Color(
                                    0xFFB89552,
                                  ).withValues(alpha: 0.12)
                                : colors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: option.selected
                                  ? const Color(0xFFB89552)
                                  : colors.border,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                option.icon,
                                color: const Color(0xFFB89552),
                                size: 21,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  option.title,
                                  style: TextStyle(
                                    color: colors.primaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (option.selected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFFB89552),
                                  size: 21,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(_CouponColors colors) {
    if (_isLoading && _coupons.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB89552)),
      );
    }

    if (_errorMessage != null && _coupons.isEmpty) {
      return _buildError(colors);
    }

    if (_coupons.isEmpty) {
      return _buildEmpty(colors);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
      itemCount: _coupons.length + (_currentPage < _lastPage ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, int index) {
        if (index == _coupons.length) {
          return Center(
            child: OutlinedButton.icon(
              onPressed: _isLoadingMore
                  ? null
                  : () => _loadCoupons(append: true),
              icon: _isLoadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: Text(_isLoadingMore ? 'جارٍ التحميل' : 'عرض المزيد'),
            ),
          );
        }

        return _buildCouponCard(_coupons[index], colors);
      },
    );
  }

  Widget _buildCouponCard(AdminCoupon coupon, _CouponColors colors) {
    final _CouponStatus status = _statusFor(coupon);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openForm(coupon),
        borderRadius: BorderRadius.circular(23),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: colors.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: colors.isDark ? 0.22 : 0.05,
                ),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
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
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                coupon.code,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: Color(0xFFB89552),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: status.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              status.label,
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          coupon.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 16,
                            height: 1.35,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'خيارات الكوبون',
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
                        _openForm(coupon);
                      } else if (action == 'toggle') {
                        _toggleActive(coupon);
                      } else if (action == 'delete') {
                        _confirmDelete(coupon);
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
                              coupon.isActive
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 19,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              coupon.isActive
                                  ? 'إيقاف الكوبون'
                                  : 'تفعيل الكوبون',
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
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Container(
                    width: 3,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFFE0C17A), Color(0xFF9B7738)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    _discountLabel(coupon),
                    style: const TextStyle(
                      color: Color(0xFFB89552),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: 12),
              _infoRow(
                icon: Icons.grid_view_rounded,
                label: coupon.department?.name ?? 'كل الأقسام',
                colors: colors,
              ),
              const SizedBox(height: 8),
              _infoRow(
                icon: Icons.repeat_rounded,
                label: _usesLabel(coupon),
                colors: colors,
              ),
              const SizedBox(height: 8),
              _infoRow(
                icon: Icons.person_outline_rounded,
                label: 'لكل زبونة: ${coupon.maximumUsesPerCustomer} مرة',
                colors: colors,
              ),
              const SizedBox(height: 8),
              _infoRow(
                icon: Icons.calendar_month_outlined,
                label: _dateLabel(coupon),
                colors: colors,
              ),
              if (coupon.catalogItemIds.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                _infoRow(
                  icon: Icons.design_services_outlined,
                  label: '${coupon.catalogItemIds.length} خدمة أو بكج محدد',
                  colors: colors,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required _CouponColors colors,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, color: const Color(0xFFB89552), size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _discountLabel(AdminCoupon coupon) {
    if (coupon.isPercentage) {
      return '${_compactNumber(coupon.discountValue)}% خصم';
    }

    return '${_money(coupon.discountValue)} د.ع خصم';
  }

  String _usesLabel(AdminCoupon coupon) {
    if (coupon.maximumTotalUses == null) {
      return 'مستخدم ${coupon.usedCount} مرة • بدون حد كلي';
    }

    return 'مستخدم ${coupon.usedCount} من ${coupon.maximumTotalUses}';
  }

  String _dateLabel(AdminCoupon coupon) {
    if (coupon.expiresAt == null) {
      return 'بدون تاريخ انتهاء';
    }

    return 'ينتهي ${_formatDate(coupon.expiresAt!)}';
  }

  _CouponStatus _statusFor(AdminCoupon coupon) {
    return switch (coupon.availability) {
      CouponAvailability.available => const _CouponStatus(
        label: 'متاح',
        color: Color(0xFF43C07A),
      ),
      CouponAvailability.upcoming => const _CouponStatus(
        label: 'يبدأ قريبًا',
        color: Color(0xFFE4B35A),
      ),
      CouponAvailability.expired => const _CouponStatus(
        label: 'منتهي',
        color: Color(0xFF9CA3AF),
      ),
      CouponAvailability.exhausted => const _CouponStatus(
        label: 'مستنفد',
        color: Color(0xFFD97706),
      ),
      CouponAvailability.inactive => const _CouponStatus(
        label: 'متوقف',
        color: Color(0xFFE45D5D),
      ),
    };
  }

  Widget _buildError(_CouponColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_outlined,
              color: Color(0xFFB89552),
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'تعذر تحميل الكوبونات.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.primaryText),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _loadCoupons,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(_CouponColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFB89552).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                color: Color(0xFFB89552),
                size: 35,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'لا توجد كوبونات',
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'أضيفي أول كوبون خصم من الزر بالأعلى.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final DateTime local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _compactNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  String _money(double value) {
    final String digits = value.round().toString();
    final StringBuffer buffer = StringBuffer();

    for (int index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }

    return buffer.toString();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PickerOption {
  const _PickerOption({
    required this.value,
    required this.title,
    required this.icon,
    required this.selected,
  });

  final String value;
  final String title;
  final IconData icon;
  final bool selected;
}

class _CouponStatus {
  const _CouponStatus({required this.label, required this.color});

  final String label;
  final Color color;
}

class _CouponColors {
  const _CouponColors({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
  });

  final bool isDark;
  final Color background;
  final Color surface;
  final Color border;
  final Color primaryText;
  final Color secondaryText;

  factory _CouponColors.from(bool isDark) {
    return _CouponColors(
      isDark: isDark,
      background: isDark ? const Color(0xFF090909) : const Color(0xFFF7F7F7),
      surface: isDark ? const Color(0xFF171717) : Colors.white,
      border: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
      primaryText: isDark ? const Color(0xFFF1F1F1) : const Color(0xFF1C1C1C),
      secondaryText: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B7280),
    );
  }
}
