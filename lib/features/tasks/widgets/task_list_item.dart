import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_date_format.dart';
import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/theme/theme_controller.dart';
import 'package:pomodoro_app/features/focus/store/focus_store.dart';
import 'package:pomodoro_app/features/projects/store/project_store.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';

class TaskListItem extends StatelessWidget {
  const TaskListItem({
    required this.task,
    this.showProject = true,
    super.key,
  });

  final TaskItem task;
  final bool showProject;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final taskStore = context.watch<TaskStore>();
    final projectStore = context.watch<ProjectStore>();
    final focusStore = context.read<FocusStore>();
    final dateFormat =
        context.watch<ThemeController?>()?.dateFormat ??
        AppDateFormat.automatic;
    final project = projectStore.projectById(task.projectId);
    final priorityColor = colors.priorityColor(task.priority);
    final now = DateTime.now();
    final timeState = task.timeState(now);
    final dueColor = colors.taskTimeColor(timeState);
    final subProgress = taskStore.subtaskProgress(task.id);
    final blocked = taskStore.isTaskBlocked(task.id);

    Future<void> handleComplete() async {
      try {
        await taskStore.toggleComplete(task.id);
      } on TaskBlockedException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    return Dismissible(
      key: ValueKey('task-row-${task.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colors.success,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(LucideIcons.check, color: Colors.white, size: 20),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await handleComplete();
          return false;
        }
        final messenger = ScaffoldMessenger.maybeOf(context);
        final snapshot = await taskStore.deleteTask(task.id);
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Deleted "${task.title}"'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => taskStore.restoreDeleted(snapshot),
              ),
            ),
          );
        return true;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.push('/task/${task.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: handleComplete,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, right: 12),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.isCompleted
                            ? priorityColor
                            : priorityColor.withValues(alpha: 0.12),
                        border: Border.all(color: priorityColor, width: 1.6),
                      ),
                      child: task.isCompleted
                          ? const Icon(
                              LucideIcons.check,
                              size: 13,
                              color: Colors.white,
                            )
                          : blocked
                              ? Icon(
                                  LucideIcons.lock,
                                  size: 11,
                                  color: priorityColor,
                                )
                              : null,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: textTheme.bodyMedium?.copyWith(
                          color: task.isCompleted
                              ? colors.mutedText
                              : colors.primaryText,
                          fontWeight: FontWeight.w500,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.secondaryText,
                          ),
                        ),
                      ],
                      if (task.dueAt != null ||
                          task.estimatedPomodoros > 0 ||
                          task.completedPomodoros > 0 ||
                          subProgress.total > 0 ||
                          blocked ||
                          task.reminderAt != null ||
                          (showProject && project != null) ||
                          task.labelIds.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (blocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.lock,
                                      size: 11,
                                      color: colors.warning,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Blocked',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colors.warning,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (task.dueAt != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.calendar,
                                    size: 12,
                                    color: dueColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDue(task, now, dateFormat),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: dueColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (task.recurrence != null) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      LucideIcons.repeat,
                                      size: 11,
                                      color: dueColor,
                                    ),
                                  ],
                                ],
                              ),
                            if (subProgress.total > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.gitBranch,
                                    size: 12,
                                    color: colors.secondaryText,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${subProgress.completed}/${subProgress.total}',
                                    style: textTheme.labelSmall
                                        ?.merge(AppTheme.monoTextStyle)
                                        .copyWith(color: colors.secondaryText),
                                  ),
                                ],
                              ),
                            if (task.estimatedPomodoros > 0 ||
                                task.completedPomodoros > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.timer,
                                    size: 12,
                                    color: colors.accent,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${task.completedPomodoros}/${task.estimatedPomodoros}',
                                    style: textTheme.labelSmall
                                        ?.merge(AppTheme.monoTextStyle)
                                        .copyWith(
                                          color: colors.secondaryText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            if (task.reminderAt != null)
                              Icon(
                                LucideIcons.bell,
                                size: 12,
                                color: colors.info,
                              ),
                            if (showProject && project != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: project.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    project.name,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            for (final labelId in task.labelIds)
                              if (projectStore.labelById(labelId)
                                  case final label?)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: label.color.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '@${label.name}',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: label.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!task.isCompleted)
                  IconButton(
                    key: const Key('task-start-focus-button'),
                    tooltip: blocked ? 'Task is blocked' : 'Start Focus',
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      try {
                        await focusStore.startSession(taskId: task.id);
                      } on TaskBlockedException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                    icon: Icon(
                      blocked ? LucideIcons.lock : LucideIcons.play,
                      size: 16,
                      color: blocked ? colors.mutedText : colors.accent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDue(TaskItem task, DateTime now, AppDateFormat dateFormat) {
    final due = task.dueAt!;
    final dayLabel = isSameCalendarDay(due, now)
        ? 'Today'
        : isSameCalendarDay(due, now.add(const Duration(days: 1)))
            ? 'Tomorrow'
            : dateFormat.formatShort(due);
    if (task.scheduleKind == TaskScheduleKind.timed) {
      final timePart = DateFormat('HH:mm').format(due);
      final durationPart = task.durationMinutes != null
          ? ' (${task.durationMinutes}m)'
          : '';
      return '$dayLabel $timePart$durationPart';
    }
    return dayLabel;
  }
}
