import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/luxury_theme_toggle.dart';
import '../../../core/theme/theme_mode_notifier.dart';
import '../providers/customer_auth_provider.dart';

class CustomerRegisterPage extends ConsumerStatefulWidget {
  const CustomerRegisterPage({super.key});

  @override
  ConsumerState<CustomerRegisterPage> createState() {
    return _CustomerRegisterPageState();
  }
}

class _CustomerRegisterPageState extends ConsumerState<CustomerRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _phoneController = TextEditingController();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  final _passwordConfirmationController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('يجب الموافقة على الشروط والأحكام.')),
        );

      return;
    }

    final success = await ref
        .read(customerAuthProvider.notifier)
        .register(
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          password: _passwordController.text,
          passwordConfirmation: _passwordConfirmationController.text,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      context.goNamed('home');
      return;
    }

    final authState = ref.read(customerAuthProvider);

    final error = authState.error;

    String message = 'تعذر إنشاء الحساب. حاولي مجددًا.';

    if (error is ApiException) {
      message =
          error.firstErrorFor('phone') ??
          error.firstErrorFor('email') ??
          error.firstErrorFor('password') ??
          error.firstErrorFor('name') ??
          error.message;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final authState = ref.watch(customerAuthProvider);

    final isSubmitting = authState.isLoading;

    final backgroundColor = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    final textColor = isDark ? Colors.white : const Color(0xFF161616);

    final secondaryTextColor = isDark
        ? const Color(0xFFB9B9B9)
        : const Color(0xFF737373);

    final fieldColor = isDark
        ? const Color(0xFF101010)
        : const Color(0xFFF8F8F8);

    final logoAsset = isDark
        ? 'assets/images/logo_dark.jpg'
        : 'assets/images/logo_light.jpg';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: backgroundColor)),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _RegisterLinesPainter(isDark: isDark),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  context.pop();
                                },
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: textColor,
                            size: 21,
                          ),
                        ),
                        const Spacer(),
                        const LuxuryThemeToggle(size: 34),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ColoredBox(
                      color: backgroundColor,
                      child: SizedBox(
                        width: 172,
                        height: 118,
                        child: ClipRect(
                          child: Transform.scale(
                            scale: isDark ? 1.12 : 1.10,
                            child: Image.asset(
                              logoAsset,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _RegisterField(
                      controller: _nameController,
                      label: 'الاسم الكامل',
                      hint: 'اكتبي اسمكِ الكامل',
                      icon: Icons.badge_outlined,
                      isDark: isDark,
                      fieldColor: fieldColor,
                      textColor: textColor,
                      validator: (value) {
                        final input = value?.trim() ?? '';

                        if (input.isEmpty) {
                          return 'الاسم الكامل مطلوب.';
                        }

                        if (input.length < 2) {
                          return 'يجب ألا يقل الاسم عن حرفين.';
                        }

                        if (input.length > 100) {
                          return 'الاسم طويل جدًا.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _RegisterField(
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      hint: '07XXXXXXXXX',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isDark: isDark,
                      fieldColor: fieldColor,
                      textColor: textColor,
                      validator: (value) {
                        final input = value?.replaceAll(' ', '').trim() ?? '';

                        if (input.isEmpty) {
                          return 'رقم الهاتف مطلوب.';
                        }

                        final validPhone = RegExp(
                          r'^07[3-9][0-9]{8}$',
                        ).hasMatch(input);

                        if (!validPhone) {
                          return 'رقم الهاتف العراقي غير صالح.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _RegisterField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      hint: 'example@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isDark: isDark,
                      fieldColor: fieldColor,
                      textColor: textColor,
                      validator: (value) {
                        final input = value?.trim() ?? '';

                        if (input.isEmpty) {
                          return 'البريد الإلكتروني مطلوب.';
                        }

                        final validEmail = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(input);

                        if (!validEmail) {
                          return 'صيغة البريد الإلكتروني غير صحيحة.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _RegisterField(
                      controller: _passwordController,
                      label: 'كلمة المرور',
                      hint: '8 أحرف على الأقل',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      isDark: isDark,
                      fieldColor: fieldColor,
                      textColor: textColor,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.gold,
                        ),
                      ),
                      validator: (value) {
                        final input = value ?? '';

                        if (input.isEmpty) {
                          return 'كلمة المرور مطلوبة.';
                        }

                        if (input.length < 8) {
                          return 'يجب ألا تقل كلمة المرور عن 8 أحرف.';
                        }

                        if (!RegExp(r'[A-Z]').hasMatch(input)) {
                          return 'يجب أن تحتوي على حرف إنجليزي كبير.';
                        }

                        if (!RegExp(r'[a-z]').hasMatch(input)) {
                          return 'يجب أن تحتوي على حرف إنجليزي صغير.';
                        }

                        if (!RegExp(r'[0-9]').hasMatch(input)) {
                          return 'يجب أن تحتوي على رقم واحد على الأقل.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _RegisterField(
                      controller: _passwordConfirmationController,
                      label: 'تأكيد كلمة المرور',
                      hint: 'أعيدي كتابة كلمة المرور',
                      icon: Icons.lock_reset_rounded,
                      obscureText: _obscureConfirmation,
                      isDark: isDark,
                      fieldColor: fieldColor,
                      textColor: textColor,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmation = !_obscureConfirmation;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmation
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.gold,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'تأكيد كلمة المرور مطلوب.';
                        }

                        if (value != _passwordController.text) {
                          return 'تأكيد كلمة المرور غير مطابق.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CheckboxListTile(
                      value: _acceptedTerms,
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                _acceptedTerms = value ?? false;
                              });
                            },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'أوافق على ',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                            const TextSpan(
                              text: 'الشروط والأحكام وسياسة الخصوصية',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(fontSize: 13.5, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: isDark
                              ? AppColors.gold
                              : AppColors.black,
                          foregroundColor: isDark
                              ? AppColors.black
                              : AppColors.lightGold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                            side: const BorderSide(color: AppColors.gold),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: isDark
                                      ? AppColors.black
                                      : AppColors.lightGold,
                                ),
                              )
                            : const Text(
                                'إنشاء الحساب',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'لديكِ حساب بالفعل؟',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  context.goNamed('customer-login');
                                },
                          child: const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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
}

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.fieldColor,
    required this.textColor,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final Color fieldColor;
  final Color textColor;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      validator: validator,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.gold),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fieldColor,
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFFC8C8C8) : const Color(0xFF6C6C6C),
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF777777) : const Color(0xFFAAAAAA),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(17)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: AppColors.gold.withValues(alpha: isDark ? 0.40 : 0.28),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
      ),
    );
  }
}

class _RegisterLinesPainter extends CustomPainter {
  const _RegisterLinesPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: isDark ? 0.10 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var index = 0; index < 3; index++) {
      final path = Path()
        ..moveTo(-20, 80 + index * 14)
        ..cubicTo(
          size.width * 0.22,
          20 + index * 10,
          size.width * 0.44,
          60 + index * 8,
          size.width * 0.65,
          -20,
        );

      canvas.drawPath(path, paint);
    }

    for (var index = 0; index < 4; index++) {
      final path = Path()
        ..moveTo(size.width * 0.18, size.height + 12 - index * 9)
        ..cubicTo(
          size.width * 0.50,
          size.height * 0.95,
          size.width * 0.80,
          size.height * 0.85,
          size.width + 25,
          size.height * 0.79 - index * 12,
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RegisterLinesPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
