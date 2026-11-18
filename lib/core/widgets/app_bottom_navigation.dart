import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_motion.dart';
import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/bottom_panel_surface.dart';

enum BottomNavStyle { soft, labels }

enum BottomNavDestination {
  today('/today', 'Today', LucideIcons.calendarCheck),
  upcoming('/upcoming', 'Upcoming', LucideIcons.calendarDays),
  focus('/focus', 'Focus', LucideIcons.timer),
  projects('/projects', 'Projects', LucideIcons.folder),
  calendar('/calendar', 'Calendar', LucideIcons.calendar),
  timeline('/timeline', 'Timeline', LucideIcons.ganttChart),
  kanban('/kanban', 'Kanban', LucideIcons.columns3),
  priorityMatrix('/priority-matrix', 'Matrix', LucideIcons.layoutGrid),
  habits('/habits', 'Habits', LucideIcons.repeat),
  reports('/reports', 'Reports', LucideIcons.chartColumn),
  search('/search', 'Search', LucideIcons.search),
  browse('/browse', 'Browse', LucideIcons.listChecks),
  settings('/settings', 'Settings', LucideIcons.settings);

  const BottomNavDestination(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;

  bool matches(String location) {
    final clean = Uri.tryParse(location)?.path ?? location;
    return clean == path ||
        clean.startsWith('$path/') ||
        (this == projects &&
            (clean.startsWith('/project/') || clean.startsWith('/label/')));
  }
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.destinations,
    required this.style,
    required this.currentLocation,
    required this.onSelect,
    this.onLongPressEdit,
    super.key,
  });

  static const defaultDestinations = <BottomNavDestination>[
    BottomNavDestination.today,
    BottomNavDestination.upcoming,
    BottomNavDestination.focus,
    BottomNavDestination.projects,
    BottomNavDestination.calendar,
  ];

  final List<BottomNavDestination> destinations;
  final BottomNavStyle style;
  final String currentLocation;
  final ValueChanged<BottomNavDestination> onSelect;
  final VoidCallback? onLongPressEdit;

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final duration = AppMotion.duration(context, AppMotion.navigation);

    return BottomPanelSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final dest in destinations.take(5))
              _buildButton(
                context: context,
                dest: dest,
                selected: dest.matches(currentLocation),
                colors: colors,
                textTheme: textTheme,
                duration: duration,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required BottomNavDestination dest,
    required bool selected,
    required AppThemePalette colors,
    required TextTheme textTheme,
    required Duration duration,
  }) {
    if (style == BottomNavStyle.soft) {
      return Flexible(
        flex: selected ? 2 : 1,
        child: Tooltip(
          message: dest.label,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelect(dest),
            onLongPress: onLongPressEdit,
            child: AnimatedContainer(
              duration: duration,
              curve: AppMotion.navigationCurve,
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 12 : 10,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected ? colors.accentTint : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    dest.icon,
                    size: 19,
                    color: selected ? colors.accent : colors.secondaryText,
                  ),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        dest.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // With labels style
    final horizontal = destinations.length <= 2;
    return Expanded(
      child: Tooltip(
        message: dest.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelect(dest),
          onLongPress: onLongPressEdit,
          child: AnimatedContainer(
            duration: duration,
            curve: AppMotion.navigationCurve,
            constraints: BoxConstraints(
              minHeight: horizontal ? 48 : 56,
              minWidth: 44,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? colors.accentTint : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: horizontal
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        dest.icon,
                        size: 18,
                        color: selected ? colors.accent : colors.secondaryText,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          dest.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            color:
                                selected ? colors.accent : colors.secondaryText,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        dest.icon,
                        size: 18,
                        color: selected ? colors.accent : colors.secondaryText,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dest.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color:
                              selected ? colors.accent : colors.secondaryText,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
