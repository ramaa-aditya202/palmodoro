import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';

class FocusCompletionCelebration extends StatelessWidget {
  const FocusCompletionCelebration({
    required this.completedCount,
    required this.onDismiss,
    super.key,
  });

  final int completedCount;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const Key('focus-completion-celebration'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.accentTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.accent),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.sparkles, color: colors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus interval complete!',
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$completedCount work interval${completedCount == 1 ? '' : 's'} completed in this session.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: onDismiss,
            icon: Icon(LucideIcons.x, size: 16, color: colors.secondaryText),
          ),
        ],
      ),
    );
  }
}
