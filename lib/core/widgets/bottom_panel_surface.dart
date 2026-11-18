import 'package:flutter/material.dart';

import 'package:pomodoro_app/core/theme/app_theme.dart';

class BottomPanelSurface extends StatelessWidget {
  const BottomPanelSurface({
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 12),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}
