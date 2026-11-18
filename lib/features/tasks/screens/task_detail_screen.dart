import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/features/focus/store/focus_store.dart';
import 'package:pomodoro_app/features/projects/store/project_store.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_editor_sheet.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({required this.taskId, super.key});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  int _selectedTab = 0; // 0: Overview, 1: Subtasks, 2: Dependencies
  final TextEditingController _subtaskController = TextEditingController();

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskStore = context.watch<TaskStore>();
    final projectStore = context.watch<ProjectStore>();
    final focusStore = context.read<FocusStore>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final task = taskStore.byId(widget.taskId);

    if (task == null) {
      return Scaffold(
        backgroundColor: colors.canvas,
        appBar: AppBar(title: const Text('Task')),
        body: const Center(child: Text('Task not found')),
      );
    }

    final project = projectStore.projectById(task.projectId);
    final subtasks = taskStore.subtasksOf(task.id);
    final blockers = taskStore.blockersOf(task.id);
    final isBlocked = taskStore.isTaskBlocked(task.id);

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/today');
            }
          },
        ),
        title: Text(project?.name ?? 'Task Details'),
        actions: [
          IconButton(
            tooltip: 'Edit task',
            onPressed: () => TaskEditorSheet.show(context, existing: task),
            icon: const Icon(LucideIcons.pencil, size: 18),
          ),
          IconButton(
            tooltip: 'Delete task',
            onPressed: () async {
              await taskStore.deleteTask(task.id);
              if (context.mounted) {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/today');
                }
              }
            },
            icon: Icon(LucideIcons.trash2, size: 18, color: colors.error),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Checkbox(
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
                child: Text(
                  task.title,
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.primaryText,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.timer, color: colors.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Focus: ${task.completedPomodoros} / ${task.estimatedPomodoros} intervals',
                    style: textTheme.bodyMedium
                        ?.merge(AppTheme.monoTextStyle)
                        .copyWith(color: colors.primaryText),
                  ),
                ),
                FilledButton.icon(
                  onPressed: isBlocked
                      ? null
                      : () async {
                          await focusStore.startSession(taskId: task.id);
                          if (context.mounted) context.go('/focus');
                        },
                  icon: Icon(
                    isBlocked ? LucideIcons.lock : LucideIcons.play,
                    size: 16,
                  ),
                  label: Text(isBlocked ? 'Blocked' : 'Start Focus'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Internal tabs: Overview | Subtasks | Dependencies
          Row(
            children: [
              _DetailTab(
                label: 'Overview',
                selected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              const SizedBox(width: 16),
              _DetailTab(
                label: 'Subtasks (${subtasks.length})',
                selected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
              const SizedBox(width: 16),
              _DetailTab(
                label: 'Blockers (${blockers.length})',
                selected: _selectedTab == 2,
                onTap: () => setState(() => _selectedTab = 2),
              ),
            ],
          ),
          const Divider(height: 20),
          if (_selectedTab == 0)
            _OverviewSection(task: task, taskStore: taskStore)
          else if (_selectedTab == 1)
            _SubtasksSection(
              parent: task,
              subtasks: subtasks,
              taskStore: taskStore,
              controller: _subtaskController,
            )
          else
            _DependenciesSection(
              task: task,
              blockers: blockers,
              taskStore: taskStore,
            ),
        ],
      ),
    );
  }
}

