import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class FixedBookingBar extends StatelessWidget {
  const FixedBookingBar({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    final Color dividerColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE5E7EB);

    return Material(
      color: backgroundColor,
      elevation: 14,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(top: BorderSide(color: dividerColor)),
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.calendar_month_outlined, size: 22),
              label: const Text(
                'احجزي الآن',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: isDark ? AppColors.gold : AppColors.black,
                foregroundColor: isDark ? AppColors.black : AppColors.lightGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
