import 'package:flutter/material.dart';

class SalonHeader extends StatelessWidget {
  const SalonHeader({
    required this.onBackPressed,
    super.key,
    this.title = 'الصالون',
  });

  final String title;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          PositionedDirectional(
            start: 8,
            child: IconButton(
              tooltip: 'رجوع',
              onPressed: onBackPressed,
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
