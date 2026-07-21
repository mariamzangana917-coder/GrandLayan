import 'package:flutter/material.dart';

import 'data/appointment_details_model.dart';
import 'data/appointment_details_service.dart';
import 'data/appointment_service.dart';
import 'appointment_edit_screen.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  const AppointmentDetailsScreen({
    required this.appointmentId,
    required this.isDarkMode,
    super.key,
  });

  final int appointmentId;
  final bool isDarkMode;

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  static const Color _gold = Color(0xFFB89552);

  final AppointmentDetailsService _service = const AppointmentDetailsService();

  AppointmentDetails? _details;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isActionRunning = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _service.fetchDetails(widget.appointmentId);

      if (!mounted) {
        return;
      }

      setState(() {
        _details = details;
        _isLoading = false;
      });
    } on AppointmentException catch (error) {
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
        _errorMessage = 'حدث خطأ أثناء تحميل تفاصيل الموعد.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    final cardColor = isDarkMode
        ? const Color(0xFF111111)
        : const Color(0xFFF8F8F8);

    final borderColor = isDarkMode
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFD2D2D2);

    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF171717);

    final secondaryTextColor = isDarkMode
        ? const Color(0xFFC1C1C1)
        : const Color(0xFF666666);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        centerTitle: true,
        title: const Text(
          'تفاصيل الموعد',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildBody(
          cardColor: cardColor,
          borderColor: borderColor,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
          isDarkMode: isDarkMode,
        ),
      ),
    );
  }

  Widget _buildBody({
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required bool isDarkMode,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _gold));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 34, color: _gold),
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: primaryTextColor),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _loadDetails,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final details = _details;

    if (details == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      color: _gold,
      onRefresh: _loadDetails,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _buildStatusHeader(
            details: details,
            cardColor: cardColor,
            borderColor: borderColor,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'بيانات العميلة',
            icon: Icons.person_outline_rounded,
            cardColor: cardColor,
            borderColor: borderColor,
            primaryTextColor: primaryTextColor,
            children: [
              _buildInfoRow(
                label: 'الاسم',
                value: details.customer.name,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
              _buildInfoRow(
                label: 'رقم الهاتف',
                value: details.customer.phone ?? 'غير متوفر',
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
              _buildInfoRow(
                label: 'البريد الإلكتروني',
                value: details.customer.email ?? 'غير متوفر',
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'معلومات الموعد',
            icon: Icons.event_note_outlined,
            cardColor: cardColor,
            borderColor: borderColor,
            primaryTextColor: primaryTextColor,
            children: [
              _buildInfoRow(
                label: 'القسم',
                value: details.department.name,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
              _buildInfoRow(
                label: 'الوقت المطلوب',
                value: _formatDate(details.requestedStartAt),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
              _buildInfoRow(
                label: 'الوقت المؤكد',
                value: details.confirmedStartAt == null
                    ? 'لم يتم التأكيد بعد'
                    : _formatDate(details.confirmedStartAt),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildServicesSection(
            details: details,
            cardColor: cardColor,
            borderColor: borderColor,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 12),
          _buildNotesSection(
            details: details,
            cardColor: cardColor,
            borderColor: borderColor,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          if (details.status == 'cancelled') ...[
            const SizedBox(height: 12),
            _buildCancellationSection(
              details: details,
              cardColor: cardColor,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
          ],
          const SizedBox(height: 18),
          _buildActions(details: details, isDarkMode: isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStatusHeader({
    required AppointmentDetails details,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final style = _statusStyle(details.status);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  details.reference.isEmpty
                      ? 'موعد رقم ${details.id}'
                      : details.reference,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: style.$2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  style.$1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: style.$3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 18, color: _gold),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _formatDate(details.requestedStartAt),
                  style: TextStyle(fontSize: 13, color: secondaryTextColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _gold),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: secondaryTextColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection({
    required AppointmentDetails details,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return _buildSection(
      title: 'الخدمات',
      icon: Icons.spa_outlined,
      cardColor: cardColor,
      borderColor: borderColor,
      primaryTextColor: primaryTextColor,
      children: details.items.isEmpty
          ? [
              Text(
                'لا توجد خدمات مسجلة.',
                style: TextStyle(color: secondaryTextColor),
              ),
            ]
          : details.items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                        if (item.quantity > 1)
                          Text(
                            '× ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                    if (item.durationMinutes != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'المدة: ${item.durationMinutes} دقيقة',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                    if (item.unitPrice != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'السعر: ${_formatMoney(item.unitPrice!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                    if (item.services.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...item.services.map(
                        (service) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${service.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
    );
  }

  Widget _buildNotesSection({
    required AppointmentDetails details,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return _buildSection(
      title: 'الملاحظات',
      icon: Icons.notes_rounded,
      cardColor: cardColor,
      borderColor: borderColor,
      primaryTextColor: primaryTextColor,
      children: [
        _buildNote(
          title: 'ملاحظات العميلة',
          value: details.customerNotes,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 10),
        _buildNote(
          title: 'ملاحظات الإدارة',
          value: details.adminNotes,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ],
    );
  }

  Widget _buildNote({
    required String title,
    required String? value,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: secondaryTextColor)),
        const SizedBox(height: 5),
        Text(
          value ?? 'لا توجد ملاحظات',
          style: TextStyle(fontSize: 13, height: 1.5, color: primaryTextColor),
        ),
      ],
    );
  }

  Widget _buildCancellationSection({
    required AppointmentDetails details,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return _buildSection(
      title: 'بيانات الإلغاء',
      icon: Icons.cancel_outlined,
      cardColor: cardColor,
      borderColor: borderColor,
      primaryTextColor: primaryTextColor,
      children: [
        _buildInfoRow(
          label: 'ألغاه',
          value: details.cancelledBy ?? 'غير محدد',
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
        _buildInfoRow(
          label: 'السبب',
          value: details.cancellationReason ?? 'غير محدد',
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
        _buildInfoRow(
          label: 'وقت الإلغاء',
          value: _formatDate(details.cancelledAt),
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ],
    );
  }

  Widget _buildActions({
    required AppointmentDetails details,
    required bool isDarkMode,
  }) {
    final primaryAction = switch (details.status) {
      'pending' => 'تأكيد الموعد',
      'confirmed' => 'بدء الخدمة',
      'in_progress' => 'إكمال الموعد',
      _ => null,
    };

    if (primaryAction == null &&
        details.status != 'pending' &&
        details.status != 'confirmed') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (primaryAction != null)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _isActionRunning
                  ? null
                  : () => _runPrimaryAction(details),
              style: FilledButton.styleFrom(
                backgroundColor: isDarkMode
                    ? const Color(0xFFD3B06B)
                    : const Color(0xFF171717),
                foregroundColor: isDarkMode ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                primaryAction,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        if (details.status == 'pending' || details.status == 'confirmed') ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openEdit(details),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(43),
                    side: const BorderSide(color: _gold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('تعديل'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isActionRunning
                      ? null
                      : () => _showCancelSheet(details),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(43),
                    foregroundColor: const Color(0xFFB42318),
                    side: const BorderSide(color: Color(0xFFB42318)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('إلغاء'),
                ),
              ),
            ],
          ),
          if (details.status == 'confirmed') ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isActionRunning ? null : () => _markNoShow(details),
              child: const Text('تسجيل لم تحضر'),
            ),
          ],
        ],
      ],
    );
  }

  (String, Color, Color) _statusStyle(String status) {
    return switch (status) {
      'pending' => (
        'بانتظار التأكيد',
        const Color(0xFFFFF3D6),
        const Color(0xFF9A6700),
      ),
      'confirmed' => ('مؤكد', const Color(0xFFE8F5EC), const Color(0xFF1D7A46)),
      'in_progress' => (
        'قيد التنفيذ',
        const Color(0xFFE8F1FF),
        const Color(0xFF2764C7),
      ),
      'completed' => (
        'مكتمل',
        const Color(0xFFEDEDED),
        const Color(0xFF555555),
      ),
      'cancelled' => ('ملغي', const Color(0xFFFFE9E9), const Color(0xFFB42318)),
      'no_show' => (
        'لم تحضر',
        const Color(0xFFF2EAFB),
        const Color(0xFF7650A8),
      ),
      _ => (status, const Color(0xFFEDEDED), const Color(0xFF555555)),
    };
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'غير محدد';
    }

    final localDate = date.toLocal();

    final hour = localDate.hour > 12
        ? localDate.hour - 12
        : localDate.hour == 0
        ? 12
        : localDate.hour;

    final minute = localDate.minute.toString().padLeft(2, '0');

    final period = localDate.hour >= 12 ? 'مساءً' : 'صباحًا';

    return '${localDate.day}/${localDate.month}/${localDate.year}، '
        '$hour:$minute $period';
  }

  String _formatMoney(double value) {
    final formatted = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(2);

    return '$formatted د.ع';
  }

  Future<void> _runPrimaryAction(AppointmentDetails details) async {
    final title = switch (details.status) {
      'pending' => 'تأكيد الموعد',
      'confirmed' => 'بدء الخدمة',
      _ => 'إكمال الموعد',
    };
    if (!await _confirmationSheet(title)) return;

    await _runAction(() {
      return switch (details.status) {
        'pending' => _service.confirm(details.id),
        'confirmed' => _service.start(details.id),
        'in_progress' => _service.complete(details.id),
        _ => Future.value(details),
      };
    });
  }

  Future<void> _markNoShow(AppointmentDetails details) async {
    if (!await _confirmationSheet('تسجيل عدم الحضور')) return;
    await _runAction(() => _service.markNoShow(details.id));
  }

  Future<void> _openEdit(AppointmentDetails details) async {
    final updated = await Navigator.of(context).push<AppointmentDetails>(
      MaterialPageRoute(
        builder: (_) => AppointmentEditScreen(
          details: details,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _details = updated);
      _message('تم تعديل الموعد.');
    }
  }

  Future<void> _showCancelSheet(AppointmentDetails details) async {
    final controller = TextEditingController();
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'إلغاء الموعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) Navigator.pop(sheetContext, value);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
              ),
              child: const Text('تأكيد الإلغاء'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (reason != null) {
      await _runAction(() => _service.cancel(details.id, reason: reason));
    }
  }

  Future<bool> _confirmationSheet(String title) async {
    return await showModalBottomSheet<bool>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('تأكيد'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: const Text('تراجع'),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<void> _runAction(Future<AppointmentDetails> Function() action) async {
    setState(() => _isActionRunning = true);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() => _details = updated);
      _message('تم تحديث الموعد بنجاح.');
    } on AppointmentException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _isActionRunning = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
