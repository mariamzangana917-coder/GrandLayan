import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../data/models/customer_appointment.dart';
import '../providers/appointment_provider.dart';

class CustomerAppointmentDetailsPage extends ConsumerStatefulWidget {
  const CustomerAppointmentDetailsPage({
    required this.appointmentId,
    this.initialAppointment,
    super.key,
  });

  final int appointmentId;
  final CustomerAppointment? initialAppointment;

  @override
  ConsumerState<CustomerAppointmentDetailsPage> createState() =>
      _CustomerAppointmentDetailsPageState();
}

class _CustomerAppointmentDetailsPageState
    extends ConsumerState<CustomerAppointmentDetailsPage> {
  bool _isCancelling = false;

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'غير محدد';
    }
    final local = dateTime.toLocal();
    final formatter = DateFormat('yyyy/MM/dd  •  hh:mm a', 'ar');
    return formatter.format(local);
  }

  Future<void> _copyReference(String reference) async {
    await Clipboard.setData(ClipboardData(text: reference));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'تم نسخ رقم الموعد: $reference',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    CustomerAppointment appointment,
  ) async {
    final reasonController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final dialogSurfaceColor =
            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
        final dialogPrimaryText =
            isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1C);
        final dialogSecondaryText =
            isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B7280);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: dialogSurfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'إلغاء الموعد',
                  style: TextStyle(
                    color: dialogPrimaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هل أنتِ متأكدة من رغبتكِ في إلغاء هذا الموعد؟',
                  style: TextStyle(
                    color: dialogSecondaryText,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: TextStyle(color: dialogPrimaryText, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'سبب الإلغاء (اختياري)...',
                    hintStyle: TextStyle(
                      color: dialogSecondaryText.withValues(alpha: 0.7),
                      fontSize: 12.5,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF282828)
                        : const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF383838)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF383838)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'تراجع',
                  style: TextStyle(color: dialogSecondaryText),
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تأكيد الإلغاء',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final reason = reasonController.text.trim();
      await ref
          .read(customerAppointmentsProvider.notifier)
          .cancelAppointment(
            appointmentId: appointment.id,
            reason: reason.isEmpty ? 'تم الإلغاء بواسطة الزبونة' : reason,
          );

      if (!mounted) return;

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'تم إلغاء الموعد بنجاح.',
              textAlign: TextAlign.right,
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'تعذر إلغاء الموعد: ${e.toString()}',
              textAlign: TextAlign.right,
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final surfaceColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final elevatedSurface =
        isDark ? const Color(0xFF242424) : const Color(0xFFFFFFFF);
    final primaryTextColor =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1C);
    final secondaryTextColor =
        isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    final detailsAsync =
        ref.watch(customerAppointmentDetailsProvider(widget.appointmentId));

    final CustomerAppointment? appointment =
        detailsAsync.asData?.value ?? widget.initialAppointment;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: primaryTextColor,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'تفاصيل الموعد',
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: detailsAsync.when(
          loading: () {
            if (appointment != null) {
              return _buildDetailsContent(
                context,
                appointment,
                isDark,
                surfaceColor,
                elevatedSurface,
                primaryTextColor,
                secondaryTextColor,
                borderColor,
              );
            }
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.gold,
                strokeWidth: 2.5,
              ),
            );
          },
          error: (error, stack) {
            if (appointment != null) {
              return _buildDetailsContent(
                context,
                appointment,
                isDark,
                surfaceColor,
                elevatedSurface,
                primaryTextColor,
                secondaryTextColor,
                borderColor,
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تعذر تحميل تفاصيل الموعد',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => ref.invalidate(
                        customerAppointmentDetailsProvider(
                          widget.appointmentId,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                      ),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          },
          data: (loadedAppointment) {
            return _buildDetailsContent(
              context,
              loadedAppointment,
              isDark,
              surfaceColor,
              elevatedSurface,
              primaryTextColor,
              secondaryTextColor,
              borderColor,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailsContent(
    BuildContext context,
    CustomerAppointment appointment,
    bool isDark,
    Color surfaceColor,
    Color elevatedSurface,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final statusColor = appointment.statusColor;
    final isSalon = appointment.department.isSalon;

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () async {
        ref.invalidate(
          customerAppointmentDetailsProvider(widget.appointmentId),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
        children: [
          // Status Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    appointment.statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            appointment.statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyReference(appointment.reference),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    appointment.reference,
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 14,
                                    color: secondaryTextColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        appointment.statusDescription,
                        style: TextStyle(
                          color: primaryTextColor.withValues(alpha: 0.85),
                          fontSize: 12.8,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Department & Timing Info Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isSalon
                                ? const Color(0xFFEC4899)
                                : const Color(0xFF06B6D4))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSalon
                            ? Icons.content_cut_rounded
                            : Icons.medical_services_outlined,
                        color: isSalon
                            ? const Color(0xFFEC4899)
                            : const Color(0xFF06B6D4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'القسم',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appointment.department.name,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, thickness: 1, color: borderColor),
                const SizedBox(height: 14),

                // Requested time
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'الوقت المطلوب بالحجز',
                  value: _formatDateTime(appointment.requestedStartAt),
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),

                // Confirmed time if available
                if (appointment.confirmedStartAt != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.event_available_rounded,
                    label: 'الوقت المؤكد من الإدارة',
                    value: _formatDateTime(appointment.confirmedStartAt),
                    valueColor: AppColors.success,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Items & Services Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الخدمات والعناصر المحجوزة (${appointment.items.length})',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...appointment.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: elevatedSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (item.isPackage)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      margin: const EdgeInsetsDirectional.only(
                                        end: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'باقة',
                                        style: TextStyle(
                                          color: AppColors.gold,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      item.itemName,
                                      style: TextStyle(
                                        color: primaryTextColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (item.unitPrice != null)
                              Text(
                                '${PriceFormatter.formatPlain(item.unitPrice! * item.quantity)} د.ع',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            else
                              Text(
                                'معاينة',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 12.5,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'الكمية: ${item.quantity}',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 12,
                              ),
                            ),
                            if (item.durationMinutes != null &&
                                item.durationMinutes! > 0) ...[
                              const SizedBox(width: 12),
                              Text(
                                'المدة: ${item.durationMinutes} دقيقة',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // If item is a package and has executable services
                        if (item.isPackage && item.services.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1B1B1B)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الخدمات المشمولة بالباقة:',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...item.services.map((srv) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2.5,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 14,
                                          color: AppColors.gold,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${srv.serviceName} (${srv.durationMinutes} دقيقة)',
                                            style: TextStyle(
                                              color: primaryTextColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Price Calculation Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل الفاتورة',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                if (appointment.subtotalAmount != null) ...[
                  _PriceRow(
                    label: 'المجموع الفرعي',
                    amount: appointment.subtotalAmount!,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                ],
                if (appointment.discountAmount > 0) ...[
                  _PriceRow(
                    label: 'قيمة الخصم${appointment.coupon != null ? ' (${appointment.coupon!.code})' : ''}',
                    amount: -appointment.discountAmount,
                    amountColor: AppColors.success,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                ],
                Divider(height: 1, thickness: 1, color: borderColor),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المبلغ النهائي',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (appointment.finalAmount != null)
                      Text(
                        '${PriceFormatter.formatPlain(appointment.finalAmount)} د.ع',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    else
                      Text(
                        'حسب المعاينة',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Notes / Cancellation Reason
          if (appointment.customerNotes != null &&
              appointment.customerNotes!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ملاحظاتكِ',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appointment.customerNotes!,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (appointment.cancellationReason != null &&
              appointment.cancellationReason!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'سبب الإلغاء (${appointment.cancelledBy == 'customer' ? 'من قِبلكِ' : 'من الإدارة'})',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appointment.cancellationReason!,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (appointment.cancelledAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'تاريخ الإلغاء: ${_formatDateTime(appointment.cancelledAt)}',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Cancel Button for cancellable appointments
          if (appointment.canBeCancelled) ...[
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isCancelling
                    ? null
                    : () => _showCancelDialog(context, appointment),
                icon: _isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Icon(Icons.cancel_outlined, size: 19),
                label: Text(
                  _isCancelling ? 'جاري الإلغاء...' : 'إلغاء هذا الموعد',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: secondaryTextColor, fontSize: 11.5),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? primaryTextColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.amountColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  final String label;
  final double amount;
  final Color? amountColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: secondaryTextColor, fontSize: 13),
        ),
        Text(
          '${PriceFormatter.formatPlain(amount)} د.ع',
          style: TextStyle(
            color: amountColor ?? primaryTextColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
