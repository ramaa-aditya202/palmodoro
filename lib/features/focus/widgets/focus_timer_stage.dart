import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/features/focus/models/focus_models.dart';

class FocusTimerVisual extends StatelessWidget {
  const FocusTimerVisual({
    required this.style,
    required this.remaining,
    required this.totalSeconds,
    required this.phaseLabel,
    required this.isWork,
    required this.compact,
    super.key,
  });

  final FocusTimerVisualStyle style;
  final Duration remaining;
  final int totalSeconds;
  final String phaseLabel;
  final bool isWork;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final progress = totalSeconds <= 0
        ? 1.0
        : (remaining.inSeconds / totalSeconds).clamp(0.0, 1.0);
    final activeColor = isWork ? colors.accent : colors.success;
    final timeText = formatDurationDigital(remaining);

    if (style == FocusTimerVisualStyle.bar) {
      return Container(
        key: const Key('focus-timer-bar'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              phaseLabel.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: activeColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timeText,
              style: textTheme.displayMedium
                  ?.merge(AppTheme.monoTextStyle)
                  .copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: colors.surfaceHover,
                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
              ),
            ),
          ],
        ),
      );
    }

    final size = compact ? 220.0 : 256.0;
    return SizedBox(
      key: const Key('focus-timer-circle'),
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircleRingPainter(
          progress: progress,
          trackColor: colors.surfaceHover,
          activeColor: activeColor,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                phaseLabel.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: activeColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                timeText,
                style: textTheme.displaySmall
                    ?.merge(AppTheme.monoTextStyle)
                    .copyWith(
                      fontSize: compact ? 42 : 48,
                      color: colors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleRingPainter extends CustomPainter {
  const _CircleRingPainter({
    required this.progress,
    required this.trackColor,
    required this.activeColor,
  });

  final double progress;
  final Color trackColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.activeColor != activeColor;
}

class FocusRhythmRail extends StatelessWidget {
  const FocusRhythmRail({
    required this.display,
    required this.completedWorkIntervals,
    required this.intervalsBeforeLongBreak,
    required this.isRunningWork,
    super.key,
  });

  final FocusSessionDisplay display;
  final int completedWorkIntervals;
  final int intervalsBeforeLongBreak;
  final bool isRunningWork;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final total = intervalsBeforeLongBreak.clamp(1, 12);
    final cycleDone = completedWorkIntervals % total;

    if (display == FocusSessionDisplay.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceTint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          'Cycle $cycleDone / $total · Total $completedWorkIntervals',
          style: Theme.of(context).textTheme.labelMedium
              ?.merge(AppTheme.monoTextStyle)
              .copyWith(color: colors.secondaryText),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: i < cycleDone
                  ? colors.accentTint
                  : (i == cycleDone && isRunningWork
                        ? colors.surfaceHover
                        : colors.surfaceTint),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    (i < cycleDone || (i == cycleDone && isRunningWork))
                        ? colors.accent
                        : colors.border,
              ),
            ),
            child: Icon(
              i < cycleDone ? LucideIcons.check : LucideIcons.timer,
              size: 14,
              color: i <= cycleDone ? colors.accent : colors.secondaryText,
            ),
          ),
      ],
    );
  }
}
