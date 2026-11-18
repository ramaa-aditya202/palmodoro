import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_editor_sheet.dart';

class PriorityMatrixScreen extends StatelessWidget {
  const PriorityMatrixScreen({super.key});

  static const List<(int, String, String)> _quadrants = [
    (1, 'P1 · Urgent & Important', 'Do first'),
    (2, 'P2 · Important, Not Urgent', 'Schedule'),
    (3, 'P3 · Urgent, Not Important', 'Delegate / quick'),
    (4, 'P4 · Neither', 'Backlog / later'),
  ];

  @override
  Widget build(BuildContext context) {
    final taskStore = context.watch<TaskStore>();
    final active = taskStore.activeTasks
        .where((t) => t.parentId == null)
        .toList(growable: false);

    return Column(
      children: [
        CompactShellHeader(
          title: 'Priority Matrix',
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
          trailing: [
            IconButton(
              tooltip: 'Add task',
              onPressed: () => TaskEditorSheet.show(context),
              icon: const Icon(LucideIcons.plus, size: 20),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
            children: [
              for (final q in _quadrants) ...[
                _MatrixQuadrantCard(
                  priority: q.$1,
                  title: q.$2,
                  subtitle: q.$3,
                  tasks: active
                      .where((t) => t.priority == q.$1)
                      .toList(growable: false),
                  taskStore: taskStore,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MatrixQuadrantCard extends StatelessWidget {
  const _MatrixQuadrantCard({
    required this.priority,
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.taskStore,
  });

  final int priority;
  final String title;
  final String subtitle;
  final List<TaskItem> tasks;
  final TaskStore taskStore;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final pColor = colors.priorityColor(priority);

    return Container(
      padding: const EdgeInsets.all(14),
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
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: pColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
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
                      '$subtitle · ${tasks.length} tasks',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tasks.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'No P$priority tasks.',
              style: textTheme.bodySmall?.copyWith(color: colors.mutedText),
            ),
          ] else ...[
            const SizedBox(height: 8),
            for (final task in tasks)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceTint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
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
                      child: InkWell(
                        onTap: () => context.push('/task/${task.id}'),
                        child: Text(
                          task.title,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    PopupMenuButton<int>(
                      tooltip: 'Move priority',
                      icon: Icon(
                        LucideIcons.arrowUpDown,
                        size: 16,
                        color: colors.secondaryText,
                      ),
                      onSelected: (nextP) =>
                          taskStore.setTaskPriority(task.id, nextP),
                      itemBuilder: (_) => [
                        for (final p in [1, 2, 3, 4])
                          if (p != priority)
                            PopupMenuItem(
                              value: p,
                              child: Text('Move to P$p'),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
