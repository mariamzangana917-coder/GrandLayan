import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/luxury_theme_toggle.dart';
import '../../../core/theme/theme_mode_notifier.dart';
import '../providers/customer_auth_provider.dart';

class CustomerLoginPage extends ConsumerStatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  ConsumerState<CustomerLoginPage> createState() {
    return _CustomerLoginPageState();
  }
}

class _CustomerLoginPageState extends ConsumerState<CustomerLoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final success = await ref
        .read(customerAuthProvider.notifier)
        .login(
          login: _loginController.text,
          password: _passwordController.text,
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

    final message = error is ApiException
        ? error.firstErrorFor('login') ?? error.message
        : 'تعذر تسجيل الدخول. حاولي مجددًا.';

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
              child: CustomPaint(painter: _AuthLinesPainter(isDark: isDark)),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
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
                          const SizedBox(height: 18),
                          _AuthLogo(asset: logoAsset, isDark: isDark),
                          const SizedBox(height: 28),
                          _AuthTextField(
                            controller: _loginController,
                            label: 'البريد الإلكتروني أو رقم الهاتف',
                            hint: 'example@email.com',
                            icon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            isDark: isDark,
                            fieldColor: fieldColor,
                            textColor: textColor,
                            validator: (value) {
                              final input = value?.trim() ?? '';

                              if (input.isEmpty) {
                                return 'البريد الإلكتروني أو رقم الهاتف مطلوب.';
                              }

                              if (input.length > 255) {
                                return 'البيانات المدخلة طويلة جدًا.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _AuthTextField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            hint: '••••••••',
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
                              if (value == null || value.isEmpty) {
                                return 'كلمة المرور مطلوبة.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      ScaffoldMessenger.of(context)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'سنضيف استعادة كلمة المرور ضمن وحدة مستقلة.',
                                            ),
                                          ),
                                        );
                                    },
                              child: const Text(
                                'نسيتِ كلمة المرور؟',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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
                                disabledBackgroundColor: AppColors.gold
                                    .withValues(alpha: 0.55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                  side: const BorderSide(
                                    color: AppColors.gold,
                                    width: 1,
                                  ),
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
                                      'تسجيل الدخول',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ليس لديكِ حساب؟',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () {
                                        context.goNamed('customer-register');
                                      },
                                child: const Text(
                                  'إنشاء حساب',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo({required this.asset, required this.isDark});

  final String asset;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      child: SizedBox(
        width: 205,
        height: 145,
        child: ClipRect(
          child: Transform.scale(
            scale: isDark ? 1.12 : 1.10,
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
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
          color: isDark ? const Color(0xFFC9C9C9) : const Color(0xFF6C6C6C),
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF777777) : const Color(0xFFAAAAAA),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
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

class _AuthLinesPainter extends CustomPainter {
  const _AuthLinesPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: isDark ? 0.11 : 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var index = 0; index < 3; index++) {
      final topPath = Path()
        ..moveTo(-20, 70 + index * 16)
        ..cubicTo(
          size.width * 0.20,
          20 + index * 10,
          size.width * 0.40,
          55 + index * 8,
          size.width * 0.62,
          -20,
        );

      canvas.drawPath(topPath, paint);
    }

    for (var index = 0; index < 4; index++) {
      final bottomPath = Path()
        ..moveTo(size.width * 0.18, size.height + 15 - index * 10)
        ..cubicTo(
          size.width * 0.48,
          size.height * 0.94,
          size.width * 0.78,
          size.height * 0.84,
          size.width + 25,
          size.height * 0.78 - index * 12,
        );

      canvas.drawPath(bottomPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuthLinesPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
