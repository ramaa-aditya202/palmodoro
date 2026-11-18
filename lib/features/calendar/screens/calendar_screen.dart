import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/calendar/models/calendar_models.dart';
import 'package:pomodoro_app/features/calendar/store/calendar_store.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_editor_sheet.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_list_item.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarStore>();
    final taskStore = context.watch<TaskStore>();
    final colors = context.appColors;
    final selectedDate = calendar.selectedDate;
    final dayTasks = taskStore.tasksForDay(selectedDate, includeCompleted: true);

    return Column(
      children: [
        CompactShellHeader(
          title: 'Calendar',
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
          trailing: [
            IconButton(
              tooltip: 'Unscheduled tasks',
              onPressed: () => _showUnscheduledSheet(context, selectedDate),
              icon: const Icon(LucideIcons.inbox, size: 18),
            ),
            if (calendar.mobileMode == MobileCalendarMode.rhythm)
              IconButton(
                tooltip: 'Edit periods',
                onPressed: () => _showPeriodEditorDialog(context, calendar),
                icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
              ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
            children: [
              // 3 equal text segments: Day | Month | Rhythm
              SegmentedButton<MobileCalendarMode>(
                segments: [
                  for (final mode in MobileCalendarMode.values)
                    ButtonSegment(value: mode, label: Text(mode.label)),
                ],
                selected: {calendar.mobileMode},
                onSelectionChanged: (s) => calendar.setMobileMode(s.first),
              ),
              const SizedBox(height: 12),
              // Date navigation row + Schedule action
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous day',
                    onPressed: () => calendar.setSelectedDate(
                      selectedDate.subtract(const Duration(days: 1)),
                    ),
                    icon: const Icon(LucideIcons.chevronLeft, size: 18),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          calendar.setSelectedDate(dateOnly(DateTime.now())),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          DateFormat('EEE, MMM d, yyyy').format(selectedDate),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next day',
                    onPressed: () => calendar.setSelectedDate(
                      selectedDate.add(const Duration(days: 1)),
                    ),
                    icon: const Icon(LucideIcons.chevronRight, size: 18),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    key: const Key('calendar-schedule-button'),
                    onPressed: () => TaskEditorSheet.show(
                      context,
                      initialDueAt: selectedDate,
                    ),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Schedule'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (calendar.mobileMode == MobileCalendarMode.day)
                _MobileDayView(
                  selectedDate: selectedDate,
                  tasks: dayTasks,
                )
              else if (calendar.mobileMode == MobileCalendarMode.month)
                _MobileMonthView(
                  calendar: calendar,
                  taskStore: taskStore,
                  dayTasks: dayTasks,
                )
              else
                _MobileRhythmView(
                  calendar: calendar,
                  selectedDate: selectedDate,
                  dayTasks: dayTasks,
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showUnscheduledSheet(BuildContext context, DateTime selectedDate) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final taskStore = context.watch<TaskStore>();
        final unscheduled = taskStore.unscheduledTasks();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Unscheduled tasks (${unscheduled.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (unscheduled.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No unscheduled tasks.')),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final task in unscheduled)
                        ListTile(
                          title: Text(task.title),
                          trailing: OutlinedButton(
                            onPressed: () async {
                              await taskStore.updateTask(
                                task.copyWith(dueAt: selectedDate),
                              );
                            },
                            child: Text(
                              'Schedule ${DateFormat('MMM d').format(selectedDate)}',
                            ),
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

  Future<void> _showPeriodEditorDialog(
    BuildContext context,
    CalendarStore calendar,
  ) async {
    var draft = [...calendar.periods];
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Rhythm periods'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          errorText!,
                          style: TextStyle(color: context.appColors.error),
                        ),
                      ),
                    for (var i = 0; i < draft.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${draft[i].name} (${draft[i].timeRangeLabel})',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Earlier start',
                              onPressed: () {
                                setDialogState(() {
                                  draft[i] = draft[i].copyWith(
                                    startMinutes:
                                        (draft[i].startMinutes - 60).clamp(
                                          0,
                                          1380,
                                        ),
                                  );
                                });
                              },
                              icon: const Icon(Icons.remove, size: 16),
                            ),
                            IconButton(
                              tooltip: 'Later end',
                              onPressed: () {
                                setDialogState(() {
                                  draft[i] = draft[i].copyWith(
                                    endMinutes:
                                        (draft[i].endMinutes + 60).clamp(
                                          60,
                                          1440,
                                        ),
                                  );
                                });
                              },
                              icon: const Icon(Icons.add, size: 16),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final ok = await calendar.savePeriods(draft);
                    if (!ok) {
                      setDialogState(() {
                        errorText =
                            'Periods cannot overlap or have invalid ranges.';
                      });
                    } else if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MobileRhythmView extends StatelessWidget {
  const _MobileRhythmView({
    required this.calendar,
    required this.selectedDate,
    required this.dayTasks,
  });

  final CalendarStore calendar;
  final DateTime selectedDate;
  final List<TaskItem> dayTasks;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final groups = calendar.groupTasksByRhythm(dayTasks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // All-day section
        _RhythmSectionCard(
          title: 'All-day',
          subtitle: '${groups.allDay.length} tasks',
          tasks: groups.allDay,
          onAdd: () => TaskEditorSheet.show(
            context,
            initialDueAt: selectedDate,
          ),
        ),
        const SizedBox(height: 10),
        for (final period in calendar.periods) ...[
          _RhythmSectionCard(
            title: period.name,
            subtitle: period.timeRangeLabel,
            tasks: groups.byPeriodId[period.id] ?? const [],
            onAdd: () => TaskEditorSheet.show(
              context,
              initialDueAt: DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                period.startMinutes ~/ 60,
                period.startMinutes % 60,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (groups.outsidePeriods.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outside periods',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                for (final task in groups.outsidePeriods)
                  TaskListItem(task: task),
              ],
            ),
          ),
      ],
    );
  }
}

class _RhythmSectionCard extends StatelessWidget {
  const _RhythmSectionCard({
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.onAdd,
  });

  final String title;
  final String subtitle;
  final List<TaskItem> tasks;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primaryText,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(LucideIcons.plus, size: 14),
                label: const Text('Schedule'),
              ),
            ],
          ),
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final task in tasks) TaskListItem(task: task),
          ],
        ],
      ),
    );
  }
}

class _MobileDayView extends StatelessWidget {
  const _MobileDayView({
    required this.selectedDate,
    required this.tasks,
  });

  final DateTime selectedDate;
  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final allDay = tasks
        .where((t) => t.scheduleKind == TaskScheduleKind.allDay)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (allDay.isNotEmpty) ...[
          for (final t in allDay) TaskListItem(task: t),
          const SizedBox(height: 8),
        ],
        for (var hour = 6; hour <= 22; hour++)
          _DayHourSlot(
            selectedDate: selectedDate,
            hour: hour,
            tasks: tasks
                .where(
                  (t) =>
                      t.scheduleKind == TaskScheduleKind.timed &&
                      t.dueAt?.hour == hour,
                )
                .toList(),
            colors: colors,
          ),
      ],
    );
  }
}

