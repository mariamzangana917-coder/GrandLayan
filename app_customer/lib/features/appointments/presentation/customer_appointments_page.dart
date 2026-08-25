import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../data/models/customer_appointment.dart';
import '../providers/appointment_provider.dart';

class CustomerAppointmentsPage extends ConsumerWidget {
  const CustomerAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final surfaceColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final primaryTextColor =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1C);
    final secondaryTextColor =
        isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    final currentFilter = ref.watch(appointmentTabFilterProvider);
    final appointmentsAsync = ref.watch(filteredAppointmentsProvider);

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
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
            'مواعيدي',
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Column(
          children: [
            // Filter Tabs
            _AppointmentFilterTabs(
              currentFilter: currentFilter,
              onFilterSelected: (category) {
                ref
                    .read(appointmentTabFilterProvider.notifier)
                    .setFilter(category);
              },
              isDark: isDark,
              surfaceColor: surfaceColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              borderColor: borderColor,
            ),

            // Content
            Expanded(
              child: appointmentsAsync.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 2.5,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'جاري تحميل المواعيد...',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                error: (error, stackTrace) => _AppointmentErrorView(
                  errorMessage: error.toString(),
                  onRetry: () =>
                      ref.read(customerAppointmentsProvider.notifier).refresh(),
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return _AppointmentEmptyView(
                      category: currentFilter,
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.gold,
                    onRefresh: () async {
                      await ref
                          .read(customerAppointmentsProvider.notifier)
                          .refresh();
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      itemCount: appointments.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        return _AppointmentCard(
                          appointment: appointment,
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          borderColor: borderColor,
                          onTap: () {
                            context.push(
                              '/appointments/${appointment.id}',
                              extra: appointment,
                            );
                          },
                        );
                      },
                    ),
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

class _AppointmentFilterTabs extends StatelessWidget {
  const _AppointmentFilterTabs({
    required this.currentFilter,
    required this.onFilterSelected,
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.borderColor,
  });

  final AppointmentStatusCategory currentFilter;
  final ValueChanged<AppointmentStatusCategory> onFilterSelected;
  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'القادمة والنشطة',
            isSelected: currentFilter == AppointmentStatusCategory.upcoming,
            onTap: () => onFilterSelected(AppointmentStatusCategory.upcoming),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _TabItem(
            label: 'السابقة والملغاة',
            isSelected: currentFilter == AppointmentStatusCategory.past,
            onTap: () => onFilterSelected(AppointmentStatusCategory.past),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _TabItem(
            label: 'الكل',
            isSelected: currentFilter == AppointmentStatusCategory.all,
            onTap: () => onFilterSelected(AppointmentStatusCategory.all),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.gold
                : (isDark ? const Color(0xFF282828) : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.gold
                  : (isDark
                      ? const Color(0xFF383838)
                      : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF4B5563)),
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.onTap,
  });

  final CustomerAppointment appointment;
  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final VoidCallback onTap;

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'الموعد غير محدد';
    }
    final local = dateTime.toLocal();
    final dateStr =
        '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minuteStr = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'م' : 'ص';
    return '$dateStr  •  $hour:$minuteStr $period';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = appointment.statusColor;
    final isSalon = appointment.department.isSalon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Reference & Status
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Department
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isSalon
                                    ? const Color(0xFFEC4899)
                                    : const Color(0xFF06B6D4))
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSalon
                                    ? Icons.content_cut_rounded
                                    : Icons.medical_services_outlined,
                                size: 13,
                                color: isSalon
                                    ? const Color(0xFFEC4899)
                                    : const Color(0xFF06B6D4),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                appointment.department.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSalon
                                      ? const Color(0xFFEC4899)
                                      : const Color(0xFF06B6D4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Reference
                        Expanded(
                          child: Text(
                            appointment.reference,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          appointment.statusIcon,
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointment.statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: borderColor),
              const SizedBox(height: 12),

              // Service Title
              Text(
                appointment.summaryServicesText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 10),

              // Date and Time
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateTime(appointment.effectiveStartAt),
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (appointment.totalDurationMinutes > 0) ...[
                    const SizedBox(width: 10),
                    Text(
                      '•  ${appointment.totalDurationMinutes} دقيقة',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Footer: Price & Details Arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price
                  if (appointment.finalAmount != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          PriceFormatter.formatPlain(appointment.finalAmount),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'د.ع',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (appointment.discountAmount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'تم تطبيق خصم',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    Text(
                      'السعر حسب المعاينة',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                  // View details button
                  const Row(
                    children: [
                      Text(
                        'عرض التفاصيل',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 12,
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentEmptyView extends StatelessWidget {
  const _AppointmentEmptyView({
    required this.category,
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  final AppointmentStatusCategory category;
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    final title = switch (category) {
      AppointmentStatusCategory.upcoming => 'لا توجد مواعيد قادمة',
      AppointmentStatusCategory.past => 'لا توجد مواعيد سابقة',
      AppointmentStatusCategory.all => 'ليس لديكِ أي مواعيد مسجلة',
    };

    final description = switch (category) {
      AppointmentStatusCategory.upcoming =>
        'لم تقومي بحجز أي موعد قادم حتى الآن. اختاري خدماتكِ المفضلة واحجزي موعدكِ بسهولة.',
      AppointmentStatusCategory.past =>
        'سوف تظهر هنا مواعيدكِ المكتملة أو الملغاة فور انتهائها.',
      AppointmentStatusCategory.all =>
        'ابدئي تجربتكِ الفاخرة مع صالون وعيادة Grand Layan باختيار الخدمة المناسبة لكِ.',
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: isDark ? 0.15 : 0.08),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 42,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Booking action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/salon'),
                    icon: const Icon(Icons.content_cut_rounded, size: 18),
                    label: const Text('حجز في الصالون'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/clinic'),
                    icon: const Icon(
                      Icons.medical_services_outlined,
                      size: 18,
                    ),
                    label: const Text('حجز في العيادة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentErrorView extends StatelessWidget {
  const _AppointmentErrorView({
    required this.errorMessage,
    required this.onRetry,
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  final String errorMessage;
  final VoidCallback onRetry;
  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'تعذر جلب المواعيد',
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
