import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';

class GlAppBar extends StatelessWidget {
  const GlAppBar({
    required this.title,
    super.key,
    this.onBackPressed,
    this.actions = const <Widget>[],
    this.showBackButton = true,
  });

  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget> actions;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (showBackButton)
            PositionedDirectional(
              start: AppSpacing.sm,
              child: IconButton(
                tooltip: 'رجوع',
                onPressed:
                    onBackPressed ??
                    () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorScheme.onSurface,
                  size: 20,
                ),
              ),
            ),
          if (actions.isNotEmpty)
            PositionedDirectional(
              end: AppSpacing.sm,
              child: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
        ],
      ),
    );
  }
}