class _DayHourSlot extends StatelessWidget {
  const _DayHourSlot({
    required this.selectedDate,
    required this.hour,
    required this.tasks,
    required this.colors,
  });

  final DateTime selectedDate;
  final int hour;
  final List<TaskItem> tasks;
  final AppThemePalette colors;

  @override
  Widget build(BuildContext context) {
    final hourLabel = '${hour.toString().padLeft(2, '0')}:00';
    return InkWell(
      onTap: () => TaskEditorSheet.show(
        context,
        initialDueAt: DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          hour,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                hourLabel,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.merge(AppTheme.monoTextStyle)
                    .copyWith(color: colors.secondaryText),
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Text(
                      'Schedule',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.mutedText.withValues(alpha: 0.45),
                      ),
                    )
                  : Column(
                      children: [
                        for (final task in tasks) TaskListItem(task: task),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileMonthView extends StatelessWidget {
  const _MobileMonthView({
    required this.calendar,
    required this.taskStore,
    required this.dayTasks,
  });

  final CalendarStore calendar;
  final TaskStore taskStore;
  final List<TaskItem> dayTasks;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selected = calendar.selectedDate;
    final firstOfMonth = DateTime(selected.year, selected.month, 1);
    final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var d = 1; d <= daysInMonth; d++)
                Builder(
                  builder: (context) {
                    final date = DateTime(
                      firstOfMonth.year,
                      firstOfMonth.month,
                      d,
                    );
                    final isSelected = isSameCalendarDay(date, selected);
                    final count = taskStore
                        .tasksForDay(date, includeCompleted: false)
                        .length;
                    return GestureDetector(
                      onTap: () => calendar.setSelectedDate(date),
                      child: Container(
                        width: 40,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.accentTint
                              : colors.surfaceTint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? colors.accent : colors.border,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$d',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.merge(AppTheme.monoTextStyle)
                                  .copyWith(
                                    color: isSelected
                                        ? colors.accent
                                        : colors.primaryText,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                            if (count > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: colors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (dayTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No tasks scheduled for ${DateFormat('MMM d').format(selected)}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.secondaryText,
              ),
            ),
          )
        else
          for (final task in dayTasks) TaskListItem(task: task),
      ],
    );
  }
}
