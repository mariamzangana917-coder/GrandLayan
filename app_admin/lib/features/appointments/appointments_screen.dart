import 'dart:async';

import 'package:flutter/material.dart';

import 'data/appointment_model.dart';
import 'data/appointment_service.dart';
import 'appointment_details_screen.dart';

enum AppointmentPeriod { today, week, month, all }

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({required this.isDarkMode, super.key});

  final bool isDarkMode;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  static const _gold = Color(0xFFB89552);

  final AppointmentService _service = const AppointmentService();

  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;

  final List<AdminAppointment> _appointments = [];

  AppointmentPeriod _selectedPeriod = AppointmentPeriod.today;

  String? _selectedStatus;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _lastPage = 1;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final range = _selectedDateRange();

      final result = await _service.fetchAppointments(
        search: _searchController.text,
        status: _selectedStatus,
        fromDate: range.$1,
        toDate: range.$2,
        page: 1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _appointments
          ..clear()
          ..addAll(result.appointments);

        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
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
        _errorMessage = 'حدث خطأ أثناء تحميل المواعيد.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _lastPage) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final range = _selectedDateRange();

      final result = await _service.fetchAppointments(
        search: _searchController.text,
        status: _selectedStatus,
        fromDate: range.$1,
        toDate: range.$2,
        page: _currentPage + 1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _appointments.addAll(result.appointments);
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _isLoadingMore = false;
      });
    } on AppointmentException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMore = false;
      });

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMore = false;
      });

      _showMessage('تعذر تحميل المزيد من المواعيد.');
    }
  }

  (DateTime?, DateTime?) _selectedDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (_selectedPeriod) {
      AppointmentPeriod.today => (today, today),
      AppointmentPeriod.week => (today, today.add(const Duration(days: 6))),
      AppointmentPeriod.month => (
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month + 1, 0),
      ),
      AppointmentPeriod.all => (null, null),
    };
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _loadAppointments(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    final cardColor = isDarkMode
        ? const Color(0xFF111111)
        : const Color(0xFFF8F8F8);

    final borderColor = isDarkMode
        ? const Color(0xFF454545)
        : const Color(0xFFC9C9C9);

    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF171717);

    final secondaryTextColor = isDarkMode
        ? const Color(0xFFC2C2C2)
        : const Color(0xFF666666);

    final fieldColor = isDarkMode
        ? const Color(0xFF141414)
        : const Color(0xFFF7F4EE);

    return Container(
      color: backgroundColor,
      child: RefreshIndicator(
        color: _gold,
        onRefresh: () => _loadAppointments(refresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'ابحثي باسم العميلة أو الرقم أو رقم الحجز',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: secondaryTextColor,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _loadAppointments(refresh: true);
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: fieldColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 0.8,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _gold,
                            width: 1.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusSelector(
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 21,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 7),
                        _buildPeriodDropdown(
                          cardColor: cardColor,
                          borderColor: borderColor,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                        const Spacer(),
                        Text(
                          '${_appointments.length} موعد',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(color: _gold)),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(
                  message: _errorMessage!,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                ),
              )
            else if (_appointments.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                sliver: SliverList.separated(
                  itemCount: _appointments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];

                    return _buildAppointmentCard(
                      appointment: appointment,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      isDarkMode: isDarkMode,
                    );
                  },
                ),
              ),
            if (!_isLoading &&
                _errorMessage == null &&
                _appointments.isNotEmpty &&
                _currentPage < _lastPage)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: OutlinedButton(
                    onPressed: _isLoadingMore ? null : _loadMore,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: const BorderSide(color: _gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoadingMore
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _gold,
                            ),
                          )
                        : const Text('تحميل المزيد'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodDropdown({
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return PopupMenuButton<AppointmentPeriod>(
      initialValue: _selectedPeriod,
      tooltip: 'اختيار الفترة',
      color: cardColor,
      elevation: 6,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1),
      ),
      onSelected: (period) {
        if (period == _selectedPeriod) {
          return;
        }

        setState(() {
          _selectedPeriod = period;
        });

        _loadAppointments(refresh: true);
      },
      itemBuilder: (context) {
        return AppointmentPeriod.values.map((period) {
          final isSelected = period == _selectedPeriod;

          return PopupMenuItem<AppointmentPeriod>(
            value: period,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _periodLabel(period),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: isSelected ? _gold : primaryTextColor,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.check_rounded, size: 18, color: _gold),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _periodLabel(_selectedPeriod),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector({
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final statuses = <(String?, String)>[
      (null, 'الكل'),
      ('pending', 'انتظار'),
      ('confirmed', 'مؤكد'),
      ('in_progress', 'تنفيذ'),
      ('completed', 'مكتمل'),
      ('cancelled', 'ملغي'),
      ('no_show', 'لم تحضر'),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (context, index) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = status.$1 == _selectedStatus;

          return InkWell(
            onTap: () {
              if (_selectedStatus == status.$1) {
                return;
              }

              setState(() {
                _selectedStatus = status.$1;
              });

              _loadAppointments(refresh: true);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    status.$2,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? _gold : secondaryTextColor,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isSelected ? 28 : 0,
                    height: 2.4,
                    decoration: BoxDecoration(
                      color: isSelected ? _gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard({
    required AdminAppointment appointment,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required bool isDarkMode,
  }) {
    final statusStyle = _statusStyle(appointment.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => AppointmentDetailsScreen(
                appointmentId: appointment.id,
                isDarkMode: widget.isDarkMode,
              ),
            ),
          );

          if (mounted) {
            await _loadAppointments(refresh: true);
          }
        },
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      appointment.customerName,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyle.$2,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      statusStyle.$1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusStyle.$3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Icon(
                    appointment.departmentCode == 'clinic'
                        ? Icons.medical_services_outlined
                        : Icons.spa_outlined,
                    size: 17,
                    color: _gold,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    appointment.departmentName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      appointment.servicesText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 17,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _formatDate(appointment.requestedStartAt),
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                  ),
                  Text(
                    appointment.reference,
                    style: TextStyle(fontSize: 10, color: secondaryTextColor),
                  ),
                ],
              ),
              if (appointment.status == 'pending' ||
                  appointment.status == 'confirmed') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _showMessage('تعديل الموعد سيكون في صفحة التفاصيل.');
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          side: const BorderSide(color: _gold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'تعديل',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          _showMessage(
                            appointment.status == 'pending'
                                ? 'ربط تأكيد الموعد سيكون بالخطوة التالية.'
                                : 'ربط بدء الخدمة سيكون بالخطوة التالية.',
                          );
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          backgroundColor: isDarkMode
                              ? const Color(0xFFD3B06B)
                              : const Color(0xFF171717),
                          foregroundColor: isDarkMode
                              ? Colors.black
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          appointment.status == 'pending'
                              ? 'تأكيد'
                              : 'بدء الخدمة',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 32, color: _gold),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: primaryTextColor),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  _loadAppointments(refresh: true);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 34,
                color: _gold,
              ),
              const SizedBox(height: 10),
              Text(
                'لا توجد مواعيد',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'غيّري الفترة أو الحالة أو امسحي البحث لعرض نتائج أخرى.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _periodLabel(AppointmentPeriod period) {
    return switch (period) {
      AppointmentPeriod.today => 'اليوم',
      AppointmentPeriod.week => 'الأسبوع',
      AppointmentPeriod.month => 'الشهر',
      AppointmentPeriod.all => 'الكل',
    };
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
      return 'لم يحدد الوقت';
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