class _DetailTab extends StatelessWidget {
  const _DetailTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? colors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? colors.primaryText : colors.secondaryText,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.task, required this.taskStore});

  final TaskItem task;
  final TaskStore taskStore;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PropertyRow(label: 'Priority', value: 'P${task.priority}'),
          const Divider(height: 16),
          _PropertyRow(
            label: 'Due date',
            value: task.dueAt == null
                ? 'Unscheduled'
                : task.scheduleKind == TaskScheduleKind.timed
                    ? '${DateFormat('EEE, MMM d, yyyy · HH:mm').format(task.dueAt!)}${task.durationMinutes != null ? ' (${task.durationMinutes}m)' : ''}'
                    : DateFormat('EEE, MMM d, yyyy').format(task.dueAt!),
          ),
          const Divider(height: 16),
          _PropertyRow(
            label: 'Kanban status',
            value: task.kanbanStatus,
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reminder',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.secondaryText,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: task.reminderAt ?? task.dueAt ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2035),
                      );
                      if (date == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          task.reminderAt ?? DateTime.now(),
                        ),
                      );
                      if (time == null) return;
                      await taskStore.setTaskReminder(
                        task.id,
                        DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.bell, size: 14),
                    label: Text(
                      task.reminderAt == null
                          ? 'Set reminder'
                          : DateFormat('MMM d, HH:mm').format(task.reminderAt!),
                    ),
                  ),
                  if (task.reminderAt != null)
                    IconButton(
                      tooltip: 'Clear reminder',
                      onPressed: () => taskStore.setTaskReminder(task.id, null),
                      icon: const Icon(LucideIcons.x, size: 14),
                    ),
                ],
              ),
            ],
          ),
          if (task.recurrence != null) ...[
            const Divider(height: 16),
            _PropertyRow(label: 'Recurrence', value: task.recurrence!.summary),
          ],
          if (task.description.isNotEmpty) ...[
            const Divider(height: 20),
            Text(
              'Description',
              style: textTheme.labelMedium?.copyWith(
                color: colors.secondaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(task.description, style: textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _SubtasksSection extends StatelessWidget {
  const _SubtasksSection({
    required this.parent,
    required this.subtasks,
    required this.taskStore,
    required this.controller,
  });

  final TaskItem parent;
  final List<TaskItem> subtasks;
  final TaskStore taskStore;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('subtask-title-input'),
                controller: controller,
                decoration: const InputDecoration(hintText: 'Add a subtask...'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('subtask-add-button'),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                controller.clear();
                await taskStore.createTask(
                  title: text,
                  parentId: parent.id,
                  projectId: parent.projectId,
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final sub in subtasks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.border),
              ),
              child: ListTile(
                dense: true,
                leading: Checkbox(
                  value: sub.isCompleted,
                  onChanged: (_) => taskStore.toggleComplete(sub.id),
                ),
                title: Text(
                  sub.title,
                  style: TextStyle(
                    decoration: sub.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  onPressed: () => taskStore.deleteTask(sub.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DependenciesSection extends StatelessWidget {
  const _DependenciesSection({
    required this.task,
    required this.blockers,
    required this.taskStore,
  });

  final TaskItem task;
  final List<TaskItem> blockers;
  final TaskStore taskStore;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final candidates = taskStore.activeTasks
        .where(
          (candidate) =>
              candidate.id != task.id &&
              !blockers.any((b) => b.id == candidate.id),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (candidates.isNotEmpty)
          DropdownButtonFormField<String>(
            key: ValueKey('blocker-picker-${blockers.length}'),
            decoration: const InputDecoration(
              labelText: 'Add blocking task (must finish before this task)',
            ),
            items: [
              for (final c in candidates)
                DropdownMenuItem(value: c.id, child: Text(c.title)),
            ],
            onChanged: (blockerId) async {
              if (blockerId == null) return;
              try {
                await taskStore.addDependency(
                  blockerTaskId: blockerId,
                  blockedTaskId: task.id,
                );
              } on TaskDependencyCycleException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
        const SizedBox(height: 12),
        if (blockers.isEmpty)
          Text(
            'No blocking tasks.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.secondaryText,
            ),
          )
        else
          for (final blocker in blockers)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colors.border),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    blocker.isCompleted
                        ? LucideIcons.circleCheck
                        : LucideIcons.lock,
                    color:
                        blocker.isCompleted ? colors.success : colors.warning,
                    size: 18,
                  ),
                  title: Text(blocker.title),
                  trailing: IconButton(
                    tooltip: 'Remove dependency',
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () => taskStore.removeDependency(
                      blockerTaskId: blocker.id,
                      blockedTaskId: task.id,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.secondaryText,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
