import 'package:flutter/material.dart';

import 'data/customer_details_model.dart';
import 'data/customer_details_service.dart';
import 'data/customer_service.dart';

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({
    required this.customerId,
    required this.isDarkMode,
    super.key,
  });

  final int customerId;
  final bool isDarkMode;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  static const _gold = Color(0xFFB89552);

  final _service = const CustomerDetailsService();

  CustomerDetails? _details;
  String? _errorMessage;
  bool _isLoading = true;

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
      final details = await _service.fetchDetails(widget.customerId);

      if (!mounted) return;

      setState(() {
        _details = details;
        _isLoading = false;
      });
    } on CustomerException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'حدث خطأ أثناء تحميل تفاصيل العميلة.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final background = dark ? Colors.black : Colors.white;
    final card = dark ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
    final primary = dark ? Colors.white : const Color(0xFF171717);
    final secondary = dark ? const Color(0xFFBEBEBE) : const Color(0xFF6E6E6E);
    final border = dark ? const Color(0xFF333333) : const Color(0xFFE5E1D8);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'تفاصيل العميلة',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _body(
          card: card,
          primary: primary,
          secondary: secondary,
          border: border,
        ),
      ),
    );
  }

  Widget _body({
    required Color card,
    required Color primary,
    required Color secondary,
    required Color border,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _gold));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 38, color: _gold),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: primary),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
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
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _profileHeader(
            details: details,
            primary: primary,
            secondary: secondary,
          ),
          const SizedBox(height: 24),
          _card(
            card: card,
            border: border,
            children: [
              _row(
                icon: Icons.phone_outlined,
                title: 'رقم الهاتف',
                value: details.phone ?? 'غير متوفر',
                primary: primary,
                secondary: secondary,
                border: border,
              ),
              _row(
                icon: Icons.email_outlined,
                title: 'البريد الإلكتروني',
                value: details.email ?? 'غير متوفر',
                primary: primary,
                secondary: secondary,
                border: border,
              ),
              _row(
                icon: Icons.calendar_today_outlined,
                title: 'تاريخ التسجيل',
                value: _date(details.createdAt),
                primary: primary,
                secondary: secondary,
                border: border,
              ),
              _statusRow(isActive: details.isActive, primary: primary),
            ],
          ),
          const SizedBox(height: 14),
          _card(
            card: card,
            border: border,
            children: [
              _row(
                icon: Icons.event_note_outlined,
                title: 'عدد الحجوزات',
                value: details.appointmentsCount.toString(),
                primary: primary,
                secondary: secondary,
                border: border,
              ),
              _row(
                icon: Icons.schedule_outlined,
                title: 'آخر موعد',
                value: _date(details.lastAppointmentAt),
                primary: primary,
                secondary: secondary,
                border: border,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _appointmentsCard(
            details: details,
            card: card,
            border: border,
            primary: primary,
            secondary: secondary,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      details.isActive
                          ? 'ربط تعطيل الحساب سيكون بالخطوة التالية.'
                          : 'ربط تفعيل الحساب سيكون بالخطوة التالية.',
                    ),
                  ),
                );
              },
              icon: Icon(
                details.isActive
                    ? Icons.block_outlined
                    : Icons.check_circle_outline,
              ),
              label: Text(details.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 44),
                foregroundColor: details.isActive
                    ? const Color(0xFFB42318)
                    : const Color(0xFF1D7A46),
                side: BorderSide(
                  color: details.isActive
                      ? const Color(0xFFB42318)
                      : const Color(0xFF1D7A46),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader({
    required CustomerDetails details,
    required Color primary,
    required Color secondary,
  }) {
    final letter = details.name.isNotEmpty
        ? details.name.characters.first
        : 'ع';

    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold, width: 1.5),
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withValues(alpha: 0.14),
            ),
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: _gold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          details.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: primary,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          [
            if (details.phone != null) details.phone!,
            if (details.email != null) details.email!,
          ].join('  |  '),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: secondary),
        ),
      ],
    );
  }

  Widget _card({
    required Color card,
    required Color border,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String value,
    required Color primary,
    required Color secondary,
    required Color border,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 22, color: _gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: border),
          ),
      ],
    );
  }

  Widget _statusRow({required bool isActive, required Color primary}) {
    final color = isActive ? const Color(0xFF1D7A46) : const Color(0xFFB42318);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle_outline : Icons.block_outlined,
            size: 22,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'حالة الحساب',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ),
          Text(
            isActive ? 'نشطة' : 'غير نشطة',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentsCard({
    required CustomerDetails details,
    required Color card,
    required Color border,
    required Color primary,
    required Color secondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: _gold,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'آخر المواعيد',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
          if (details.appointments.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: Text(
                'لا توجد مواعيد لهذه العميلة.',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, color: secondary),
              ),
            )
          else
            ...details.appointments.asMap().entries.map((entry) {
              final index = entry.key;
              final appointment = entry.value;
              final status = _status(appointment.status);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.reference.isEmpty
                                    ? 'موعد رقم ${appointment.id}'
                                    : appointment.reference,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _date(appointment.requestedStartAt),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          status.$1,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: status.$2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                          color: secondary,
                        ),
                      ],
                    ),
                  ),
                  if (index != details.appointments.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: border),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  (String, Color) _status(String status) {
    return switch (status) {
      'pending' => ('بانتظار التأكيد', const Color(0xFF9A6700)),
      'confirmed' => ('مؤكد', const Color(0xFF1D7A46)),
      'in_progress' => ('قيد التنفيذ', const Color(0xFF2764C7)),
      'completed' => ('مكتمل', const Color(0xFF666666)),
      'cancelled' => ('ملغي', const Color(0xFFB42318)),
      'no_show' => ('لم تحضر', const Color(0xFF7650A8)),
      _ => (status, const Color(0xFF666666)),
    };
  }

  String _date(DateTime? date) {
    if (date == null) return 'لا يوجد';

    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}
