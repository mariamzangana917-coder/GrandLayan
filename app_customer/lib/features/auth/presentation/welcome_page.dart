import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/luxury_theme_toggle.dart';
import '../../../core/theme/theme_mode_notifier.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _darkBackground = Color(0xFF000000);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final backgroundColor = isDark ? _darkBackground : _lightBackground;

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
              child: CustomPaint(painter: _ModernLinesPainter(isDark: isDark)),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final isShort = height < 720;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: height),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          width < 380 ? 20 : 26,
                          12,
                          width < 380 ? 20 : 26,
                          20,
                        ),
                        child: Column(
                          children: [
                            const Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: LuxuryThemeToggle(size: 34),
                            ),
                            SizedBox(height: isShort ? 22 : 34),
                            _LogoSection(
                              isDark: isDark,
                              logoAsset: logoAsset,
                              screenWidth: width,
                            ),
                            SizedBox(height: isShort ? 22 : 30),
                            Text(
                              'جمالك يبدأ من هنا',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: width < 380 ? 29 : 33,
                                height: 1.22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111111),
                                shadows: [
                                  Shadow(
                                    color: AppColors.gold.withValues(
                                      alpha: isDark ? 0.18 : 0.08,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'صالون وعيادة متكاملة لجمالكِ وعنايتكِ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15.5,
                                height: 1.65,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? const Color(0xFFB9B9B9)
                                    : const Color(0xFF767676),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _ModernDivider(isDark: isDark),
                            SizedBox(height: isShort ? 36 : 52),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: _PrimaryButton(
                                isDark: isDark,
                                onPressed: () {
                                  context.pushNamed('customer-login');
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: _SecondaryButton(
                                isDark: isDark,
                                onPressed: () {
                                  context.pushNamed('customer-register');
                                },
                              ),
                            ),
                            const Spacer(),
                            SizedBox(height: isShort ? 20 : 42),
                          ],
                        ),
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

class _LogoSection extends StatelessWidget {
  const _LogoSection({
    required this.isDark,
    required this.logoAsset,
    required this.screenWidth,
  });

  final bool isDark;
  final String logoAsset;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final logoWidth = screenWidth.clamp(220.0, 270.0);

    final exactBackground = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return ColoredBox(
      color: exactBackground,
      child: SizedBox(
        width: logoWidth,
        height: logoWidth * 0.78,
        child: ClipRect(
          child: Transform.scale(
            scale: isDark ? 1.12 : 1.10,
            child: Image.asset(
              logoAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernDivider extends StatelessWidget {
  const _ModernDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.lightGold : AppColors.gold;
    return SizedBox(
      width: 132,
      height: 12,
      child: CustomPaint(painter: _DividerPainter(color: color)),
    );
  }
}

class _DividerPainter extends CustomPainter {
  const _DividerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final left = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width * 0.40, size.height / 2);

    final right = Path()
      ..moveTo(size.width * 0.60, size.height / 2)
      ..lineTo(size.width, size.height / 2);

    canvas.drawPath(left, linePaint);
    canvas.drawPath(right, linePaint);

    final center = Offset(size.width / 2, size.height / 2);

    final diamondPaint = Paint()..color = color;

    final diamond = Path()
      ..moveTo(center.dx, center.dy - 4)
      ..lineTo(center.dx + 4, center.dy)
      ..lineTo(center.dx, center.dy + 4)
      ..lineTo(center.dx - 4, center.dy)
      ..close();

    canvas.drawPath(diamond, diamondPaint);
  }

  @override
  bool shouldRepaint(covariant _DividerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ModernLinesPainter extends CustomPainter {
  const _ModernLinesPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: isDark ? 0.18 : 0.17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final softPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: isDark ? 0.07 : 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    /*
     * الزخارف العلوية الحالية.
     */
    for (var index = 0; index < 3; index++) {
      final topPath = Path()
        ..moveTo(-30, size.height * (0.07 + index * 0.028))
        ..cubicTo(
          size.width * 0.10,
          size.height * (0.02 + index * 0.018),
          size.width * 0.26,
          size.height * (0.05 + index * 0.012),
          size.width * 0.39,
          -25,
        );

      canvas.drawPath(topPath, index == 0 ? mainPaint : softPaint);
    }

    final rightArc = Path()
      ..moveTo(size.width * 0.90, size.height * 0.09)
      ..cubicTo(
        size.width * 1.04,
        size.height * 0.16,
        size.width * 1.05,
        size.height * 0.29,
        size.width * 0.94,
        size.height * 0.37,
      );

    canvas.drawPath(rightArc, softPaint);

    /*
     * زخارف سفلية إضافية.
     */
    for (var index = 0; index < 4; index++) {
      final bottomPath = Path()
        ..moveTo(size.width * 0.24, size.height + 18 - index * 10)
        ..cubicTo(
          size.width * 0.47,
          size.height * (0.94 - index * 0.012),
          size.width * 0.76,
          size.height * (0.88 - index * 0.016),
          size.width + 28,
          size.height * (0.80 - index * 0.018),
        );

      canvas.drawPath(bottomPath, index == 0 ? mainPaint : softPaint);
    }

    /*
     * خطان خفيفان من الجهة المقابلة
     * * حتى يصير توازن بصري.
     */
    for (var index = 0; index < 2; index++) {
      final oppositePath = Path()
        ..moveTo(-20, size.height * (0.90 - index * 0.018))
        ..cubicTo(
          size.width * 0.18,
          size.height * (0.86 - index * 0.015),
          size.width * 0.34,
          size.height * (0.92 - index * 0.012),
          size.width * 0.52,
          size.height + 12 - index * 8,
        );

      canvas.drawPath(oppositePath, softPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ModernLinesPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.isDark, required this.onPressed});

  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.person_outline_rounded, size: 21),
        label: const Text(
          'تسجيل الدخول',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isDark ? AppColors.gold : AppColors.black,
          foregroundColor: isDark ? AppColors.black : AppColors.lightGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: AppColors.gold, width: 1),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.isDark, required this.onPressed});

  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.person_add_alt_1_outlined, size: 21),
        label: const Text(
          'إنشاء حساب',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          backgroundColor: isDark
              ? const Color(0xFF000000)
              : const Color(0xFFFFFFFF),
          side: const BorderSide(color: AppColors.gold, width: 1.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}
