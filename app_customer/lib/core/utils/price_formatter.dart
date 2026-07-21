import 'package:intl/intl.dart';

abstract final class PriceFormatter {
  static final NumberFormat _numberFormat = NumberFormat('#,###', 'en');

  static String formatIqd(num? value) {
    if (value == null) {
      return '—';
    }

    final int intValue = value.round();
    return '${_numberFormat.format(intValue)} د.ع';
  }

  static String formatPlain(num? value) {
    if (value == null) {
      return '—';
    }

    final int intValue = value.round();
    return _numberFormat.format(intValue);
  }

  const PriceFormatter._();
}