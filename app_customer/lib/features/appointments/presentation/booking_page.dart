import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../catalog/data/models/catalog_item.dart';
import '../providers/appointment_provider.dart';

import 'widgets/coupon_code_field.dart';
import 'widgets/booking_success_price_summary.dart';

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({required this.item, super.key});

  final CatalogItem item;

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  final TextEditingController _notesController = TextEditingController();

  final TextEditingController _couponController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  CatalogItem get item => widget.item;

  int? get _departmentId {
    return item.department?.id;
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

  @override
  void dispose() {
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
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

  Future<void> _submitBooking() async {
    if (_isSubmitting) {
      return;
    }

    final int? departmentId = _departmentId;
    final DateTime? requestedStartAt = _requestedStartAt;

    if (departmentId == null) {
      _showError('تعذر تحديد قسم الخدمة. أعيدي فتح الخدمة وحاولي مرة ثانية.');
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

    if (requestedStartAt == null || !requestedStartAt.isAfter(DateTime.now())) {
      _showError('يجب اختيار تاريخ ووقت في المستقبل.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(appointmentRepositoryProvider);

      final Map<String, dynamic> response = await repository.createAppointment(
        departmentId: departmentId,
        requestedStartAt: requestedStartAt,
        catalogItemId: item.id,
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
          return AlertDialog(
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
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('تم'),
              ),
            ],
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

  String get _priceText {
    if (item.priceType == 'inspection') {
      return 'السعر بعد المعاينة';
    }

    final double? price = item.price;

    if (price == null) {
      return 'السعر غير محدد';
    }

    final NumberFormat formatter = NumberFormat.decimalPattern('ar');

    return '${formatter.format(price)} د.ع';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final Color borderColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: const Text('تأكيد الحجز'), centerTitle: true),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9A227).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      color: Color(0xFFC9A227),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _priceText,
                          style: const TextStyle(
                            color: Color(0xFFC9A227),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (item.durationMinutes != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            '${item.durationMinutes} دقيقة',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'الموعد المطلوب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              minLines: 4,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'اكتبي أي تفاصيل تريدين أن تعرفها الإدارة...',
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
                  Icon(Icons.info_outline_rounded, color: Color(0xFFC9A227)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'هذا الموعد طلب مبدئي. ستقوم الإدارة بتأكيد الوقت نفسه أو اقتراح وقت آخر.',
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBooking,
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
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Text(
                      'إرسال طلب الحجز',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
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
