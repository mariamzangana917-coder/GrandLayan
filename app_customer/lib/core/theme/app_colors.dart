import 'package:flutter/material.dart';

abstract final class AppColors {
  const AppColors._();

  // الهوية الأساسية
  static const Color gold = Color(0xFFC9A227);
  static const Color black = Color(0xFF1C1C1C);
  static const Color white = Color(0xFFFFFFFF);

  // الوضع النهاري
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimaryText = Color(0xFF1C1C1C);
  static const Color lightSecondaryText = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);

  // الوضع الليلي
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkElevatedSurface = Color(0xFF242424);
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFB3B3B3);
  static const Color darkBorder = Color(0xFF2E2E2E);

  // ألوان الحالات
  static const Color success = Color(0xFF22C55E);
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color reports = Color(0xFF8B5CF6);

  // توافق مع الملفات القديمة حتى ما تنكسر الصفحات الحالية
  static const Color softBlack = darkSurface;
  static const Color offWhite = lightBackground;
  static const Color lightGold = Color(0xFFE3C75D);
  static const Color darkGold = Color(0xFF9A7B18);
}
