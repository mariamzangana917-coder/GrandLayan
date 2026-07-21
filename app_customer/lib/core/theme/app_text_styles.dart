import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  const AppTextStyles._();

  static TextStyle heading(
    BuildContext context,
  ) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return TextStyle(
      color: isDark
          ? Colors.white
          : AppColors.black,
      fontSize: 22,
      fontWeight: FontWeight.w800,
    );
  }

  static TextStyle title(
    BuildContext context,
  ) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return TextStyle(
      color: isDark
          ? Colors.white
          : AppColors.black,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle body(
    BuildContext context,
  ) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return TextStyle(
      color: isDark
          ? const Color(0xFFE6E6E6)
          : const Color(0xFF666666),
      fontSize: 14,
      height: 1.6,
    );
  }

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
}