import 'package:flutter/material.dart';

abstract final class AppShadows {
  const AppShadows._();

  static List<BoxShadow> small({required bool isDark}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ];
  }

  static List<BoxShadow> medium({required bool isDark}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.07),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static List<BoxShadow> large({required bool isDark}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.10),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }
}
