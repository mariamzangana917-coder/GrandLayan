import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class BookingSuccessPriceSummary extends StatelessWidget {
  const BookingSuccessPriceSummary({
    required this.appointmentData,
    required this.reference,
    super.key,
  });

  final Object? appointmentData;
  final String reference;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = _asStringMap(appointmentData);
    final Map<String, dynamic> coupon = _asStringMap(data['coupon']);

    final double? subtotal = _toDouble(data['subtotal_amount']);
    final double discount = _toDouble(data['discount_amount']) ?? 0;
    final double? finalAmount = _toDouble(data['final_amount']);

    final String couponCode = _text(coupon['code']);
    final String couponName = _text(coupon['name']);
    final bool hasCoupon = couponCode.isNotEmpty || couponName.isNotEmpty;
    final bool hasPriceSummary = subtotal != null || finalAmount != null;

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color borderColor = isDark
        ? const Color(0xFF353535)
        : const Color(0xFFE7E1D8);
    final Color cardColor = isDark
        ? const Color(0xFF252525)
        : const Color(0xFFC9A227).withValues(alpha: 0.08);
    final Color secondaryText = theme.colorScheme.onSurfaceVariant;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            reference.trim().isEmpty
                ? 'وصل طلبچ إلى الإدارة، وسيتم تأكيد الموعد قريبًا.'
                : 'وصل طلبچ إلى الإدارة.\nرقم الحجز: ${reference.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.55),
          ),
          if (hasPriceSummary) ...<Widget>[
            const SizedBox(height: 18),
            Container(
              key: const ValueKey<String>('customer-booking-price-summary'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFFC9A227),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasCoupon ? 'تم تطبيق الخصم' : 'ملخص المبلغ',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasCoupon) ...<Widget>[
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'كود الخصم',
                      value: couponCode.isNotEmpty ? couponCode : couponName,
                      valueColor: const Color(0xFFC9A227),
                    ),
                    if (couponName.isNotEmpty && couponName != couponCode)
                      _SummaryRow(label: 'اسم الكوبون', value: couponName),
                  ],
                  if (subtotal != null)
                    _SummaryRow(
                      label: 'السعر قبل الخصم',
                      value: _formatMoney(subtotal),
                    ),
                  if (hasCoupon || discount > 0)
                    _SummaryRow(
                      label: 'قيمة الخصم',
                      value: '- ${_formatMoney(discount)}',
                      valueColor: const Color(0xFF2E7D32),
                    ),
                  if (finalAmount != null) ...<Widget>[
                    Divider(height: 20, color: borderColor),
                    _SummaryRow(
                      label: 'المبلغ النهائي',
                      value: _formatMoney(finalAmount),
                      emphasize: true,
                      valueColor: const Color(0xFFC9A227),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'المبلغ أعلاه محسوب ومؤكد من النظام بعد التحقق من الكوبون.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 10.8,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
                fontSize: emphasize ? 14.5 : 12.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: valueColor,
              fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
              fontSize: emphasize ? 15 : 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _asStringMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (Object? key, Object? item) => MapEntry(key.toString(), item),
    );
  }

  return const <String, dynamic>{};
}

double? _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.trim());
  }

  return null;
}

String _text(Object? value) {
  if (value == null) {
    return '';
  }

  final String text = value.toString().trim();
  return text.toLowerCase() == 'null' ? '' : text;
}

String _formatMoney(double value) {
  final NumberFormat formatter = value == value.roundToDouble()
      ? NumberFormat('#,##0', 'en')
      : NumberFormat('#,##0.##', 'en');

  return '${formatter.format(value)} د.ع';
}
