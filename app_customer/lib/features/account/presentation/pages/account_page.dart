import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/luxury_theme_toggle.dart';
import '../../../../core/network/api_url.dart';
import '../../../auth/providers/customer_auth_provider.dart';
import 'edit_profile_page.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  Future<void> _openEditProfile(BuildContext context, WidgetRef ref) async {
    final customer = ref.read(customerAuthProvider).asData?.value;

    if (customer == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر تحميل بيانات الحساب.',
              textAlign: TextAlign.right,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditProfilePage(customer: customer)),
    );
  }

  void _showTemporaryMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'صفحة $feature راح نكملها ونربطها بالبيانات الحقيقية.',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              'تسجيل الخروج',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF1C1C1C),
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'هل أنتِ متأكدة من تسجيل الخروج من حسابكِ؟',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFB3B3B3)
                    : const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref.read(customerAuthProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(customerAuthProvider);

    final customer = authState.when(
      data: (value) => value,
      loading: () => null,
      error: (error, stackTrace) => null,
    );

    final isLoggingOut = authState.isLoading;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    final surfaceColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFFFFFFF);

    final elevatedSurfaceColor = isDark
        ? const Color(0xFF242424)
        : const Color(0xFFFFFFFF);

    final primaryTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1C1C1C);

    final secondaryTextColor = isDark
        ? const Color(0xFFB3B3B3)
        : const Color(0xFF6B7280);

    final borderColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFE5E7EB);

    final customerName = customer?.name.trim();

    final displayName = customerName == null || customerName.isEmpty
        ? 'ضيفتنا الجميلة'
        : customerName;

    final customerEmail = customer?.email.trim();

    final displayEmail = customerEmail == null || customerEmail.isEmpty
        ? 'لم تتم إضافة البريد الإلكتروني'
        : customerEmail;

    final customerPhone = customer?.phone.trim();

    final displayPhone = customerPhone == null || customerPhone.isEmpty
        ? 'لم تتم إضافة رقم الهاتف'
        : customerPhone;

    final String? avatarUrl = ApiUrl.resolveStorageUrl(customer?.avatar);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              _ProfileCard(
                name: displayName,
                email: displayEmail,
                phone: displayPhone,
                avatarUrl: avatarUrl,
                isDark: isDark,
                surfaceColor: surfaceColor,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 22),
              _SectionTitle(title: 'الحساب', textColor: primaryTextColor),
              const SizedBox(height: 10),
              _AccountMenuGroup(
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                children: [
                  _AccountMenuTile(
                    title: 'بياناتي',
                    subtitle: 'الاسم ورقم الهاتف والبريد الإلكتروني والصورة',
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.gold,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    borderColor: borderColor,
                    onTap: () {
                      _openEditProfile(context, ref);
                    },
                  ),
                  _AccountMenuTile(
                    title: 'مواعيدي',
                    subtitle: 'المواعيد القادمة والسابقة والملغاة',
                    icon: Icons.calendar_month_outlined,
                    iconColor: AppColors.info,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    borderColor: borderColor,
                    onTap: () {
                      context.pushNamed('customer-appointments');
                    },
                  ),
                  _AccountMenuTile(
                    title: 'الفواتير',
                    subtitle: 'تفاصيل المدفوعات والفواتير السابقة',
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.reports,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    borderColor: borderColor,
                    showDivider: false,
                    onTap: () {
                      _showTemporaryMessage(context, 'الفواتير');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _SectionTitle(
                title: 'الهدايا والإعدادات',
                textColor: primaryTextColor,
              ),
              const SizedBox(height: 10),
              _AccountMenuGroup(
                surfaceColor: elevatedSurfaceColor,
                borderColor: borderColor,
                children: [
                  _AccountMenuTile(
                    title: 'بطاقات الهدايا',
                    subtitle: 'شراء وإدارة بطاقات الهدايا',
                    icon: Icons.card_giftcard_rounded,
                    iconColor: AppColors.gold,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    borderColor: borderColor,
                    onTap: () {
                      context.pushNamed('gift-cards');
                    },
                  ),
                  _AccountMenuTile(
                    title: 'الإشعارات',
                    subtitle: 'تذكيرات المواعيد والعروض الجديدة',
                    icon: Icons.notifications_none_rounded,
                    iconColor: AppColors.info,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    borderColor: borderColor,
                    onTap: () {
                      _showTemporaryMessage(context, 'إعدادات الإشعارات');
                    },
                  ),
                  _AccountMenuTile(
                    title: 'الوضع الليلي',
                    subtitle: isDark ? 'مفعّل الآن' : 'غير مفعّل',
                    icon: isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    iconColor: AppColors.gold,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    borderColor: borderColor,
                    trailing: _ThemeStatusControl(isDark: isDark),
                  ),
                  _AccountMenuTile(
                    title: 'الخصوصية والأمان',
                    subtitle: 'إعدادات الحساب وحماية البيانات',
                    icon: Icons.lock_outline_rounded,
                    iconColor: AppColors.success,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    borderColor: borderColor,
                    showDivider: false,
                    onTap: () {
                      context.pushNamed('privacy-security');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: isLoggingOut
                      ? null
                      : () {
                          _confirmLogout(context, ref);
                        },
                  icon: isLoggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error,
                          ),
                        )
                      : const Icon(Icons.logout_rounded),
                  label: Text(
                    isLoggingOut ? 'جاري تسجيل الخروج...' : 'تسجيل الخروج',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Grand Layan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.isDark,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.borderColor,
  });

  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final bool isDark;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _AccountAvatar(avatarUrl: avatarUrl, isDark: isDark),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: secondaryTextColor, fontSize: 12.5),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: secondaryTextColor, fontSize: 11.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.avatarUrl, required this.isDark});

  final String? avatarUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold.withValues(alpha: isDark ? 0.15 : 0.10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
      ),
      child: ClipOval(
        child: avatarUrl == null
            ? Container(
                color: AppColors.gold.withValues(alpha: isDark ? 0.13 : 0.08),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.gold,
                  size: 35,
                ),
              )
            : Image.network(
                avatarUrl!,
                width: 67,
                height: 67,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.gold.withValues(
                      alpha: isDark ? 0.13 : 0.08,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.gold,
                      size: 35,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child: SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.textColor});

  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AccountMenuGroup extends StatelessWidget {
  const _AccountMenuGroup({
    required this.surfaceColor,
    required this.borderColor,
    required this.children,
  });

  final Color surfaceColor;
  final Color borderColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(children: children),
      ),
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.borderColor,
    this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing ??
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: secondaryTextColor,
                        size: 15,
                      ),
                ],
              ),
            ),
            if (showDivider)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 70),
                child: Divider(height: 1, thickness: 1, color: borderColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeStatusControl extends StatelessWidget {
  const _ThemeStatusControl({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const controlWidth = 54.0;
    const controlHeight = 32.0;
    const thumbSize = 26.0;

    final trackColor = isDark ? AppColors.gold : const Color(0xFFE5E7EB);

    final thumbIconColor = isDark ? AppColors.gold : const Color(0xFF6B7280);

    return Semantics(
      button: true,
      toggled: isDark,
      label: isDark ? 'إيقاف الوضع الليلي' : 'تفعيل الوضع الليلي',
      child: SizedBox(
        width: controlWidth,
        height: controlHeight,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: controlWidth,
              height: controlHeight,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(controlHeight / 2),
                border: Border.all(
                  color: isDark ? AppColors.gold : const Color(0xFFD1D5DB),
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: isDark
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    size: 15,
                    color: thumbIconColor,
                  ),
                ),
              ),
            ),

            // نبقي نفس ربط تغيير الثيم الموجود بالمشروع،
            // لكن نخفي شكله القديم ونستخدمه كمنطقة ضغط فقط.
            const Positioned.fill(
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: 0,
                  child: LuxuryThemeToggle(size: controlWidth),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
