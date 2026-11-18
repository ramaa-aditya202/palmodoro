import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/focus/store/focus_store.dart';
import 'package:pomodoro_app/features/projects/store/project_store.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_editor_sheet.dart';

enum KanbanColumn {
  backlog('backlog', 'Backlog', LucideIcons.circleDashed),
  todo('todo', 'To do', LucideIcons.circle),
  inProgress('inProgress', 'In progress', LucideIcons.loader),
  done('done', 'Done', LucideIcons.circleCheck);

  const KanbanColumn(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  KanbanColumn _selectedColumn = KanbanColumn.todo;
  String? _projectFilterId;

  @override
  Widget build(BuildContext context) {
    final taskStore = context.watch<TaskStore>();
    final projectStore = context.watch<ProjectStore>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final allRootTasks = taskStore.tasks
        .where(
          (t) =>
              t.parentId == null &&
              (_projectFilterId == null || t.projectId == _projectFilterId),
        )
        .toList(growable: false);

    Map<KanbanColumn, List<TaskItem>> byColumn = {
      for (final col in KanbanColumn.values) col: <TaskItem>[],
    };
    for (final task in allRootTasks) {
      if (task.isCompleted || task.kanbanStatus == 'done') {
        byColumn[KanbanColumn.done]!.add(task);
      } else if (task.kanbanStatus == 'backlog') {
        byColumn[KanbanColumn.backlog]!.add(task);
      } else if (task.kanbanStatus == 'inProgress') {
        byColumn[KanbanColumn.inProgress]!.add(task);
      } else {
        byColumn[KanbanColumn.todo]!.add(task);
      }
    }

    final currentCards = byColumn[_selectedColumn] ?? const [];

    return Column(
      children: [
        CompactShellHeader(
          title: 'Kanban',
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
          trailing: [
            IconButton(
              tooltip: 'Add task',
              onPressed: () => TaskEditorSheet.show(
                context,
                initialProjectId: _projectFilterId,
              ),
              icon: Icon(LucideIcons.circlePlus, size: 20, color: colors.accent),
            ),
          ],
        ),
        // Column selector tabs + optional project filter
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final col in KanbanColumn.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(col.icon, size: 14),
                          label: Text(
                            '${col.label} (${byColumn[col]!.length})',
                          ),
                          selected: _selectedColumn == col,
                          onSelected: (_) =>
                              setState(() => _selectedColumn = col),
                        ),
                      ),
                  ],
                ),
              ),
              if (projectStore.activeProjects.isNotEmpty) ...[
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All projects'),
                        selected: _projectFilterId == null,
                        onSelected: (_) =>
                            setState(() => _projectFilterId = null),
                      ),
                      const SizedBox(width: 6),
                      for (final project in projectStore.activeProjects)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(project.name),
                            selected: _projectFilterId == project.id,
                            onSelected: (_) => setState(
                              () => _projectFilterId = project.id,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: currentCards.isEmpty
              ? Center(
                  child: Text(
                    'No tasks in ${_selectedColumn.label}.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.secondaryText,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                  children: [
                    for (final task in currentCards)
                      _KanbanCard(
                        task: task,
                        currentColumn: _selectedColumn,
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

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({
    required this.task,
    required this.currentColumn,
    required this.projectStore,
    required this.taskStore,
  });

  final TaskItem task;
  final KanbanColumn currentColumn;
  final ProjectStore projectStore;
  final TaskStore taskStore;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final focusStore = context.read<FocusStore>();
    final project = projectStore.projectById(task.projectId);
    final blocked = taskStore.isTaskBlocked(task.id);

    Future<void> moveTo(KanbanColumn target) async {
      try {
        await taskStore.moveKanbanStatus(task.id, target.key);
      } on TaskBlockedException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/task/${task.id}'),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.priorityColor(task.priority),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.primaryText,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                if (!task.isCompleted && !blocked)
                  IconButton(
                    tooltip: 'Start Focus',
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => focusStore.startSession(taskId: task.id),
                    icon: Icon(
                      LucideIcons.play,
                      size: 16,
                      color: colors.accent,
                    ),
                  ),
              ],
            ),
          ),
          if (project != null || task.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              project != null
                  ? '${project.name}${task.description.isNotEmpty ? " · ${task.description}" : ""}'
                  : task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: colors.secondaryText),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final col in KanbanColumn.values)
                if (col != currentColumn)
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(col.icon, size: 12),
                    label: Text(col.label),
                    onPressed: () => moveTo(col),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
