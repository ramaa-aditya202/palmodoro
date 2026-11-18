import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';

class CompactShellHeader extends StatelessWidget {
  const CompactShellHeader({
    required this.title,
    required this.onOpenDrawer,
    this.trailing = const [],
    this.isTodayHeader = false,
    this.todayDate,
    this.leadingWing,
    this.trailingWing,
    this.subtitle,
    this.leadingIcon,
    this.leadingTooltip = 'Menu',
    super.key,
  });

  final String title;
  final VoidCallback onOpenDrawer;
  final List<Widget> trailing;
  final bool isTodayHeader;
  final DateTime? todayDate;
  final Widget? leadingWing;
  final Widget? trailingWing;
  final String? subtitle;
  final IconData? leadingIcon;
  final String leadingTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final date = todayDate ?? DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasWings = leadingWing != null || trailingWing != null;
        final stackedWings =
            hasWings &&
            (constraints.maxWidth < 420 ||
                MediaQuery.textScalerOf(context).scale(20) > 22);

        final leadingWidth =
            (!stackedWings && leadingWing != null) ? 144.0 : 48.0;
        final trailingButtonsWidth = math.max(1, trailing.length) * 44.0 +
            ((!stackedWings && trailingWing != null) ? 88.0 : 0.0);
        final sideWidth = math.max(leadingWidth, trailingButtonsWidth);

        return Container(
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: colors.canvas,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: sideWidth,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            tooltip: leadingTooltip,
                            onPressed: onOpenDrawer,
                            icon: Icon(
                              leadingIcon ?? LucideIcons.panelLeft,
                              size: 20,
                              color: colors.primaryText,
                            ),
                          ),
                        ),
                        if (!stackedWings && leadingWing != null)
                          Flexible(child: leadingWing!),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isTodayHeader
                        ? _TodayCenteredTitle(title: title, date: date)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                softWrap: false,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleLarge?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: colors.primaryText,
                                ),
                              ),
                              if (subtitle != null && !stackedWings)
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.secondaryText,
                                  ),
                                ),
                            ],
                          ),
                  ),
                  SizedBox(
                    width: sideWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!stackedWings && trailingWing != null)
                          Flexible(child: trailingWing!),
                        for (final widget in trailing)
                          SizedBox(width: 44, height: 44, child: widget),
                      ],
                    ),
                  ),
                ],
              ),
              if (stackedWings)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 84,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: leadingWing ?? const SizedBox.shrink(),
                        ),
                      ),
                      if (subtitle != null)
                        Expanded(
                          child: Text(
                            subtitle!,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.secondaryText,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      SizedBox(
                        width: 84,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: trailingWing ?? const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayCenteredTitle extends StatelessWidget {
  const _TodayCenteredTitle({required this.title, required this.date});

  final String title;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final weekday = DateFormat('EEE').format(date);
    final dayNum = DateFormat('d').format(date);
    final month = DateFormat('MMM').format(date);
    final dateStyle = textTheme.bodySmall?.copyWith(
      color: colors.secondaryText,
      fontWeight: FontWeight.w500,
      height: 1.0,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              weekday,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: dateStyle,
            ),
          ),
        ),
        Text(
          title,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.primaryText,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    dayNum,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primaryText,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    month,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: dateStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
