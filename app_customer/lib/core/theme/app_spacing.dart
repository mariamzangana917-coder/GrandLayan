import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double giant = 48;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  static const EdgeInsets cardPadding =
      EdgeInsets.all(16);

  static const EdgeInsets dialogPadding =
      EdgeInsets.all(24);

  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 14,
  );
}