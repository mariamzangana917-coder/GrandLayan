import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  const AppRadius._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double xxl = 28;
  static const double pill = 999;

  static const BorderRadius extraSmall = BorderRadius.all(Radius.circular(xs));

  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));

  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));

  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));

  static const BorderRadius extraLarge = BorderRadius.all(Radius.circular(xl));

  static const BorderRadius huge = BorderRadius.all(Radius.circular(xxl));

  static const BorderRadius fullyRounded = BorderRadius.all(
    Radius.circular(pill),
  );
}
