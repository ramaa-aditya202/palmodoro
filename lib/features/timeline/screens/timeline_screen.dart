import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/projects/store/project_store.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_editor_sheet.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_list_item.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  DateTime _selectedDate = dateOnly(DateTime.now());
  bool _allDayExpanded = true;
  bool _workHoursOnly = true; // true: 08-20 (auto-expanded to fit tasks), false: 00-23

  @override
  Widget build(BuildContext context) {
    final taskStore = context.watch<TaskStore>();
    final projectStore = context.watch<ProjectStore>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final dayTasks = taskStore.tasksForDay(_selectedDate, includeCompleted: true);
    final allDayTasks = dayTasks
        .where((t) => t.scheduleKind == TaskScheduleKind.allDay)
        .toList(growable: false);
    final timedTasks = dayTasks
        .where((t) => t.scheduleKind == TaskScheduleKind.timed)
        .toList(growable: false);

    var startHour = _workHoursOnly ? 8 : 0;
    var endHour = _workHoursOnly ? 20 : 23;
    for (final t in timedTasks) {
      final h = t.dueAt?.hour;
      if (h != null) {
        if (h < startHour) startHour = h;
        if (h > endHour) endHour = h;
      }
    }

    return Column(
      children: [
        CompactShellHeader(
          title: 'Timeline',
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
          trailing: [
            IconButton(
              tooltip: _workHoursOnly ? 'Show 24 hours' : 'Work hours (08–20)',
              onPressed: () =>
                  setState(() => _workHoursOnly = !_workHoursOnly),
              icon: Icon(
                _workHoursOnly ? LucideIcons.clock : LucideIcons.sun,
                size: 18,
              ),
            ),
          ],
        ),
        // Date toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous day',
                onPressed: () => setState(() {
                  _selectedDate = _selectedDate.subtract(
                    const Duration(days: 1),
                  );
                }),
                icon: const Icon(LucideIcons.chevronLeft, size: 18),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      setState(() => _selectedDate = dateOnly(DateTime.now())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                      textAlign: TextAlign.center,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primaryText,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next day',
                onPressed: () => setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                }),
                icon: const Icon(LucideIcons.chevronRight, size: 18),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
            children: [
              // Expandable All-day card
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () =>
                          setState(() => _allDayExpanded = !_allDayExpanded),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'All-day (${allDayTasks.length})',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            _allDayExpanded
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 16,
                            color: colors.secondaryText,
                          ),
                        ],
                      ),
                    ),
                    if (_allDayExpanded && allDayTasks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final task in allDayTasks) TaskListItem(task: task),
                    ],
                  ],
                ),
              ),
              // Vertical time grid with fixed hour gutter
              for (var hour = startHour; hour <= endHour; hour++)
                _TimelineHourRow(
                  selectedDate: _selectedDate,
                  hour: hour,
                  tasks: timedTasks
                      .where((t) => t.dueAt?.hour == hour)
                      .toList(growable: false),
                  projectStore: projectStore,
                  taskStore: taskStore,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineHourRow extends StatelessWidget {
  const _TimelineHourRow({
    required this.selectedDate,
    required this.hour,
    required this.tasks,
    required this.projectStore,
    required this.taskStore,
  });

  final DateTime selectedDate;
  final int hour;
  final List<TaskItem> tasks;
  final ProjectStore projectStore;
  final TaskStore taskStore;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
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
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              child: Text(
                hourLabel,
                style: textTheme.labelSmall
                    ?.merge(AppTheme.monoTextStyle)
                    .copyWith(color: colors.secondaryText),
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? const SizedBox(height: 24)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final task in tasks)
                          _TimelineTimedCard(
                            task: task,
                            projectStore: projectStore,
                            taskStore: taskStore,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTimedCard extends StatelessWidget {
  const _TimelineTimedCard({
    required this.task,
    required this.projectStore,
    required this.taskStore,
  });

  final TaskItem task;
  final ProjectStore projectStore;
  final TaskStore taskStore;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final project = projectStore.projectById(task.projectId);
    final edgeColor = project?.color ?? colors.accent;
    final timeStr = task.dueAt != null
        ? DateFormat('HH:mm').format(task.dueAt!)
        : '';
    final durationStr = task.durationMinutes != null
        ? ' · ${task.durationMinutes}m'
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.accentTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/task/${task.id}'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: edgeColor),
              const SizedBox(width: 6),
              Checkbox(
                visualDensity: VisualDensity.compact,
                value: task.isCompleted,
                onChanged: (_) async {
                  try {
                    await taskStore.toggleComplete(task.id);
                  } on TaskBlockedException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.primaryText,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(
                        '$timeStr$durationStr${project != null ? ' · ${project.name}' : ''}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
