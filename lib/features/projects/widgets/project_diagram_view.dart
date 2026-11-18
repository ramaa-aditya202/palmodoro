import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/features/projects/models/project_models.dart';
import 'package:pomodoro_app/features/projects/store/project_store.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';

class ProjectDiagramView extends StatefulWidget {
  const ProjectDiagramView({
    required this.projectStore,
    required this.taskStore,
    super.key,
  });

  final ProjectStore projectStore;
  final TaskStore taskStore;

  @override
  State<ProjectDiagramView> createState() => _ProjectDiagramViewState();
}

class _ProjectDiagramViewState extends State<ProjectDiagramView> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final roots = widget.projectStore.childrenOf(null);
    final unassigned = widget.taskStore.tasksForProject(
      null,
      includeCompleted: _showCompleted,
    );
    final totalTasks = widget.taskStore.tasks
        .where((t) => t.parentId == null)
        .length;
    final completedTasks = widget.taskStore.completedTasks
        .where((t) => t.parentId == null)
        .length;

    return ListView(
      key: const Key('project-diagram-view'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
      children: [
        // Top diagram controls bar
        Row(
          children: [
            TextButton.icon(
              onPressed: () =>
                  setState(() => _showCompleted = !_showCompleted),
              icon: Icon(
                _showCompleted ? LucideIcons.circleCheck : LucideIcons.circle,
                size: 16,
              ),
              label: const Text('Show completed'),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surfaceTint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                'Workspace $completedTasks/$totalTasks',
                style: textTheme.labelSmall
                    ?.merge(AppTheme.monoTextStyle)
                    .copyWith(color: colors.secondaryText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Workspace root node
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.accentTint,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.accent),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.network, color: colors.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Workspace Map',
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${roots.length} projects',
                style: textTheme.labelSmall
                    ?.merge(AppTheme.monoTextStyle)
                    .copyWith(color: colors.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final root in roots)
          _DiagramProjectBranch(
            project: root,
            subprojects: widget.projectStore.childrenOf(root.id),
            taskStore: widget.taskStore,
            showCompleted: _showCompleted,
            depth: 0,
          ),
        if (unassigned.isNotEmpty)
          _DiagramTaskGroupCard(
            title: 'Unassigned Tasks',
            color: colors.secondaryText,
            tasks: unassigned,
            depth: 0,
          ),
      ],
    );
  }
}

class _DiagramProjectBranch extends StatelessWidget {
  const _DiagramProjectBranch({
    required this.project,
    required this.subprojects,
    required this.taskStore,
    required this.showCompleted,
    required this.depth,
  });

  final ProjectItem project;
  final List<ProjectItem> subprojects;
  final TaskStore taskStore;
  final bool showCompleted;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final allProjectTasks = taskStore.tasksForProject(
      project.id,
      includeCompleted: true,
    );
    final doneCount = allProjectTasks.where((t) => t.isCompleted).length;
    final visibleTasks = taskStore.tasksForProject(
      project.id,
      includeCompleted: showCompleted,
    );

    return Padding(
      padding: EdgeInsets.only(left: depth * 18.0, bottom: 10),
      child: Container(
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
              onTap: () => context.go('/project/${project.id}'),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: project.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(project.icon.iconData, size: 16, color: project.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primaryText,
                      ),
                    ),
                  ),
                  Text(
                    '$doneCount/${allProjectTasks.length}',
                    style: textTheme.labelSmall
                        ?.merge(AppTheme.monoTextStyle)
                        .copyWith(color: colors.secondaryText),
                  ),
                ],
              ),
            ),
            if (visibleTasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final task in visibleTasks)
                _DiagramTaskNode(task: task, accentColor: project.color),
            ],
            if (subprojects.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final sub in subprojects)
                _DiagramProjectBranch(
                  project: sub,
                  subprojects: const [],
                  taskStore: taskStore,
                  showCompleted: showCompleted,
                  depth: 1,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DiagramTaskGroupCard extends StatelessWidget {
  const _DiagramTaskGroupCard({
    required this.title,
    required this.color,
    required this.tasks,
    required this.depth,
  });

  final String title;
  final Color color;
  final List<TaskItem> tasks;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(left: depth * 18.0, bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            for (final task in tasks)
              _DiagramTaskNode(task: task, accentColor: color),
          ],
        ),
      ),
    );
  }
}

class _DiagramTaskNode extends StatelessWidget {
  const _DiagramTaskNode({required this.task, required this.accentColor});

  final TaskItem task;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/task/${task.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surfaceTint,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                task.isCompleted ? LucideIcons.circleCheck : LucideIcons.circle,
                size: 14,
                color: task.isCompleted ? colors.success : accentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: task.isCompleted
                        ? colors.mutedText
                        : colors.primaryText,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
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
