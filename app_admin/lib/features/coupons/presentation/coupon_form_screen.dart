import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../data/admin_coupon.dart';
import '../data/coupon_repository.dart';

class CouponFormScreen extends StatefulWidget {
  const CouponFormScreen({
    required this.isDarkMode,
    required this.repository,
    this.coupon,
    super.key,
  });

  final bool isDarkMode;
  final CouponRepository repository;
  final AdminCoupon? coupon;

  @override
  State<CouponFormScreen> createState() => _CouponFormScreenState();
}

class _CouponFormScreenState extends State<CouponFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _minimumOrderController;
  late final TextEditingController _maximumDiscountController;
  late final TextEditingController _maximumTotalUsesController;
  late final TextEditingController _maximumUsesPerCustomerController;
  late final TextEditingController _notesController;

  List<CouponDepartment> _departments = <CouponDepartment>[];
  List<CouponCatalogItem> _catalogItems = <CouponCatalogItem>[];
  final Set<int> _selectedCatalogItemIds = <int>{};

  String _discountType = 'percentage';
  int? _departmentId;
  DateTime? _startsAt;
  DateTime? _expiresAt;
  bool _isActive = true;
  bool _isLoadingLookups = true;
  bool _isLoadingCatalog = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.coupon != null;

  CouponDepartment? get _selectedDepartment {
    for (final CouponDepartment department in _departments) {
      if (department.id == _departmentId) {
        return department;
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();

    final AdminCoupon? coupon = widget.coupon;

    _nameController = TextEditingController(text: coupon?.name ?? '');
    _codeController = TextEditingController(text: coupon?.code ?? '');
    _discountValueController = TextEditingController(
      text: coupon == null ? '' : _numberText(coupon.discountValue),
    );
    _minimumOrderController = TextEditingController(
      text: coupon?.minimumOrderAmount == null
          ? ''
          : _numberText(coupon!.minimumOrderAmount!),
    );
    _maximumDiscountController = TextEditingController(
      text: coupon?.maximumDiscountAmount == null
          ? ''
          : _numberText(coupon!.maximumDiscountAmount!),
    );
    _maximumTotalUsesController = TextEditingController(
      text: coupon?.maximumTotalUses?.toString() ?? '',
    );
    _maximumUsesPerCustomerController = TextEditingController(
      text: (coupon?.maximumUsesPerCustomer ?? 1).toString(),
    );
    _notesController = TextEditingController(text: coupon?.notes ?? '');

    _discountType = coupon?.discountType ?? 'percentage';
    _departmentId = coupon?.departmentId;
    _startsAt = coupon?.startsAt;
    _expiresAt = coupon?.expiresAt;
    _isActive = coupon?.isActive ?? true;
    _selectedCatalogItemIds.addAll(coupon?.catalogItemIds ?? const <int>[]);

    _loadLookups();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _discountValueController.dispose();
    _minimumOrderController.dispose();
    _maximumDiscountController.dispose();
    _maximumTotalUsesController.dispose();
    _maximumUsesPerCustomerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _isLoadingLookups = true;
      _errorMessage = null;
    });

    try {
      final List<CouponDepartment> departments = await widget.repository
          .fetchDepartments();
      final List<CouponDepartment> availableDepartments =
          List<CouponDepartment>.from(departments);
      final CouponDepartment? currentDepartment = widget.coupon?.department;

      if (_departmentId != null &&
          currentDepartment != null &&
          !availableDepartments.any(
            (CouponDepartment item) => item.id == _departmentId,
          )) {
        availableDepartments.add(currentDepartment);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _departments = availableDepartments;
        _isLoadingLookups = false;
      });

      await _loadCatalogItems(keepSelection: true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoadingLookups = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'تعذر تحميل الأقسام والخدمات.';
        _isLoadingLookups = false;
      });
    }
  }

  Future<void> _loadCatalogItems({bool keepSelection = false}) async {
    setState(() {
      _isLoadingCatalog = true;

      if (!keepSelection) {
        _selectedCatalogItemIds.clear();
      }
    });

    try {
      final List<CouponCatalogItem> items = await widget.repository
          .fetchCatalogItems(departmentCode: _selectedDepartment?.code);

      if (!mounted) {
        return;
      }

      final Set<int> validIds = items.map((item) => item.id).toSet();

      setState(() {
        _catalogItems = items;
        _selectedCatalogItemIds.removeWhere((int id) => !validIds.contains(id));
        _isLoadingCatalog = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _catalogItems = <CouponCatalogItem>[];
        _selectedCatalogItemIds.clear();
        _isLoadingCatalog = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _catalogItems = <CouponCatalogItem>[];
        _selectedCatalogItemIds.clear();
        _isLoadingCatalog = false;
        _errorMessage = 'تعذر تحميل الخدمات والبكجات.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _CouponFormColors colors = _CouponFormColors.from(widget.isDarkMode);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            _isEditing ? 'تعديل الكوبون' : 'إضافة كوبون',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: _isLoadingLookups
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFB89552)),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: <Widget>[
                      if (_errorMessage != null) ...<Widget>[
                        _errorCard(_errorMessage!, colors),
                        const SizedBox(height: 12),
                      ],
                      _section(
                        title: 'معلومات الكوبون',
                        subtitle: 'الاسم والكود الظاهر للمديرة والزبونة',
                        colors: colors,
                        children: <Widget>[
                          _textField(
                            controller: _nameController,
                            label: 'اسم الكوبون',
                            hint: 'مثال: خصم الزبائن الجدد',
                            colors: colors,
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'اسم الكوبون مطلوب.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _textField(
                            controller: _codeController,
                            label: 'كود الكوبون',
                            hint: 'WELCOME20',
                            colors: colors,
                            textDirection: TextDirection.ltr,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9_-]'),
                              ),
                              _UpperCaseTextFormatter(),
                            ],
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'كود الكوبون مطلوب.';
                              }

                              if (!RegExp(
                                r'^[A-Z0-9_-]+$',
                              ).hasMatch(value.trim().toUpperCase())) {
                                return 'استخدمي أحرف إنجليزية وأرقام فقط.';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _section(
                        title: 'نوع وقيمة الخصم',
                        subtitle: 'اختاري نسبة مئوية أو مبلغًا ثابتًا',
                        colors: colors,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _typeChoice(
                                  label: 'نسبة مئوية',
                                  icon: Icons.percent_rounded,
                                  value: 'percentage',
                                  colors: colors,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _typeChoice(
                                  label: 'مبلغ ثابت',
                                  icon: Icons.payments_outlined,
                                  value: 'fixed',
                                  colors: colors,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _numericField(
                            controller: _discountValueController,
                            label: _discountType == 'percentage'
                                ? 'نسبة الخصم'
                                : 'مبلغ الخصم (د.ع)',
                            suffix: _discountType == 'percentage' ? '%' : 'د.ع',
                            colors: colors,
                            validator: (String? value) {
                              final double? number = _parseDouble(value);

                              if (number == null || number <= 0) {
                                return 'قيمة الخصم يجب أن تكون أكبر من صفر.';
                              }

                              if (_discountType == 'percentage' &&
                                  number > 100) {
                                return 'النسبة لا يمكن أن تتجاوز 100%.';
                              }

                              return null;
                            },
                          ),
                          if (_discountType == 'percentage') ...<Widget>[
                            const SizedBox(height: 12),
                            _numericField(
                              controller: _maximumDiscountController,
                              label: 'أعلى خصم مسموح (اختياري)',
                              suffix: 'د.ع',
                              colors: colors,
                              validator: _optionalPositiveValidator,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _numericField(
                            controller: _minimumOrderController,
                            label: 'الحد الأدنى لقيمة الحجز (اختياري)',
                            suffix: 'د.ع',
                            colors: colors,
                            validator: _optionalNonNegativeValidator,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _section(
                        title: 'نطاق الاستخدام',
                        subtitle: 'القسم والخدمات أو البكجات المشمولة',
                        colors: colors,
                        children: <Widget>[
                          DropdownButtonFormField<int>(
                            value: _departmentId ?? -1,
                            isExpanded: true,
                            decoration: _inputDecoration(
                              label: 'القسم',
                              colors: colors,
                            ),
                            dropdownColor: colors.surface,
                            style: TextStyle(color: colors.primaryText),
                            items: <DropdownMenuItem<int>>[
                              const DropdownMenuItem<int>(
                                value: -1,
                                child: Text('كل الأقسام'),
                              ),
                              ..._departments.map(
                                (CouponDepartment department) =>
                                    DropdownMenuItem<int>(
                                      value: department.id,
                                      child: Text(department.name),
                                    ),
                              ),
                            ],
                            onChanged: _isSaving
                                ? null
                                : (int? value) async {
                                    setState(() {
                                      _departmentId = value == -1
                                          ? null
                                          : value;
                                    });
                                    await _loadCatalogItems();
                                  },
                          ),
                          const SizedBox(height: 12),
                          _catalogSelector(colors),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _section(
                        title: 'شروط الاستخدام',
                        subtitle: 'العدد الكلي وعدد المرات لكل زبونة',
                        colors: colors,
                        children: <Widget>[
                          _integerField(
                            controller: _maximumTotalUsesController,
                            label: 'الحد الكلي للاستخدامات (اختياري)',
                            colors: colors,
                            validator: _optionalPositiveIntegerValidator,
                          ),
                          const SizedBox(height: 12),
                          _integerField(
                            controller: _maximumUsesPerCustomerController,
                            label: 'عدد الاستخدامات لكل زبونة',
                            colors: colors,
                            validator: (String? value) {
                              final int? number = int.tryParse(
                                value?.trim() ?? '',
                              );

                              if (number == null || number < 1) {
                                return 'يجب أن يكون مرة واحدة على الأقل.';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _section(
                        title: 'مدة الكوبون',
                        subtitle: 'يمكن ترك البداية أو النهاية بدون تحديد',
                        colors: colors,
                        children: <Widget>[
                          _dateSelector(
                            label: 'تاريخ البداية',
                            value: _startsAt,
                            colors: colors,
                            onPick: () => _pickDate(isStart: true),
                            onClear: _startsAt == null
                                ? null
                                : () => setState(() => _startsAt = null),
                          ),
                          const SizedBox(height: 10),
                          _dateSelector(
                            label: 'تاريخ الانتهاء',
                            value: _expiresAt,
                            colors: colors,
                            onPick: () => _pickDate(isStart: false),
                            onClear: _expiresAt == null
                                ? null
                                : () => setState(() => _expiresAt = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _section(
                        title: 'الحالة والملاحظات',
                        subtitle: 'يمكن إيقاف الكوبون بدون حذفه',
                        colors: colors,
                        children: <Widget>[
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _isActive,
                            activeColor: const Color(0xFFB89552),
                            title: Text(
                              'الكوبون مفعّل',
                              style: TextStyle(
                                color: colors.primaryText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              _isActive
                                  ? 'يمكن استخدامه عند تحقق الشروط.'
                                  : 'لن يقبل النظام هذا الكود.',
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 11.5,
                              ),
                            ),
                            onChanged: _isSaving
                                ? null
                                : (bool value) {
                                    setState(() {
                                      _isActive = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _notesController,
                            label: 'ملاحظات داخلية (اختياري)',
                            hint: 'تفاصيل لا تظهر للزبونة',
                            colors: colors,
                            maxLines: 4,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        key: const ValueKey<String>('save-coupon-button'),
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          _isSaving
                              ? 'جارٍ الحفظ'
                              : _isEditing
                              ? 'حفظ التعديلات'
                              : 'إضافة الكوبون',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: const Color(0xFFB89552),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
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

  Widget _section({
    required String title,
    required String subtitle,
    required _CouponFormColors colors,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _typeChoice({
    required String label,
    required IconData icon,
    required String value,
    required _CouponFormColors colors,
  }) {
    final bool selected = _discountType == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSaving
            ? null
            : () {
                setState(() {
                  _discountType = value;

                  if (value == 'fixed') {
                    _maximumDiscountController.clear();
                  }
                });
              },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFB89552).withValues(alpha: 0.13)
                : colors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFFB89552) : colors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                color: selected
                    ? const Color(0xFFB89552)
                    : colors.secondaryText,
                size: 19,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _catalogSelector(_CouponFormColors colors) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey<String>('coupon-catalog-selector'),
        onTap: _isSaving || _isLoadingCatalog || _catalogItems.isEmpty
            ? null
            : () => _showCatalogPicker(colors),
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.design_services_outlined,
                  color: const Color(0xFFB89552),
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'الخدمات والبكجات',
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isLoadingCatalog
                            ? 'جارٍ التحميل'
                            : _selectedCatalogItemIds.isEmpty
                            ? 'كل الخدمات والبكجات'
                            : '${_selectedCatalogItemIds.length} محدد',
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingCatalog)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.chevron_left_rounded, color: colors.secondaryText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCatalogPicker(_CouponFormColors colors) async {
    final Set<int> workingSelection = <int>{..._selectedCatalogItemIds};

    final Set<int>? result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setSheetState) {
                return Container(
                  height: MediaQuery.sizeOf(context).height * 0.78,
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(27),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
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
                        'الخدمات والبكجات المشمولة',
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'بدون تحديد يعني أن الكوبون يشمل الكل.',
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                workingSelection.clear();
                              });
                            },
                            child: const Text('يشمل الكل'),
                          ),
                          const Spacer(),
                          Text(
                            '${workingSelection.length} محدد',
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _catalogItems.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: colors.border),
                          itemBuilder: (_, int index) {
                            final CouponCatalogItem item = _catalogItems[index];
                            final bool selected = workingSelection.contains(
                              item.id,
                            );

                            return CheckboxListTile(
                              value: selected,
                              activeColor: const Color(0xFFB89552),
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                item.name,
                                style: TextStyle(
                                  color: colors.primaryText,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                item.type == 'package' ? 'بكج' : 'خدمة',
                                style: TextStyle(
                                  color: colors.secondaryText,
                                  fontSize: 10.5,
                                ),
                              ),
                              onChanged: (bool? checked) {
                                setSheetState(() {
                                  if (checked == true) {
                                    workingSelection.add(item.id);
                                  } else {
                                    workingSelection.remove(item.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(
                            sheetContext,
                          ).pop(Set<int>.from(workingSelection));
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB89552),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('اعتماد الاختيار'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedCatalogItemIds
        ..clear()
        ..addAll(result);
    });
  }

  Widget _dateSelector({
    required String label,
    required DateTime? value,
    required _CouponFormColors colors,
    required VoidCallback onPick,
    VoidCallback? onClear,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSaving ? null : onPick,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFFB89552),
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        label,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value == null ? 'بدون تحديد' : _formatDate(value),
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    tooltip: 'إزالة التاريخ',
                    onPressed: _isSaving ? null : onClear,
                    icon: const Icon(Icons.close_rounded, size: 19),
                  )
                else
                  Icon(Icons.chevron_left_rounded, color: colors.secondaryText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime now = DateTime.now();
    final DateTime initial = isStart
        ? (_startsAt ?? now)
        : (_expiresAt ?? _startsAt?.add(const Duration(days: 7)) ?? now);

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
      helpText: isStart ? 'اختاري تاريخ البداية' : 'اختاري تاريخ الانتهاء',
    );

    if (selected == null || !mounted) {
      return;
    }

    final DateTime normalized = DateTime(
      selected.year,
      selected.month,
      selected.day,
      isStart ? 0 : 23,
      isStart ? 0 : 59,
      isStart ? 0 : 59,
    );

    setState(() {
      if (isStart) {
        _startsAt = normalized;
      } else {
        _expiresAt = normalized;
      }
    });
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required _CouponFormColors colors,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextDirection? textDirection,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters,
      textDirection: textDirection,
      maxLines: maxLines,
      enabled: !_isSaving,
      style: TextStyle(color: colors.primaryText),
      decoration: _inputDecoration(label: label, hint: hint, colors: colors),
    );
  }

  Widget _numericField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required _CouponFormColors colors,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: !_isSaving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: TextStyle(color: colors.primaryText),
      decoration: _inputDecoration(
        label: label,
        colors: colors,
      ).copyWith(suffixText: suffix),
    );
  }

  Widget _integerField({
    required TextEditingController controller,
    required String label,
    required _CouponFormColors colors,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: !_isSaving,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: TextStyle(color: colors.primaryText),
      decoration: _inputDecoration(label: label, colors: colors),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required _CouponFormColors colors,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: colors.secondaryText),
      hintStyle: TextStyle(color: colors.secondaryText),
      filled: true,
      fillColor: colors.background,
      border: _border(colors.border),
      enabledBorder: _border(colors.border),
      focusedBorder: _border(const Color(0xFFB89552), width: 1.4),
      errorBorder: _border(const Color(0xFFD84A4A)),
      focusedErrorBorder: _border(const Color(0xFFD84A4A), width: 1.4),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _errorCard(String message, _CouponFormColors colors) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFD84A4A).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFD84A4A).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD84A4A),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _optionalPositiveValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final double? number = _parseDouble(value);
    if (number == null || number <= 0) {
      return 'يجب أن تكون القيمة أكبر من صفر.';
    }

    return null;
  }

  String? _optionalNonNegativeValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final double? number = _parseDouble(value);
    if (number == null || number < 0) {
      return 'القيمة لا يمكن أن تكون سالبة.';
    }

    return null;
  }

  String? _optionalPositiveIntegerValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final int? number = int.tryParse(value.trim());
    if (number == null || number < 1) {
      return 'يجب أن يكون مرة واحدة على الأقل.';
    }

    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_startsAt != null &&
        _expiresAt != null &&
        !_expiresAt!.isAfter(_startsAt!)) {
      setState(() {
        _errorMessage = 'تاريخ الانتهاء يجب أن يكون بعد تاريخ البداية.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final Map<String, dynamic> fields = <String, dynamic>{
      'name': _nameController.text.trim(),
      'code': _codeController.text.trim().toUpperCase(),
      'discount_type': _discountType,
      'discount_value': _parseDouble(_discountValueController.text),
      'minimum_order_amount': _parseDouble(_minimumOrderController.text),
      'maximum_discount_amount': _discountType == 'percentage'
          ? _parseDouble(_maximumDiscountController.text)
          : null,
      'department_id': _departmentId,
      'maximum_total_uses': _parseInt(_maximumTotalUsesController.text),
      'maximum_uses_per_customer': _parseInt(
        _maximumUsesPerCustomerController.text,
      ),
      'starts_at': _startsAt?.toUtc().toIso8601String(),
      'expires_at': _expiresAt?.toUtc().toIso8601String(),
      'is_active': _isActive,
      'notes': _nullableText(_notesController.text),
      'catalog_item_ids': _selectedCatalogItemIds.toList(growable: false),
    };

    try {
      final AdminCoupon savedCoupon;

      if (_isEditing) {
        savedCoupon = await widget.repository.updateCoupon(
          couponId: widget.coupon!.id,
          fields: fields,
        );
      } else {
        savedCoupon = await widget.repository.createCoupon(fields);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(savedCoupon);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = 'تعذر حفظ الكوبون.';
      });
    }
  }

  double? _parseDouble(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }

  int? _parseInt(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : int.tryParse(normalized);
  }

  String? _nullableText(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  String _numberText(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  String _formatDate(DateTime value) {
    final DateTime local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

class _CouponFormColors {
  const _CouponFormColors({
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

  factory _CouponFormColors.from(bool isDark) {
    return _CouponFormColors(
      background: isDark ? const Color(0xFF090909) : const Color(0xFFF7F7F7),
      surface: isDark ? const Color(0xFF171717) : Colors.white,
      border: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
      primaryText: isDark ? const Color(0xFFF1F1F1) : const Color(0xFF1C1C1C),
      secondaryText: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B7280),
    );
  }
}
