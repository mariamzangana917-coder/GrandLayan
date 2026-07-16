import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_colors.dart';
import 'theme_mode_notifier.dart';

class LuxuryThemeToggle extends ConsumerWidget {
  const LuxuryThemeToggle({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Semantics(
      button: true,
      label: isDark ? 'تفعيل الوضع النهاري' : 'تفعيل الوضع الليلي',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            ref.read(themeModeProvider.notifier).toggle();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF101010) : Colors.white,
              border: Border.all(color: AppColors.gold, width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: isDark ? 0.14 : 0.10),
                  blurRadius: 8,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey<bool>(isDark),
                size: size * 0.49,
                color: isDark ? const Color(0xFFD5D7DC) : AppColors.gold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
