import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

class GlCard extends StatelessWidget {
  const GlCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.borderRadius = AppRadius.extraLarge,
    this.showShadow = true,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final bool showShadow;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveColor =
        color ?? (isDark ? const Color(0xFF171717) : const Color(0xFFFAF9F7));

    final decoration = BoxDecoration(
      color: effectiveColor,
      borderRadius: borderRadius,
      boxShadow: showShadow ? AppShadows.medium(isDark: isDark) : null,
    );

    final content = Ink(padding: padding, decoration: decoration, child: child);

    final card = Material(
      color: Colors.transparent,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: borderRadius, child: content),
    );

    if (margin == null) {
      return card;
    }

    return Padding(padding: margin!, child: card);
  }
}
