import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/customer_auth_provider.dart';

class PrivacySecurityPage extends ConsumerStatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  ConsumerState<PrivacySecurityPage> createState() =>
      _PrivacySecurityPageState();
}

class _PrivacySecurityPageState
    extends ConsumerState<PrivacySecurityPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text ==
        _currentPasswordController.text) {
      _showMessage(
        'كلمة المرور الجديدة يجب أن تختلف عن الحالية.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(customerAuthProvider.notifier)
          .changePassword(
            currentPassword:
                _currentPasswordController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation:
                _confirmationController.text,
          );

      if (!mounted) return;

      _currentPasswordController.clear();
      _passwordController.clear();
      _confirmationController.clear();

      _showMessage('تم تغيير كلمة المرور بنجاح.');

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _errorMessage(error),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _errorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('current_password') ||
        message.contains('current password') ||
        message.contains('incorrect password') ||
        message.contains('unauthorized')) {
      return 'كلمة المرور الحالية غير صحيحة.';
    }

    if (message.contains('password_confirmation') ||
        message.contains('confirmation')) {
      return 'تأكيد كلمة المرور غير مطابق.';
    }

    if (message.contains('different')) {
      return 'كلمة المرور الجديدة يجب أن تختلف عن الحالية.';
    }

    if (message.contains('min')) {
      return 'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل.';
    }

    if (message.contains('422')) {
      return 'البيانات المدخلة غير صحيحة. تحقق من الحقول وحاول مرة أخرى.';
    }

    return 'تعذر تغيير كلمة المرور. حاول مرة أخرى.';
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? AppColors.error : null,
        ),
      );
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _PageColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: colors.primary,
        ),
        title: Text(
          'الخصوصية والأمان',
          style: TextStyle(
            color: colors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              32,
            ),
            children: [
              _SecurityHeader(
                colors: colors,
              ),

              const SizedBox(height: 26),

              _SectionLabel(
                title: 'أمان الحساب',
                color: colors.primary,
              ),

              const SizedBox(height: 10),

              _MenuCard(
                colors: colors,
                children: [
                  _MenuTile(
                    icon: Icons.lock_outline_rounded,
                    iconColor: AppColors.gold,
                    title: 'تغيير كلمة المرور',
                    subtitle:
                        'تحديث كلمة المرور الخاصة بحسابك',
                    primaryTextColor: colors.primary,
                    secondaryTextColor: colors.secondary,
                    onTap: () {
                      _openPage(
                        _ChangePasswordPage(
                          formKey: _formKey,
                          currentPasswordController:
                              _currentPasswordController,
                          passwordController:
                              _passwordController,
                          confirmationController:
                              _confirmationController,
                          obscureCurrentPassword:
                              _obscureCurrentPassword,
                          obscurePassword:
                              _obscurePassword,
                          obscureConfirmation:
                              _obscureConfirmation,
                          isSubmitting: _isSubmitting,
                          onToggleCurrent: () {
                            setState(() {
                              _obscureCurrentPassword =
                                  !_obscureCurrentPassword;
                            });
                          },
                          onTogglePassword: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                          onToggleConfirmation: () {
                            setState(() {
                              _obscureConfirmation =
                                  !_obscureConfirmation;
                            });
                          },
                          onSubmit: _changePassword,
                        ),
                      );
                    },
                  ),

                  _MenuDivider(
                    color: colors.border,
                  ),

                  _MenuTile(
                    icon: Icons.devices_outlined,
                    iconColor: AppColors.info,
                    title: 'الجلسات والأجهزة',
                    subtitle:
                        'إدارة الأجهزة التي تستخدم حسابك',
                    primaryTextColor: colors.primary,
                    secondaryTextColor: colors.secondary,
                    onTap: () {
                      _openPage(
                        const _SessionsPage(),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 26),

              _SectionLabel(
                title: 'الخصوصية',
                color: colors.primary,
              ),

              const SizedBox(height: 10),

              _MenuCard(
                colors: colors,
                children: [
                  _MenuTile(
                    icon: Icons.shield_outlined,
                    iconColor: AppColors.success,
                    title: 'سياسة الخصوصية',
                    subtitle:
                        'تعرف على كيفية حماية واستخدام بياناتك',
                    primaryTextColor: colors.primary,
                    secondaryTextColor: colors.secondary,
                    onTap: () {
                      _openPage(
                        const _PrivacyPolicyPage(),
                      );
                    },
                  ),

                  _MenuDivider(
                    color: colors.border,
                  ),

                  _MenuTile(
                    icon: Icons.description_outlined,
                    iconColor: AppColors.gold,
                    title: 'الشروط والأحكام',
                    subtitle:
                        'الشروط المنظمة لاستخدام Grand Layan',
                    primaryTextColor: colors.primary,
                    secondaryTextColor: colors.secondary,
                    onTap: () {
                      _openPage(
                        const _TermsPage(),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 26),

              _SectionLabel(
                title: 'إدارة الحساب',
                color: colors.primary,
              ),

              const SizedBox(height: 10),

              _MenuCard(
                colors: colors,
                children: [
                  _MenuTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.error,
                    title: 'حذف الحساب',
                    subtitle:
                        'حذف حسابك وبياناتك بشكل نهائي',
                    primaryTextColor: colors.primary,
                    secondaryTextColor: colors.secondary,
                    showArrow: false,
                    onTap: () {
                      _showDeleteAccountDialog(
                        context,
                        colors,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                'Grand Layan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    _PageColors colors,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              22,
              10,
              22,
              28,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.secondary
                          .withValues(alpha: 0.35),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.error
                          .withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 31,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'حذف الحساب',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'سيؤدي حذف الحساب إلى إزالة بيانات حسابك بشكل نهائي. لا يمكن التراجع عن هذا الإجراء بعد تنفيذه.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.secondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error
                          .withValues(alpha: 0.07),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'تأكد من رغبتك قبل المتابعة. حذف الحساب إجراء نهائي وليس تسجيل خروج.',
                            style: TextStyle(
                              color: colors.secondary,
                              fontSize: 11.5,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();

                        _showMessage(
                          'حذف الحساب يحتاج إلى ربط عملية الحذف الآمنة مع الخادم.',
                          isError: true,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'متابعة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          color: colors.secondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// PAGE COLORS
// ============================================================

class _PageColors {
  _PageColors(BuildContext context)
      : isDark =
            Theme.of(context).brightness == Brightness.dark;

  final bool isDark;

  Color get background =>
      isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF6F6F6);

  Color get surface =>
      isDark
          ? const Color(0xFF1D1D1D)
          : Colors.white;

  Color get primary =>
      isDark
          ? Colors.white
          : const Color(0xFF202020);

  Color get secondary =>
      isDark
          ? const Color(0xFFAAAAAA)
          : const Color(0xFF777777);

  Color get border =>
      isDark
          ? const Color(0xFF303030)
          : const Color(0xFFE8E8E8);

  Color get softSurface =>
      isDark
          ? const Color(0xFF252525)
          : const Color(0xFFF8F8F8);
}

// ============================================================
// SECURITY HEADER
// ============================================================

class _SecurityHeader extends StatelessWidget {
  const _SecurityHeader({
    required this.colors,
  });

  final _PageColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(
                alpha: colors.isDark ? 0.13 : 0.09,
              ),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.gold,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'خصوصيتك وأمانك',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'تحكم بإعدادات الأمان والخصوصية الخاصة بحسابك.',
                  style: TextStyle(
                    color: colors.secondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION LABEL
// ============================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.color,
  });

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ============================================================
// MENU CARD
// ============================================================

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.colors,
    required this.children,
  });

  final _PageColors colors;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

// ============================================================
// MENU DIVIDER
// ============================================================

class _MenuDivider extends StatelessWidget {
  const _MenuDivider({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 70,
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color: color,
      ),
    );
  }
}

// ============================================================
// MENU TILE
// ============================================================

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
    this.showArrow = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      iconColor.withValues(alpha: 0.09),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              if (showArrow) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: secondaryTextColor,
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CHANGE PASSWORD PAGE
// ============================================================

class _ChangePasswordPage
    extends StatefulWidget {
  const _ChangePasswordPage({
    required this.formKey,
    required this.currentPasswordController,
    required this.passwordController,
    required this.confirmationController,
    required this.obscureCurrentPassword,
    required this.obscurePassword,
    required this.obscureConfirmation,
    required this.isSubmitting,
    required this.onToggleCurrent,
    required this.onTogglePassword,
    required this.onToggleConfirmation,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;

  final TextEditingController
      currentPasswordController;

  final TextEditingController passwordController;

  final TextEditingController
      confirmationController;

  final bool obscureCurrentPassword;
  final bool obscurePassword;
  final bool obscureConfirmation;

  final bool isSubmitting;

  final VoidCallback onToggleCurrent;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmation;

  final VoidCallback onSubmit;

  @override
  State<_ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState
    extends State<_ChangePasswordPage> {
  @override
  Widget build(BuildContext context) {
    final colors = _PageColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: colors.primary,
        ),
        title: Text(
          'تغيير كلمة المرور',
          style: TextStyle(
            color: colors.primary,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            physics:
                const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'تحديث كلمة المرور',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'أدخل كلمة المرور الحالية ثم اختر كلمة مرور جديدة لحسابك.',
                style: TextStyle(
                  color: colors.secondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius:
                      BorderRadius.circular(21),
                  border: Border.all(
                    color: colors.border,
                  ),
                ),
                child: Form(
                  key: widget.formKey,
                  child: Column(
                    children: [
                      _PasswordField(
                        controller:
                            widget
                                .currentPasswordController,
                        label:
                            'كلمة المرور الحالية',
                        obscureText:
                            widget
                                .obscureCurrentPassword,
                        onToggle:
                            widget.onToggleCurrent,
                      ),

                      const SizedBox(height: 14),

                      _PasswordField(
                        controller:
                            widget.passwordController,
                        label:
                            'كلمة المرور الجديدة',
                        obscureText:
                            widget.obscurePassword,
                        onToggle:
                            widget.onTogglePassword,
                        validatePassword: true,
                      ),

                      const SizedBox(height: 14),

                      _PasswordField(
                        controller:
                            widget
                                .confirmationController,
                        label:
                            'تأكيد كلمة المرور الجديدة',
                        obscureText:
                            widget
                                .obscureConfirmation,
                        onToggle:
                            widget
                                .onToggleConfirmation,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'يرجى تأكيد كلمة المرور.';
                          }

                          if (value !=
                              widget
                                  .passwordController
                                  .text) {
                            return 'تأكيد كلمة المرور غير مطابق.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 51,
                        child: FilledButton(
                          onPressed:
                              widget.isSubmitting
                                  ? null
                                  : widget.onSubmit,
                          style:
                              FilledButton.styleFrom(
                            backgroundColor:
                                AppColors.gold,
                            foregroundColor:
                                Colors.black,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                            ),
                          ),
                          child:
                              widget.isSubmitting
                                  ? const SizedBox(
                                      width: 21,
                                      height: 21,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'تغيير كلمة المرور',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PASSWORD FIELD
// ============================================================

class _PasswordField
    extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggle,
    this.validatePassword = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggle;
  final bool validatePassword;

  final String? Function(String?)?
      validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textDirection: TextDirection.ltr,
      textInputAction:
          TextInputAction.next,
      autofillHints: const [
        AutofillHints.password,
      ],
      validator: validator ??
          (value) {
            if (value == null ||
                value.isEmpty) {
              return 'هذا الحقل مطلوب.';
            }

            if (validatePassword &&
                value.length < 8) {
              return 'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل.';
            }

            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
    );
  }
}

// ============================================================
// SESSIONS PAGE
// ============================================================

class _SessionsPage
    extends StatelessWidget {
  const _SessionsPage();

  @override
  Widget build(BuildContext context) {
    final colors = _PageColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: colors.primary,
        ),
        title: Text(
          'الجلسات والأجهزة',
          style: TextStyle(
            color: colors.primary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            physics:
                const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              32,
            ),
            children: [
              Container(
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: colors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration:
                          BoxDecoration(
                        color: AppColors.gold
                            .withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: const Icon(
                        Icons.devices_outlined,
                        color:
                            AppColors.gold,
                        size: 27,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أجهزة تسجيل الدخول',
                            style: TextStyle(
                              color:
                                  colors.primary,
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'راجع الأجهزة التي تم تسجيل الدخول منها إلى حسابك.',
                            style: TextStyle(
                              color:
                                  colors.secondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: colors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration:
                          BoxDecoration(
                        color: AppColors.gold
                            .withValues(
                          alpha: 0.08,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons
                            .security_outlined,
                        color:
                            AppColors.gold,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'الجلسات النشطة',
                      style: TextStyle(
                        color:
                            colors.primary,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Text(
                      'سيتم عرض الجلسات والأجهزة الحقيقية المرتبطة بحسابك هنا عند توفر واجهة إدارة الجلسات من الخادم.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            colors.secondary,
                        fontSize: 12.5,
                        height: 1.7,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            colors.softSurface,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons
                                .verified_user_outlined,
                            color:
                                AppColors.success,
                            size: 19,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              'لن يتم عرض أجهزة أو جلسات وهمية. البيانات المعروضة يجب أن تأتي من الخادم الفعلي.',
                              style: TextStyle(
                                color:
                                    colors.secondary,
                                fontSize: 11.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'حماية الحساب',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration:
                          BoxDecoration(
                        color: AppColors.success
                            .withValues(
                          alpha: 0.09,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .verified_user_outlined,
                        color:
                            AppColors.success,
                        size: 21,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'لا تشارك كلمة المرور أو رموز تسجيل الدخول مع أي شخص.',
                        style: TextStyle(
                          color:
                              colors.secondary,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PRIVACY POLICY
// ============================================================

class _PrivacyPolicyPage
    extends StatelessWidget {
  const _PrivacyPolicyPage();

  @override
  Widget build(BuildContext context) {
    return const _InformationPage(
      title: 'سياسة الخصوصية',
      icon: Icons.shield_outlined,
      sections: [
        _InfoSection(
          title: 'خصوصيتك مهمة لنا',
          text:
              'نحرص في Grand Layan على التعامل مع بيانات المستخدمين بطريقة آمنة ومسؤولة، ونسعى إلى استخدام البيانات فقط للأغراض المرتبطة بتقديم خدمات التطبيق.',
        ),
        _InfoSection(
          title: 'البيانات الشخصية',
          text:
              'قد تشمل بيانات الحساب الاسم ورقم الهاتف والبريد الإلكتروني والصورة والبيانات المرتبطة بالحساب والمواعيد والخدمات التي يستخدمها العميل.',
        ),
        _InfoSection(
          title: 'استخدام البيانات',
          text:
              'تستخدم البيانات لتوفير خدمات التطبيق وإدارة الحسابات والمواعيد والحجوزات والإشعارات وتحسين تجربة المستخدم وتشغيل الخدمات المرتبطة بالمركز.',
        ),
        _InfoSection(
          title: 'حماية البيانات',
          text:
              'نطبق إجراءات تقنية وتنظيمية مناسبة للمساعدة في حماية بيانات المستخدم من الوصول أو الاستخدام أو التعديل غير المصرح به.',
        ),
        _InfoSection(
          title: 'المواعيد والحجوزات',
          text:
              'قد يتم الاحتفاظ ببيانات المواعيد والحجوزات اللازمة لإدارة الخدمة وتقديم سجل صحيح للعميل والمركز وفقًا لآلية تشغيل النظام.',
        ),
        _InfoSection(
          title: 'حقوق المستخدم',
          text:
              'يمكن للمستخدم إدارة بعض بيانات حسابه من خلال التطبيق، كما يمكنه طلب الإجراءات المتعلقة بحسابه وفق الإمكانيات والسياسات المعتمدة في Grand Layan.',
        ),
      ],
    );
  }
}

// ============================================================
// TERMS
// ============================================================

class _TermsPage
    extends StatelessWidget {
  const _TermsPage();

  @override
  Widget build(BuildContext context) {
    return const _InformationPage(
      title: 'الشروط والأحكام',
      icon: Icons.description_outlined,
      sections: [
        _InfoSection(
          title: 'استخدام التطبيق',
          text:
              'باستخدام Grand Layan فإنك توافق على استخدام التطبيق بطريقة قانونية ومسؤولة وعدم إساءة استخدام الخدمات أو محاولة الوصول إلى حسابات أو بيانات مستخدمين آخرين.',
        ),
        _InfoSection(
          title: 'الحساب',
          text:
              'أنت مسؤول عن صحة البيانات التي تقدمها وعن المحافظة على سرية بيانات الدخول الخاصة بحسابك، ويجب عدم مشاركة بيانات الدخول مع الآخرين.',
        ),
        _InfoSection(
          title: 'المواعيد والخدمات',
          text:
              'تخضع المواعيد والخدمات المتاحة للحالة الفعلية للمركز وسياسات الحجز والتعديل والإلغاء المعتمدة في Grand Layan.',
        ),
        _InfoSection(
          title: 'الأسعار والعروض',
          text:
              'الأسعار والعروض والباقات الظاهرة في التطبيق تعتمد على البيانات التي يتم نشرها وإدارتها من قبل Grand Layan وقد تتغير عند تحديث الخدمات.',
        ),
        _InfoSection(
          title: 'إساءة الاستخدام',
          text:
              'يُمنع استخدام التطبيق بطريقة تؤثر على أمن النظام أو خصوصية المستخدمين الآخرين أو سلامة الخدمات المقدمة.',
        ),
        _InfoSection(
          title: 'التحديثات',
          text:
              'قد يتم تحديث هذه الشروط عند الحاجة بما يتناسب مع تطوير خدمات Grand Layan، ويستمر استخدام التطبيق بعد التحديث وفق الشروط المحدثة.',
        ),
      ],
    );
  }
}

// ============================================================
// INFORMATION PAGE
// ============================================================

class _InformationPage
    extends StatelessWidget {
  const _InformationPage({
    required this.title,
    required this.icon,
    required this.sections,
  });

  final String title;
  final IconData icon;
  final List<_InfoSection> sections;

  @override
  Widget build(BuildContext context) {
    final colors = _PageColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: colors.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colors.primary,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            physics:
                const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            children: [
              Align(
                alignment:
                    Alignment.centerRight,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration:
                      BoxDecoration(
                    color: AppColors.gold
                        .withValues(
                      alpha: 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color:
                        AppColors.gold,
                    size: 28,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              ...sections.map(
                (section) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 16,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        17,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            colors.surface,
                        borderRadius:
                            BorderRadius.circular(
                          19,
                        ),
                        border: Border.all(
                          color:
                              colors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: TextStyle(
                              color:
                                  colors.primary,
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            section.text,
                            style: TextStyle(
                              color:
                                  colors.secondary,
                              fontSize: 12.5,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// INFO SECTION
// ============================================================

class _InfoSection {
  const _InfoSection({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;
}