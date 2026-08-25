import 'package:flutter/material.dart';
import '../customers/customers_screen.dart';
import '../auth/auth_session.dart';
import '../appointments/appointments_screen.dart';
import 'data/dashboard_model.dart';
import 'data/dashboard_service.dart';
import '../catalog/catalog_screen.dart';
import '../gift_cards/presentation/gift_cards_screen.dart';
import '../coupons/presentation/promotion_management_screen.dart';
import '../settings/settings_screen.dart';
import '../posts/presentation/posts_screen.dart';
import '../banners/presentation/banners_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.authSession,
    required this.isDarkMode,
    required this.onToggleTheme,
    super.key,
  });

  final AuthSession authSession;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = const DashboardService();

  int _selectedIndex = 0;
  DashboardModel? _dashboard;
  String? _dashboardError;
  bool _isDashboardLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isDashboardLoading = true;
        _dashboardError = null;
      });
    }

    try {
      final dashboard = await _dashboardService.fetchDashboard();

      if (!mounted) {
        return;
      }

      setState(() {
        _dashboard = dashboard;
        _dashboardError = null;
        _isDashboardLoading = false;
      });
    } on DashboardException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _dashboardError = error.message;
        _isDashboardLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _dashboardError = 'حدث خطأ أثناء تحميل البيانات.';
        _isDashboardLoading = false;
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
        ? const Color(0xFF292929)
        : const Color(0xFFEAEAEA);

    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF171717);

    final secondaryTextColor = isDarkMode
        ? const Color(0xFFB5B5B5)
        : const Color(0xFF777777);

    final navigationBarColor = isDarkMode
        ? const Color(0xFF15130F)
        : const Color(0xFFFBF7EF);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomePage(
                isDarkMode: isDarkMode,
                cardColor: cardColor,
                borderColor: borderColor,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                dashboard: _dashboard,
                isLoading: _isDashboardLoading,
                errorMessage: _dashboardError,
              ),
              AppointmentsScreen(
                isDarkMode: isDarkMode,
                onBack: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              CustomersScreen(isDarkMode: isDarkMode),
              _buildMorePage(
                backgroundColor: backgroundColor,
                cardColor: cardColor,
                borderColor: borderColor,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: NavigationBar(
          height: 66,
          elevation: 0,
          selectedIndex: _selectedIndex,
          backgroundColor: navigationBarColor,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          indicatorColor: isDarkMode
              ? const Color(0xFF332B1E)
              : const Color(0xFFF1E1C2),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF9B7738)
                  : secondaryTextColor,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });

            if (index == 0 && _dashboard == null && !_isDashboardLoading) {
              _loadDashboard();
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 22),
              selectedIcon: Icon(
                Icons.home,
                size: 22,
                color: Color(0xFF9B7738),
              ),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined, size: 22),
              selectedIcon: Icon(
                Icons.calendar_month,
                size: 22,
                color: Color(0xFF9B7738),
              ),
              label: 'المواعيد',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, size: 22),
              selectedIcon: Icon(
                Icons.people,
                size: 22,
                color: Color(0xFF9B7738),
              ),
              label: 'العملاء',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined, size: 22),
              selectedIcon: Icon(
                Icons.grid_view_rounded,
                size: 22,
                color: Color(0xFF9B7738),
              ),
              label: 'المزيد',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage({
    required bool isDarkMode,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required DashboardModel? dashboard,
    required bool isLoading,
    required String? errorMessage,
  }) {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: const Color(0xFFB89552),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(
              isDarkMode: isDarkMode,
              primaryTextColor: primaryTextColor,
            ),
            if (isLoading) ...[
              const SizedBox(height: 110),
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFB89552)),
              ),
              const SizedBox(height: 110),
            ] else if (errorMessage != null) ...[
              const SizedBox(height: 30),
              _buildDashboardError(
                message: errorMessage,
                cardColor: cardColor,
                borderColor: borderColor,
                primaryTextColor: primaryTextColor,
              ),
              const SizedBox(height: 80),
            ] else if (dashboard != null) ...[
              const SizedBox(height: 20),
              _buildSectionTitle(
                title: 'يحتاج متابعة الآن',
                textColor: primaryTextColor,
              ),
              const SizedBox(height: 10),
              _buildFollowUpCard(
                followUp: dashboard.followUp,
                cardColor: cardColor,
                borderColor: borderColor,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 22),
              _buildSectionTitle(
                title: 'ملخص اليوم',
                textColor: primaryTextColor,
              ),
              const SizedBox(height: 10),
              _buildSummaryGrid(
                dashboard: dashboard,
                cardColor: cardColor,
                borderColor: borderColor,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(height: 22),
              _buildSectionTitle(
                title: 'الإجراءات السريعة',
                textColor: primaryTextColor,
              ),
              const SizedBox(height: 10),
              _buildQuickActions(
                cardColor: cardColor,
                borderColor: borderColor,
                primaryTextColor: primaryTextColor,
              ),
              const SizedBox(height: 22),
              _buildSectionTitle(
                title: 'تنبيهات النظام',
                textColor: primaryTextColor,
              ),
              const SizedBox(height: 10),
              _buildSystemAlert(
                cardColor: cardColor,
                borderColor: borderColor,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar({
    required bool isDarkMode,
    required Color primaryTextColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('صفحة الإشعارات سنربطها لاحقًا.')),
            );
          },
          tooltip: 'الإشعارات',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: primaryTextColor,
                size: 25,
              ),
              Positioned(
                top: 0,
                left: 1,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB89552),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: widget.onToggleTheme,
          tooltip: isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Icon(
              isDarkMode ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              key: ValueKey<bool>(isDarkMode),
              color: isDarkMode ? const Color(0xFFD8B56A) : primaryTextColor,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({required String title, required Color textColor}) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
    );
  }

  Widget _buildFollowUpCard({
    required DashboardFollowUp? followUp,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required bool isDarkMode,
  }) {
    if (followUp == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFFB89552),
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              'لا توجد مواعيد تحتاج متابعة حاليًا',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    final waitingBadgeColor = isDarkMode
        ? const Color(0xFF351717)
        : const Color(0xFFFFE9E9);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5484D),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'موعد بانتظار التأكيد',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: waitingBadgeColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _statusLabel(followUp.status),
                  style: const TextStyle(
                    color: Color(0xFFE06B6B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            followUp.customerName,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            followUp.servicesText,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 13, color: secondaryTextColor),
          ),
          const SizedBox(height: 3),
          Text(
            _formatAppointmentDate(followUp.requestedStartAt),
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 13, color: secondaryTextColor),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showComingSoon('تعديل الموعد');
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: Color(0xFFB89552)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'تعديل',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    _showComingSoon('تأكيد الموعد');
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: isDarkMode
                        ? const Color(0xFFD3B06B)
                        : const Color(0xFF171717),
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'تأكيد',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid({
    required DashboardModel dashboard,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.78,
      children: [
        _buildSummaryCard(
          title: 'مواعيد اليوم',
          value: dashboard.todayAppointments.toString(),
          icon: Icons.calendar_today_outlined,
          cardColor: cardColor,
          borderColor: borderColor,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
        _buildSummaryCard(
          title: 'بانتظار التأكيد',
          value: dashboard.pendingAppointments.toString(),
          icon: Icons.schedule_outlined,
          cardColor: cardColor,
          borderColor: borderColor,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
        _buildSummaryCard(
          title: 'قيد التنفيذ',
          value: dashboard.inProgressAppointments.toString(),
          icon: Icons.autorenew_rounded,
          cardColor: cardColor,
          borderColor: borderColor,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
        _buildSummaryCard(
          title: 'اكتملت',
          value: dashboard.completedAppointments.toString(),
          icon: Icons.check_circle_outline,
          cardColor: cardColor,
          borderColor: borderColor,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFB89552).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFB89552), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions({
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
  }) {
    final actions = [
      (icon: Icons.add_circle_outline, title: 'حجز جديد'),
      (icon: Icons.person_add_alt_1_outlined, title: 'إضافة عميلة'),
      (icon: Icons.spa_outlined, title: 'الخدمات'),
      (icon: Icons.campaign_outlined, title: 'إرسال إشعار'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.78,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];

        return InkWell(
          onTap: () {
            _showComingSoon(action.title);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB89552).withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    action.icon,
                    color: const Color(0xFFB89552),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.title,
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
          ),
        );
      },
    );
  }

  Widget _buildSystemAlert({
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFFB7791F),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لا توجد تنبيهات جديدة',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ستظهر هنا تذكيرات المواعيد والتنبيهات المهمة.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: secondaryTextColor, size: 22),
        ],
      ),
    );
  }

  Widget _buildDashboardError({
    required String message,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 32,
            color: Color(0xFFB89552),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: primaryTextColor),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildMorePage({
    required Color backgroundColor,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final isDarkMode = widget.isDarkMode;
    final softGoldColor = isDarkMode
        ? const Color(0xFF2A2419)
        : const Color(0xFFF7F0E3);

    return ColoredBox(
      color: backgroundColor,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المزيد',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'إدارة كل أقسام كراند ليان من مكان واحد',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: softGoldColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Color(0xFFB89552),
                  size: 23,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDarkMode
                    ? const [Color(0xFF2B2418), Color(0xFF17130E)]
                    : const [Color(0xFFC7A25E), Color(0xFF9B7738)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B7738).withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'لوحة إدارة متكاملة',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'وصول سريع للخدمات والعروض والتقارير والإعدادات.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.55,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildMoreSectionTitle(
            title: 'الأدوات الأساسية',
            textColor: primaryTextColor,
          ),
          const SizedBox(height: 11),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            childAspectRatio: 1.12,
            children: [
              _buildMoreFeatureCard(
                icon: Icons.spa_outlined,
                title: 'الخدمات والبكجات',
                subtitle: 'الأسعار والصور والتفاصيل',
                cardColor: cardColor,
                borderColor: borderColor,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CatalogScreen(isDarkMode: widget.isDarkMode),
                    ),
                  );
                },
              ),
              _buildMoreFeatureCard(
                icon: Icons.local_offer_outlined,
                title: 'العروض والكوبونات',
                subtitle: 'الخصومات والحملات',
                cardColor: cardColor,
                borderColor: borderColor,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PromotionManagementScreen(
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  );
                },
              ),
              _buildMoreFeatureCard(
                icon: Icons.card_giftcard_rounded,
                title: 'بطاقات الهدايا',
                subtitle: 'إنشاء وإدارة البطاقات',
                cardColor: cardColor,
                borderColor: borderColor,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          GiftCardsScreen(isDarkMode: widget.isDarkMode),
                    ),
                  );
                },
              ),
              _buildMoreFeatureCard(
                icon: Icons.campaign_outlined,
                title: 'الإشعارات',
                subtitle: 'إرسال إشعارات للعميلات',
                cardColor: cardColor,
                borderColor: borderColor,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () => _showComingSoon('الإشعارات'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildMoreSectionTitle(
            title: 'الإدارة والمتابعة',
            textColor: primaryTextColor,
          ),
          const SizedBox(height: 11),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Column(
              children: [

                _buildMoreListItem(
                  icon: Icons.view_carousel_outlined,
                  title: 'البانرات',
                  subtitle: 'إدارة بانرات الرئيسية والصالون والعيادة',
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  borderColor: borderColor,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BannersScreen(isDarkMode: widget.isDarkMode),
                      ),
                    );
                  },
                ),

                              _buildMoreListItem(
                  icon: Icons.photo_library_outlined,
                  title: 'آخر المنشورات',
                  subtitle: 'إضافة وإدارة منشورات الصالون والعيادة',
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  borderColor: borderColor,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PostsScreen(
                          isDarkMode: widget.isDarkMode,
                        ),
                      ),
                    );
                  },
                ),

                _buildMoreListItem(
                  icon: Icons.insert_chart_outlined_rounded,
                  title: 'التقارير',
                  subtitle: 'التقارير اليومية والشهرية',
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  borderColor: borderColor,
                  onTap: () => _showComingSoon('التقارير'),
                ),
                _buildMoreListItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'المالية',
                  subtitle: 'المبيعات والأرباح والمدفوعات',
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  borderColor: borderColor,
                  onTap: () => _showComingSoon('المالية'),
                ),
                _buildMoreListItem(
                  icon: Icons.star_outline_rounded,
                  title: 'تقييمات العميلات',
                  subtitle: 'متابعة التقييمات بعد الخدمات',
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  borderColor: borderColor,
                  onTap: () => _showComingSoon('تقييمات العميلات'),
                ),
                _buildMoreListItem(
                  icon: Icons.settings_outlined,
                  title: 'الإعدادات',
                  subtitle: 'إعدادات التطبيق والحساب',
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  borderColor: borderColor,
                  isLast: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          isDarkMode: widget.isDarkMode,
                          onToggleTheme: widget.onToggleTheme,
                          onLogout: widget.authSession.logout,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.authSession.logout,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF2B1717)
                      : const Color(0xFFFFF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF4A2525)
                        : const Color(0xFFFFD8D8),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFD84A4A),
                      size: 21,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'تسجيل الخروج',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD84A4A),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFD84A4A),
                      size: 21,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreSectionTitle({
    required String title,
    required Color textColor,
  }) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: textColor,
      ),
    );
  }

  Widget _buildMoreFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB89552).withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: const Color(0xFFB89552), size: 21),
                  ),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: secondaryTextColor.withValues(alpha: 0.72),
                    size: 15,
                  ),
                ],
              ),
           const SizedBox(height: 18),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.35,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreListItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB89552).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: const Color(0xFFB89552), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: secondaryTextColor,
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(right: 66, left: 14),
            child: Divider(height: 1, thickness: 0.7, color: borderColor),
          ),
      ],
    );
  }

  String _formatAppointmentDate(DateTime? date) {
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

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'قيد الانتظار',
      'confirmed' => 'مؤكد',
      'in_progress' => 'قيد التنفيذ',
      'completed' => 'مكتمل',
      'cancelled' => 'ملغي',
      'no_show' => 'لم تحضر',
      _ => status,
    };
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('سيتم ربط $feature في الخطوة الخاصة به.')),
    );
  }
}
