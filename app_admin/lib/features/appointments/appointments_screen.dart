import 'dart:async';

import 'package:flutter/material.dart';

import 'appointment_details_screen.dart';
import 'appointment_edit_screen.dart';
import 'data/appointment_details_service.dart';
import 'data/appointment_model.dart';
import 'data/appointment_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({required this.isDarkMode, this.onBack, super.key});

  final bool isDarkMode;
  final VoidCallback? onBack;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  static const _gold = Color(0xFFB89552);
  final _service = const AppointmentService();
  final _detailsService = const AppointmentDetailsService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  final List<AdminAppointment> _appointments = [];
  List<AppointmentDepartmentFilter> _departments = [];
  String? _status;
  int? _departmentId;
  DateTime? _date;
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 280) {
      _loadMore();
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _load(refresh: true),
    );
    setState(() {});
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _lastPage = 1;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.fetchAppointments(
        search: _searchController.text,
        status: _status,
        departmentId: _departmentId,
        date: _date,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _appointments
          ..clear()
          ..addAll(result.appointments);
        _departments = result.departments;
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
        _loading = false;
      });
    } on AppointmentException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _service.fetchAppointments(
        search: _searchController.text,
        status: _status,
        departmentId: _departmentId,
        date: _date,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _appointments.addAll(result.appointments);
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
      });
    } on AppointmentException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _load(refresh: true);
  }

  Future<void> _openDetails(AdminAppointment appointment) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppointmentDetailsScreen(
          appointmentId: appointment.id,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
    if (mounted) await _load(refresh: true);
  }

  Future<void> _confirm(AdminAppointment appointment) async {
    final accepted = await _confirmSheet(
      title: 'تأكيد الموعد',
      message: 'هل تريدين تأكيد هذا الموعد في الوقت المطلوب؟',
      confirmLabel: 'تأكيد',
    );
    if (!accepted) return;
    await _runAction(
      () => _detailsService.confirm(appointment.id),
      'تم تأكيد الموعد.',
    );
  }

  Future<void> _cancel(AdminAppointment appointment) async {
    final reason = await _cancelSheet();
    if (reason == null) return;
    await _runAction(
      () => _detailsService.cancel(appointment.id, reason: reason),
      'تم إلغاء الموعد.',
    );
  }

  Future<void> _edit(AdminAppointment appointment) async {
    try {
      final details = await _detailsService.fetchDetails(appointment.id);
      if (!mounted) return;
      final updated = await Navigator.of(context).push(
        MaterialPageRoute<Object?>(
          builder: (_) => AppointmentEditScreen(
            details: details,
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
      if (updated != null && mounted) {
        _message('تم تعديل الموعد.');
        await _load(refresh: true);
      }
    } on AppointmentException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _runAction(
    Future<Object?> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (!mounted) return;
      _message(success);
      await _load(refresh: true);
    } on AppointmentException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.isDarkMode ? Colors.black : Colors.white;
    final foreground = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF171717);
    final secondary = widget.isDarkMode
        ? const Color(0xFFBDBDBD)
        : const Color(0xFF666666);
    final card = widget.isDarkMode
        ? const Color(0xFF111111)
        : const Color(0xFFF8F8F8);
    final border = widget.isDarkMode
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFD5D5D5);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'رجوع',
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'المواعيد',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          color: _gold,
          onRefresh: () => _load(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: 'ابحثي بالاسم أو الهاتف أو رقم الحجز',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _load(refresh: true);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _statusChips(secondary),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: _departmentId,
                              decoration: const InputDecoration(
                                labelText: 'القسم',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('كل الأقسام'),
                                ),
                                ..._departments.map(
                                  (item) => DropdownMenuItem<int?>(
                                    value: item.id,
                                    child: Text(item.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _departmentId = value);
                                _load(refresh: true);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(
                                _date == null
                                    ? 'كل التواريخ'
                                    : '${_date!.day}/${_date!.month}/${_date!.year}',
                              ),
                            ),
                          ),
                          if (_date != null)
                            IconButton(
                              tooltip: 'مسح التاريخ',
                              onPressed: () {
                                setState(() => _date = null);
                                _load(refresh: true);
                              },
                              icon: const Icon(Icons.close),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'عدد النتائج: $_total',
                          style: TextStyle(
                            color: secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: _gold)),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: _stateCard(
                    icon: Icons.cloud_off_outlined,
                    title: _error!,
                    action: 'إعادة المحاولة',
                    onPressed: () => _load(refresh: true),
                    card: card,
                    border: border,
                    foreground: foreground,
                  ),
                )
              else if (_appointments.isEmpty)
                SliverFillRemaining(
                  child: _stateCard(
                    icon: Icons.event_available_outlined,
                    title: 'لا توجد مواعيد مطابقة للفلاتر الحالية.',
                    card: card,
                    border: border,
                    foreground: foreground,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  sliver: SliverList.separated(
                    itemCount: _appointments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _appointmentCard(
                      _appointments[index],
                      card,
                      border,
                      foreground,
                      secondary,
                    ),
                  ),
                ),
              if (_loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(
                      child: CircularProgressIndicator(color: _gold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChips(Color secondary) {
    const values = <(String?, String)>[
      (null, 'الكل'),
      ('pending', 'انتظار'),
      ('confirmed', 'مؤكد'),
      ('in_progress', 'قيد التنفيذ'),
      ('completed', 'مكتمل'),
      ('cancelled', 'ملغي'),
      ('no_show', 'لم تحضر'),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final item = values[index];
          return ChoiceChip(
            label: Text(item.$2),
            selected: _status == item.$1,
            selectedColor: _gold.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: _status == item.$1 ? _gold : secondary,
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) {
              setState(() => _status = item.$1);
              _load(refresh: true);
            },
          );
        },
      ),
    );
  }

  Widget _appointmentCard(
    AdminAppointment item,
    Color card,
    Color border,
    Color foreground,
    Color secondary,
  ) {
    final status = _statusStyle(item.status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(item),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.customerName,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: status.$2,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      status.$1,
                      style: TextStyle(
                        color: status.$3,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${item.departmentName} • ${item.servicesText}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: secondary),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatDate(item.confirmedStartAt ?? item.requestedStartAt)}'
                '  |  ${item.reference}',
                style: TextStyle(color: secondary, fontSize: 12),
              ),
              if (item.status == 'pending' || item.status == 'confirmed') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _edit(item),
                        child: const Text('تعديل'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancel(item),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB42318),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    if (item.status == 'pending') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _confirm(item),
                          child: const Text('تأكيد'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required Color card,
    required Color border,
    required Color foreground,
    String? action,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: card,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _gold, size: 36),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: foreground),
              ),
              if (action != null) ...[
                const SizedBox(height: 14),
                OutlinedButton(onPressed: onPressed, child: Text(action)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmSheet({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
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
                  const SizedBox(height: 10),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: Text(confirmLabel),
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

  Future<String?> _cancelSheet() async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
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
              maxLength: 1000,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton(
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isNotEmpty) Navigator.pop(sheetContext, reason);
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
    return result;
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
    if (date == null) return 'غير محدد';
    final local = date.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour}:$minute';
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
