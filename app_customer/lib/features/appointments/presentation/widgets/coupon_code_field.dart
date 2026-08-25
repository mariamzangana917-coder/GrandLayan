import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CouponCodeField extends StatelessWidget {
  const CouponCodeField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color borderColor = isDark
        ? const Color(0xFF303030)
        : const Color(0xFFE7E1D8);
    final Color textColor = isDark
        ? const Color(0xFFF1F1F1)
        : const Color(0xFF1C1C1C);
    final Color hintColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF77716C);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'كود الخصم',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اختياري، ويتم التحقق منه عند إرسال الحجز.',
            textAlign: TextAlign.right,
            style: TextStyle(color: hintColor, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey<String>('booking-coupon-code-field'),
            controller: controller,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 50,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
              LengthLimitingTextInputFormatter(50),
            ],
            decoration: InputDecoration(
              counterText: '',
              hintText: 'WELCOME20',
              prefixIcon: const Icon(
                Icons.confirmation_number_outlined,
                color: Color(0xFFC9A227),
              ),
              suffixIcon: IconButton(
                tooltip: 'مسح الكود',
                onPressed: controller.clear,
                icon: Icon(Icons.close_rounded, size: 19, color: hintColor),
              ),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFC9A227),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
