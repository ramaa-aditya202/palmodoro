import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_editor_sheet.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_list_item.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  DateTime _anchorDay = dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final taskStore = context.watch<TaskStore>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final today = dateOnly(DateTime.now());
    final dayBuckets = taskStore.upcomingByDay(_anchorDay, days: 14);

    return Column(
      children: [
        CompactShellHeader(
          title: 'Upcoming',
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
          trailing: [
            if (!isSameCalendarDay(_anchorDay, today))
              IconButton(
                tooltip: 'Back to today',
                onPressed: () => setState(() => _anchorDay = today),
                icon: Icon(
                  LucideIcons.calendarCheck,
                  size: 18,
                  color: colors.accent,
                ),
              ),
          ],
        ),
        // Horizontal 14-day interactive date strip
        Container(
          height: 68,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: 14,
            itemBuilder: (context, index) {
              final day = DateTime(
                today.year,
                today.month,
                today.day + index,
              );
              final selected = isSameCalendarDay(day, _anchorDay);
              final count = taskStore.tasksForDay(day).length;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _anchorDay = day),
                  child: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      color: selected ? colors.accentTint : colors.surfaceTint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? colors.accent : colors.border,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(day),
                          style: textTheme.labelSmall?.copyWith(
                            color: selected
                                ? colors.accent
                                : colors.secondaryText,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: textTheme.titleSmall
                              ?.merge(AppTheme.monoTextStyle)
                              .copyWith(
                                color: selected
                                    ? colors.accent
                                    : colors.primaryText,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (count > 0)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
            children: [
              for (final entry in dayBuckets.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDayHeader(entry.key, today),
                          style: textTheme.titleSmall?.copyWith(
                            color: isSameCalendarDay(entry.key, today)
                                ? colors.accent
                                : colors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Schedule task',
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => TaskEditorSheet.show(
                          context,
                          initialDueAt: entry.key,
                        ),
                        icon: Icon(
                          LucideIcons.plus,
                          size: 16,
                          color: colors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry.value.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No tasks scheduled',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                  )
                else
                  for (final task in entry.value) TaskListItem(task: task),
                const Divider(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDayHeader(DateTime day, DateTime today) {
    final base = DateFormat('EEE, MMM d').format(day);
    if (isSameCalendarDay(day, today)) return 'Today · $base';
    if (isSameCalendarDay(day, today.add(const Duration(days: 1)))) {
      return 'Tomorrow · $base';
    }
    return base;
  }
}
