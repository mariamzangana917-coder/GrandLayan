import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../catalog/data/models/catalog_item.dart';
import '../../catalog/providers/catalog_provider.dart';
import '../providers/appointment_provider.dart';

import 'widgets/coupon_code_field.dart';
import 'widgets/booking_success_price_summary.dart';

class ClinicBookingPage extends ConsumerStatefulWidget {
  const ClinicBookingPage({super.key});

  @override
  ConsumerState<ClinicBookingPage> createState() => _ClinicBookingPageState();
}

class _ClinicBookingPageState extends ConsumerState<ClinicBookingPage> {
  static const CatalogFilter _clinicFilter = CatalogFilter(
    department: 'clinic',
  );

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final TextEditingController _couponController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<int> _selectedItemIds = <int>{};

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _searchQuery = '';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String? get _normalizedCouponCode {
    final String value = _couponController.text.trim().toUpperCase();
    return value.isEmpty ? null : value;
  }

  DateTime? get _requestedStartAt {
    final DateTime? date = _selectedDate;
    final TimeOfDay? time = _selectedTime;

    if (date == null || time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'اختاري تاريخ الموعد',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'اختاري الوقت المطلوب',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = pickedTime;
    });
  }

  void _selectItem(CatalogItem item) {
    setState(() {
      _selectedItemIds.add(item.id);
      _searchQuery = '';
      _searchController.clear();
    });

    _searchFocusNode.requestFocus();
  }

  void _removeItem(CatalogItem item) {
    setState(() {
      _selectedItemIds.remove(item.id);
    });
  }

  List<CatalogItem> _selectedItems(List<CatalogItem> allItems) {
    return allItems
        .where((CatalogItem item) => _selectedItemIds.contains(item.id))
        .toList(growable: false);
  }

  List<CatalogItem> _searchResults(List<CatalogItem> allItems) {
    final String query = _normalizeText(_searchQuery);

    if (query.isEmpty) {
      return const <CatalogItem>[];
    }

    return allItems
        .where((CatalogItem item) {
          if (_selectedItemIds.contains(item.id)) {
            return false;
          }

          final String itemName = _normalizeText(item.name);
          final String categoryName = _normalizeText(item.category?.name ?? '');

          return itemName.contains(query) || categoryName.contains(query);
        })
        .take(8)
        .toList(growable: false);
  }

  String _normalizeText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  Future<void> _submitBooking(List<CatalogItem> allItems) async {
    if (_isSubmitting) {
      return;
    }

    final List<CatalogItem> selectedItems = _selectedItems(allItems);

    if (selectedItems.isEmpty) {
      _showError('اختاري خدمة واحدة على الأقل.');
      return;
    }

    if (_selectedDate == null) {
      _showError('اختاري تاريخ الموعد أولًا.');
      return;
    }

    if (_selectedTime == null) {
      _showError('اختاري وقت الموعد أولًا.');
      return;
    }

    final DateTime? requestedStartAt = _requestedStartAt;

    if (requestedStartAt == null || !requestedStartAt.isAfter(DateTime.now())) {
      _showError('يجب اختيار تاريخ ووقت في المستقبل.');
      return;
    }

    final List<int> departmentIds = selectedItems
        .map((CatalogItem item) => item.department?.id)
        .whereType<int>()
        .toList(growable: false);

    final int departmentId = departmentIds.isNotEmpty ? departmentIds.first : 2;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(appointmentRepositoryProvider);

      final Map<String, dynamic> response = await repository
          .createAppointmentWithItems(
            departmentId: departmentId,
            requestedStartAt: requestedStartAt,
            catalogItemIds: selectedItems
                .map((CatalogItem item) => item.id)
                .toList(growable: false),
            customerNotes: _notesController.text,
            couponCode: _normalizedCouponCode,
          );

      if (!mounted) {
        return;
      }

      final dynamic data = response['data'];
      final String reference = data is Map
          ? data['reference']?.toString() ?? ''
          : '';

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              icon: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFC9A227),
                size: 52,
              ),
              title: const Text(
                'تم إرسال طلب الحجز',
                textAlign: TextAlign.center,
              ),
              content: BookingSuccessPriceSummary(
                appointmentData: data,
                reference: reference,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('تم'),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(_cleanErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _cleanErrorMessage(Object error) {
    final String raw = error.toString().trim();

    if (raw.startsWith('ApiException:')) {
      return raw.replaceFirst('ApiException:', '').trim();
    }

    if (raw.startsWith('Exception:')) {
      return raw.replaceFirst('Exception:', '').trim();
    }

    return raw.isEmpty ? 'تعذر إرسال طلب الحجز.' : raw;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  String get _dateText {
    final DateTime? date = _selectedDate;

    if (date == null) {
      return 'اختاري التاريخ';
    }

    return DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);
  }

  String get _timeText {
    final TimeOfDay? time = _selectedTime;

    if (time == null) {
      return 'اختاري الوقت';
    }

    return time.format(context);
  }

  String _priceText(CatalogItem item) {
    if (item.priceType == 'inspection') {
      return 'بعد المعاينة';
    }

    final double? price = item.price;

    if (price == null) {
      return 'غير محدد';
    }

    return '${NumberFormat.decimalPattern('ar').format(price)} د.ع';
  }

  String _totalPriceText(List<CatalogItem> selectedItems) {
    double total = 0;
    bool hasInspectionPrice = false;

    for (final CatalogItem item in selectedItems) {
      if (item.priceType == 'inspection') {
        hasInspectionPrice = true;
      } else {
        total += item.price ?? 0;
      }
    }

    final String totalText =
        '${NumberFormat.decimalPattern('ar').format(total)} د.ع';

    return hasInspectionPrice ? '$totalText + خدمات بعد المعاينة' : totalText;
  }

  int _totalDuration(List<CatalogItem> selectedItems) {
    return selectedItems.fold<int>(
      0,
      (int total, CatalogItem item) => total + (item.durationMinutes ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final Color elevatedSurfaceColor = isDark
        ? const Color(0xFF242424)
        : Colors.white;

    final Color borderColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFE5E7EB);

    final AsyncValue<List<CatalogItem>> catalogState = ref.watch(
      catalogItemsProvider(_clinicFilter),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: catalogState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFC9A227)),
          ),
          error: (Object error, StackTrace stackTrace) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 42,
                      color: Color(0xFFC9A227),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'تعذر تحميل خدمات العيادة.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.invalidate(catalogItemsProvider(_clinicFilter));
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          },
          data: (List<CatalogItem> items) {
            final List<CatalogItem> availableItems = items
                .where((CatalogItem item) => item.isActive)
                .toList(growable: false);

            final List<CatalogItem> searchResults = _searchResults(
              availableItems,
            );

            final List<CatalogItem> selectedItems = _selectedItems(
              availableItems,
            );

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                    children: [
                      Text(
                        'اختاري خدماتچ',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ابحثي باسم الخدمة واختاري خدمة واحدة أو أكثر.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textDirection: TextDirection.rtl,
                        textInputAction: TextInputAction.search,
                        onChanged: (String value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'اكتبي اسم الخدمة، مثل مكياج...',
                          hintTextDirection: TextDirection.rtl,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.trim().isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: surfaceColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFFC9A227),
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                      if (_searchQuery.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: elevatedSurfaceColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.18 : 0.06,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: searchResults.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search_off_rounded,
                                        color: Color(0xFFC9A227),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'ماكو خدمة بهذا الاسم ضمن خدمات العيادة.',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Column(
                                    children: List<Widget>.generate(
                                      searchResults.length,
                                      (int index) {
                                        final CatalogItem item =
                                            searchResults[index];

                                        return Column(
                                          children: [
                                            _SearchSuggestionTile(
                                              item: item,
                                              priceText: _priceText(item),
                                              onTap: () => _selectItem(item),
                                            ),
                                            if (index !=
                                                searchResults.length - 1)
                                              Divider(
                                                height: 1,
                                                color: borderColor,
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ),
                      ],
                      if (selectedItems.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              '${selectedItems.length}',
                              style: const TextStyle(
                                color: Color(0xFFC9A227),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Expanded(
                              child: Text(
                                'الخدمات المختارة',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: elevatedSurfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              ...List<Widget>.generate(selectedItems.length, (
                                int index,
                              ) {
                                final CatalogItem item = selectedItems[index];

                                return Column(
                                  children: [
                                    _SelectedServiceTile(
                                      item: item,
                                      priceText: _priceText(item),
                                      onRemove: () => _removeItem(item),
                                    ),
                                    if (index != selectedItems.length - 1)
                                      Divider(height: 1, color: borderColor),
                                  ],
                                );
                              }),
                              const SizedBox(height: 8),
                              Divider(color: borderColor),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'المجموع التقريبي',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _totalPriceText(selectedItems),
                                    style: const TextStyle(
                                      color: Color(0xFFC9A227),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              if (_totalDuration(selectedItems) > 0) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 18,
                                      color: Color(0xFFC9A227),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      'المدة التقريبية: ${_totalDuration(selectedItems)} دقيقة',
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),
                      const Text(
                        'الموعد المطلوب',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BookingSelectionCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'التاريخ',
                        value: _dateText,
                        onTap: _selectDate,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 12),
                      _BookingSelectionCard(
                        icon: Icons.schedule_rounded,
                        title: 'الوقت',
                        value: _timeText,
                        onTap: _selectTime,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                      ),
                      CouponCodeField(controller: _couponController),
                      const SizedBox(height: 24),
                      const Text(
                        'ملاحظات إضافية',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        textDirection: TextDirection.rtl,
                        minLines: 4,
                        maxLines: 6,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          hintText:
                              'اكتبي أي تفاصيل تريدين أن تعرفها الإدارة...',
                          hintTextDirection: TextDirection.rtl,
                          filled: true,
                          fillColor: surfaceColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFC9A227,
                          ).withValues(alpha: isDark ? 0.10 : 0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFC9A227),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'هذا الموعد طلب مبدئي. ستقوم الإدارة بتأكيد الوقت نفسه أو اختيار وقت آخر.',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  height: 1.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      border: Border(top: BorderSide(color: borderColor)),
                    ),
                    child: SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitBooking(availableItems),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: isDark
                              ? const Color(0xFFC9A227)
                              : const Color(0xFF1C1C1C),
                          foregroundColor: isDark
                              ? const Color(0xFF1C1C1C)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                selectedItems.isEmpty
                                    ? 'اختاري خدمة أولًا'
                                    : 'إرسال طلب الحجز (${selectedItems.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchSuggestionTile extends StatelessWidget {
  const _SearchSuggestionTile({
    required this.item,
    required this.priceText,
    required this.onTap,
  });

  final CatalogItem item;
  final String priceText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color secondaryColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A227).withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: Color(0xFFC9A227),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (item.category != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.category!.name,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11.5, color: secondaryColor),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                priceText,
                style: const TextStyle(
                  color: Color(0xFFC9A227),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.add_circle_rounded, color: Color(0xFFC9A227)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedServiceTile extends StatelessWidget {
  const _SelectedServiceTile({
    required this.item,
    required this.priceText,
    required this.onRemove,
  });

  final CatalogItem item;
  final String priceText;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final Color secondaryColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          IconButton(
            onPressed: onRemove,
            tooltip: 'إزالة الخدمة',
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (item.durationMinutes != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${item.durationMinutes} دقيقة',
                    style: TextStyle(fontSize: 11.5, color: secondaryColor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            priceText,
            style: const TextStyle(
              color: Color(0xFFC9A227),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingSelectionCard extends StatelessWidget {
  const _BookingSelectionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    required this.surfaceColor,
    required this.borderColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFC9A227)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
