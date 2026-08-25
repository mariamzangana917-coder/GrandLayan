import 'package:flutter/material.dart';

import 'manager_profile_screen.dart';

/// Grand Layan admin settings landing page.
///
/// The manager profile item is connected to its real screen and API. The
/// remaining settings items stay ready for their dedicated implementation.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
    super.key,
  });

  static const Color _gold = Color(0xFFB89552);

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.fromBrightness(isDarkMode);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          constraints.maxWidth >= 600 ? 24 : 16,
                          8,
                          constraints.maxWidth >= 600 ? 24 : 16,
                          30,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate.fixed([
                            _buildHeader(context, palette),
                            const SizedBox(height: 18),
                            _buildProfileCard(palette),
                            const SizedBox(height: 26),
                            _SettingsSectionTitle(
                              title: 'الحساب',
                              palette: palette,
                            ),
                            const SizedBox(height: 10),
                            _SettingsSection(
                              palette: palette,
                              children: [
                                _SettingsTile(
                                  icon: Icons.person_outline_rounded,
                                  title: 'بيانات حساب المديرة',
                                  subtitle:
                                      'الاسم ورقم الهاتف والبريد الإلكتروني',
                                  palette: palette,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ManagerProfileScreen(
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _SettingsTile(
                                  icon: Icons.lock_outline_rounded,
                                  title: 'تغيير كلمة المرور',
                                  subtitle: 'تحديث كلمة المرور بشكل آمن',
                                  palette: palette,
                                  isLast: true,
                                  onTap: () => _showComingSoon(
                                    context,
                                    'تغيير كلمة المرور',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _SettingsSectionTitle(
                              title: 'إعدادات المركز',
                              palette: palette,
                            ),
                            const SizedBox(height: 10),
                            _SettingsSection(
                              palette: palette,
                              children: [
                                _SettingsTile(
                                  icon: Icons.storefront_outlined,
                                  title: 'بيانات Grand Layan',
                                  subtitle: 'الشعار والعنوان وأرقام التواصل',
                                  palette: palette,
                                  onTap: () =>
                                      _showComingSoon(context, 'بيانات المركز'),
                                ),
                                _SettingsTile(
                                  icon: Icons.schedule_rounded,
                                  title: 'ساعات العمل',
                                  subtitle:
                                      'أوقات الصالون والعيادة وأيام الإغلاق',
                                  palette: palette,
                                  isLast: true,
                                  onTap: () =>
                                      _showComingSoon(context, 'ساعات العمل'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _SettingsSectionTitle(
                              title: 'التشغيل والحجوزات',
                              palette: palette,
                            ),
                            const SizedBox(height: 10),
                            _SettingsSection(
                              palette: palette,
                              children: [
                                _SettingsTile(
                                  icon: Icons.calendar_month_outlined,
                                  title: 'إعدادات الحجوزات',
                                  subtitle:
                                      'الفواصل الزمنية والإلغاء والحجز المسبق',
                                  palette: palette,
                                  onTap: () => _showComingSoon(
                                    context,
                                    'إعدادات الحجوزات',
                                  ),
                                ),
                                _SettingsTile(
                                  icon: Icons.notifications_active_outlined,
                                  title: 'التذكيرات والإشعارات',
                                  subtitle:
                                      'تنبيهات الحجوزات والتقييمات والبطاقات',
                                  palette: palette,
                                  onTap: () => _showComingSoon(
                                    context,
                                    'التذكيرات والإشعارات',
                                  ),
                                ),
                                _SettingsTile(
                                  icon: Icons.payments_outlined,
                                  title: 'إعدادات الدفع',
                                  subtitle:
                                      'الدفع عند الوصول والعربون والدفع الإلكتروني',
                                  palette: palette,
                                  isLast: true,
                                  onTap: () =>
                                      _showComingSoon(context, 'إعدادات الدفع'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _SettingsSectionTitle(
                              title: 'التطبيق والأمان',
                              palette: palette,
                            ),
                            const SizedBox(height: 10),
                            _SettingsSection(
                              palette: palette,
                              children: [
                                _SettingsTile(
                                  icon: isDarkMode
                                      ? Icons.dark_mode_rounded
                                      : Icons.light_mode_outlined,
                                  title: 'الوضع الداكن',
                                  subtitle: isDarkMode
                                      ? 'الوضع الداكن مفعّل على هذا الجهاز'
                                      : 'تفعيل مظهر داكن ومريح للعين',
                                  palette: palette,
                                  trailing: Switch.adaptive(
                                    value: isDarkMode,
                                    activeTrackColor: _gold,
                                    onChanged: (_) => onToggleTheme(),
                                  ),
                                  onTap: onToggleTheme,
                                ),
                                _SettingsTile(
                                  icon: Icons.devices_outlined,
                                  title: 'الأجهزة والجلسات',
                                  subtitle:
                                      'مراجعة الأجهزة المسجّل منها الدخول',
                                  palette: palette,
                                  onTap: () => _showComingSoon(
                                    context,
                                    'الأجهزة والجلسات',
                                  ),
                                ),
                                _SettingsTile(
                                  icon: Icons.policy_outlined,
                                  title: 'سياسات المركز',
                                  subtitle: 'الإلغاء والتأخير وعدم الحضور',
                                  palette: palette,
                                  onTap: () =>
                                      _showComingSoon(context, 'سياسات المركز'),
                                ),
                                _SettingsTile(
                                  icon: Icons.info_outline_rounded,
                                  title: 'حول التطبيق',
                                  subtitle: 'الإصدار والخصوصية والدعم الفني',
                                  palette: palette,
                                  isLast: true,
                                  onTap: () =>
                                      _showComingSoon(context, 'حول التطبيق'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            _LogoutButton(
                              palette: palette,
                              onTap: () => _confirmLogout(context),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Grand Layan Admin',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: palette.secondaryText.withValues(
                                  alpha: 0.72,
                                ),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _SettingsPalette palette) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Row(
        children: [
          Tooltip(
            message: 'رجوع',
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 44),
              splashRadius: 22,
              icon: Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: palette.primaryText,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'الإعدادات',
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إدارة الحساب والمركز والتطبيق',
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(_SettingsPalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDarkMode
              ? const [Color(0xFF2A2419), Color(0xFF171717)]
              : const [Color(0xFFFFFBF3), Color(0xFFF5E7CC)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF4A3B25) : const Color(0xFFE8D3AC),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.055),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: isDarkMode ? 0.2 : 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: _gold.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: const Center(
              child: Text(
                'GL',
                style: TextStyle(
                  color: _gold,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مديرة Grand Layan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'حساب الإدارة الرئيسي',
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: isDarkMode ? 0.17 : 0.13),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'مديرة',
              style: TextStyle(
                color: _gold,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تم تجهيز مكان $feature، وسيتم ربطه بالـ API في مرحلته.',
          ),
        ),
      );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final palette = _SettingsPalette.fromBrightness(isDarkMode);

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: palette.card,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              'تسجيل الخروج؟',
              style: TextStyle(
                color: palette.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Text(
              'سيتم تسجيل الخروج من هذا الجهاز فقط، ولن تتأثر الأجهزة الأخرى.',
              style: TextStyle(color: palette.secondaryText, height: 1.55),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD84A4A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldLogout == true) {
      onLogout();
    }
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title, required this.palette});

  final String title;
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: SettingsScreen._gold,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: TextStyle(
            color: palette.primaryText,
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.palette, required this.children});

  final _SettingsPalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: palette.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: palette.isDark ? 0.13 : 0.035,
            ),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onTap,
    this.trailing,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _SettingsPalette palette;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: SettingsScreen._gold.withValues(
                          alpha: palette.isDark ? 0.18 : 0.115,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: SettingsScreen._gold, size: 22),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: palette.primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.secondaryText,
                              fontSize: 11.8,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    trailing ??
                        Icon(
                          Icons.chevron_left_rounded,
                          color: palette.secondaryText.withValues(alpha: 0.8),
                          size: 23,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 73, end: 14),
            child: Divider(height: 1, thickness: 0.75, color: palette.border),
          ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.palette, required this.onTap});

  final _SettingsPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: palette.isDark
                ? const Color(0xFF2B1717)
                : const Color(0xFFFFF2F2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: palette.isDark
                  ? const Color(0xFF4A2525)
                  : const Color(0xFFFFD8D8),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFD84A4A), size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: Color(0xFFD84A4A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFFD84A4A),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsPalette {
  const _SettingsPalette({
    required this.isDark,
    required this.background,
    required this.card,
    required this.primaryText,
    required this.secondaryText,
    required this.border,
  });

  factory _SettingsPalette.fromBrightness(bool isDark) {
    if (isDark) {
      return const _SettingsPalette(
        isDark: true,
        background: Color(0xFF121212),
        card: Color(0xFF1E1E1E),
        primaryText: Color(0xFFEAEAEA),
        secondaryText: Color(0xFF9CA3AF),
        border: Color(0xFF2A2A2A),
      );
    }

    return const _SettingsPalette(
      isDark: false,
      background: Color(0xFFF5F5F5),
      card: Color(0xFFFFFFFF),
      primaryText: Color(0xFF1C1C1C),
      secondaryText: Color(0xFF6B7280),
      border: Color(0xFFE5E7EB),
    );
  }

  final bool isDark;
  final Color background;
  final Color card;
  final Color primaryText;
  final Color secondaryText;
  final Color border;
}
