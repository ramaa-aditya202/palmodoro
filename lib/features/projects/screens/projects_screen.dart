import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/projects/models/project_models.dart';
import 'package:pomodoro_app/features/projects/store/project_store.dart';
import 'package:pomodoro_app/features/projects/widgets/project_diagram_view.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_editor_sheet.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_list_item.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  bool _showLabelsTab = false;
  bool _showMapView = false;

  Future<void> _showCreateProjectDialog({String? parentId}) async {
    final nameController = TextEditingController();
    var selectedColor = ProjectColors.palette.first;
    var selectedIcon = ProjectIcon.folder;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(parentId == null ? 'New project' : 'New sub-project'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Project name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final hex in ProjectColors.palette)
                          GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedColor = hex),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: ProjectColors.parse(hex),
                                shape: BoxShape.circle,
                                border: selectedColor == hex
                                    ? Border.all(
                                        color: context.appColors.primaryText,
                                        width: 2.2,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final icon in ProjectIcon.values)
                          ChoiceChip(
                            label: Icon(icon.iconData, size: 16),
                            selected: selectedIcon == icon,
                            onSelected: (_) =>
                                setDialogState(() => selectedIcon = icon),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    final text = nameController.text.trim();
    nameController.dispose();
    if (created == true && text.isNotEmpty && mounted) {
      await context.read<ProjectStore>().createProject(
        name: text,
        colorHex: selectedColor,
        icon: selectedIcon,
        parentId: parentId,
      );
    }
  }

  Future<void> _showCreateLabelDialog() async {
    final nameController = TextEditingController();
    var selectedColor = ProjectColors.palette.first;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New label'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Label name'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final hex in ProjectColors.palette)
                        GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedColor = hex),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: ProjectColors.parse(hex),
                              shape: BoxShape.circle,
                              border: selectedColor == hex
                                  ? Border.all(
                                      color: context.appColors.primaryText,
                                      width: 2.2,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    final text = nameController.text.trim();
    nameController.dispose();
    if (created == true && text.isNotEmpty && mounted) {
      try {
        await context.read<ProjectStore>().createLabel(
          name: text,
          colorHex: selectedColor,
        );
      } on LabelNameTakenException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectStore = context.watch<ProjectStore>();
    final taskStore = context.watch<TaskStore>();
    final colors = context.appColors;

    return Column(
      children: [
        CompactShellHeader(
          title: 'Projects',
          subtitle: _showLabelsTab
              ? 'Labels'
              : (_showMapView ? 'Projects · Map' : 'Projects · List'),
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
          leadingWing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Projects',
                  onPressed: () => setState(() => _showLabelsTab = false),
                  icon: Icon(
                    LucideIcons.folder,
                    size: 18,
                    color:
                        !_showLabelsTab ? colors.accent : colors.secondaryText,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Labels',
                  onPressed: () => setState(() => _showLabelsTab = true),
                  icon: Icon(
                    LucideIcons.tag,
                    size: 18,
                    color:
                        _showLabelsTab ? colors.accent : colors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          trailingWing: _showLabelsTab
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'List view',
                        onPressed: () => setState(() => _showMapView = false),
                        icon: Icon(
                          LucideIcons.list,
                          size: 18,
                          color: !_showMapView
                              ? colors.accent
                              : colors.secondaryText,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Map view',
                        onPressed: () => setState(() => _showMapView = true),
                        icon: Icon(
                          LucideIcons.map,
                          size: 18,
                          color: _showMapView
                              ? colors.accent
                              : colors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
          trailing: [
            IconButton(
              padding: EdgeInsets.zero,
              tooltip: _showLabelsTab ? 'Add label' : 'Add project',
              onPressed: _showLabelsTab
                  ? _showCreateLabelDialog
                  : () => _showCreateProjectDialog(),
              icon: Icon(LucideIcons.plus, size: 20, color: colors.accent),
            ),
          ],
        ),
        Expanded(
          child: _showLabelsTab
              ? _LabelsList(
                  projectStore: projectStore,
                  taskStore: taskStore,
                )
              : _showMapView
                  ? ProjectDiagramView(
                      projectStore: projectStore,
                      taskStore: taskStore,
                    )
                  : _ProjectsList(
                      projectStore: projectStore,
                      taskStore: taskStore,
                      onAddSubproject: (parentId) =>
                          _showCreateProjectDialog(parentId: parentId),
                    ),
        ),
      ],
    );
  }
}

class _ProjectsList extends StatelessWidget {
  const _ProjectsList({
    required this.projectStore,
    required this.taskStore,
    required this.onAddSubproject,
  });

  final ProjectStore projectStore;
  final TaskStore taskStore;
  final ValueChanged<String> onAddSubproject;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final roots = projectStore.childrenOf(null);

    if (roots.isEmpty) {
      return Center(
        child: Text(
          'No projects yet. Tap + to create one.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.secondaryText,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
      children: [
        for (final root in roots) ...[
          _ProjectTile(
            project: root,
            depth: 0,
            taskCount: taskStore.tasksForProject(root.id).length,
            onAddSubproject: () => onAddSubproject(root.id),
            onDelete: () => projectStore.deleteProject(root.id),
          ),
          for (final child in projectStore.childrenOf(root.id))
            _ProjectTile(
              project: child,
              depth: 1,
              taskCount: taskStore.tasksForProject(child.id).length,
              onAddSubproject: null,
              onDelete: () => projectStore.deleteProject(child.id),
            ),
        ],
      ],
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.depth,
    required this.taskCount,
    required this.onAddSubproject,
    required this.onDelete,
  });

  final ProjectItem project;
  final int depth;
  final int taskCount;
  final VoidCallback? onAddSubproject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0, top: 4, bottom: 4),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.border),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onTap: () => context.go('/project/${project.id}'),
          leading: Icon(project.icon.iconData, color: project.color, size: 20),
          title: Text(project.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$taskCount',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.merge(AppTheme.monoTextStyle),
              ),
              if (onAddSubproject != null)
                IconButton(
                  tooltip: 'Add sub-project',
                  onPressed: onAddSubproject,
                  icon: const Icon(LucideIcons.folderPlus, size: 16),
                ),
              IconButton(
                tooltip: 'Delete project',
                onPressed: onDelete,
                icon: Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: colors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelsList extends StatelessWidget {
  const _LabelsList({required this.projectStore, required this.taskStore});

  final ProjectStore projectStore;
  final TaskStore taskStore;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final labels = projectStore.labels;
    if (labels.isEmpty) {
      return Center(
        child: Text(
          'No labels yet. Tap + to create one.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.secondaryText,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
      children: [
        for (final label in labels)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: colors.border),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () => context.go('/label/${label.id}'),
                leading: Icon(
                  label.icon.iconData,
                  color: label.color,
                  size: 18,
                ),
                title: Text(label.name),
                trailing: IconButton(
                  tooltip: 'Delete label',
                  onPressed: () => projectStore.deleteLabel(label.id),
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: colors.secondaryText,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final projectStore = context.watch<ProjectStore>();
    final taskStore = context.watch<TaskStore>();
    final project = projectStore.projectById(projectId);
    final tasks = taskStore.tasksForProject(projectId, includeCompleted: true);

    return Column(
      children: [
        CompactShellHeader(
          title: project?.name ?? 'Project',
          leadingIcon: LucideIcons.arrowLeft,
          leadingTooltip: 'Back to Projects',
          onOpenDrawer: () => context.go('/projects'),
          trailing: [
            IconButton(
              tooltip: 'Add task to project',
              onPressed: () => TaskEditorSheet.show(
                context,
                initialProjectId: projectId,
              ),
              icon: const Icon(LucideIcons.plus, size: 20),
            ),
          ],
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(child: Text('No tasks in this project'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                  children: [
                    for (final task in tasks)
                      TaskListItem(task: task, showProject: false),
                  ],
                ),
        ),
      ],
    );
  }
}

class LabelDetailScreen extends StatelessWidget {
  const LabelDetailScreen({required this.labelId, super.key});

  final String labelId;

  @override
  Widget build(BuildContext context) {
    final projectStore = context.watch<ProjectStore>();
    final taskStore = context.watch<TaskStore>();
    final label = projectStore.labelById(labelId);
    final tasks = taskStore.tasksForLabel(labelId, includeCompleted: true);

    return Column(
      children: [
        CompactShellHeader(
          title: label != null ? '@${label.name}' : 'Label',
          leadingIcon: LucideIcons.arrowLeft,
          leadingTooltip: 'Back to Projects',
          onOpenDrawer: () => context.go('/projects'),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(child: Text('No tasks with this label'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                  children: [
                    for (final task in tasks) TaskListItem(task: task),
                  ],
                ),
        ),
      ],
    );
  }
}
