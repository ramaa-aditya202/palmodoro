import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/features/projects/store/project_store.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({
    this.existing,
    this.initialDueAt,
    this.initialProjectId,
    super.key,
  });

  final TaskItem? existing;
  final DateTime? initialDueAt;
  final String? initialProjectId;

  static Future<TaskItem?> show(
    BuildContext context, {
    TaskItem? existing,
    DateTime? initialDueAt,
    String? initialProjectId,
  }) {
    return showModalBottomSheet<TaskItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskEditorSheet(
        existing: existing,
        initialDueAt: initialDueAt,
        initialProjectId: initialProjectId,
      ),
    );
  }

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _projectId;
  int _priority = 4;
  DateTime? _dueAt;
  TaskScheduleKind _scheduleKind = TaskScheduleKind.allDay;
  int? _durationMinutes;
  TaskRecurrence? _recurrence;
  int _estimatedPomodoros = 0;
  late Set<String> _labelIds;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _projectId = e?.projectId ?? widget.initialProjectId;
    _priority = e?.priority ?? 4;
    _dueAt = e != null
        ? e.dueAt
        : (widget.initialDueAt ?? dateOnly(DateTime.now()));
    _scheduleKind = e?.scheduleKind ?? TaskScheduleKind.allDay;
    _durationMinutes = e?.durationMinutes;
    _recurrence = e?.recurrence;
    _estimatedPomodoros = e?.estimatedPomodoros ?? 0;
    _labelIds = {...(e?.labelIds ?? const <String>[])};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final store = context.read<TaskStore>();
    final validLabelIds = context
        .read<ProjectStore>()
        .labels
        .map((l) => l.id)
        .toSet();
    final filteredLabels = _labelIds
        .where(validLabelIds.contains)
        .toList(growable: false);
    TaskItem saved;
    if (widget.existing == null) {
      saved = await store.createTask(
        title: title,
        description: _descriptionController.text.trim(),
        projectId: _projectId,
        priority: _priority,
        dueAt: _dueAt,
        scheduleKind: _scheduleKind,
        durationMinutes: _durationMinutes,
        recurrence: _recurrence,
        estimatedPomodoros: _estimatedPomodoros,
        labelIds: filteredLabels,
      );
    } else {
      saved = await store.updateTask(
        widget.existing!.copyWith(
          title: title,
          description: _descriptionController.text.trim(),
          projectId: _projectId,
          clearProject: _projectId == null,
          priority: _priority,
          dueAt: _dueAt,
          clearDueAt: _dueAt == null,
          scheduleKind: _scheduleKind,
          durationMinutes: _durationMinutes,
          clearDuration: _durationMinutes == null,
          recurrence: _recurrence,
          clearRecurrence: _recurrence == null,
          estimatedPomodoros: _estimatedPomodoros,
          labelIds: filteredLabels,
        ),
      );
    }
    if (mounted) {
      Navigator.of(context).pop(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final projectStore = context.watch<ProjectStore>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('task-title-input'),
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Task name',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('task-description-input'),
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Description',
              ),
            ),
            const SizedBox(height: 12),
            // Quick date chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(LucideIcons.calendarCheck, size: 14),
                  label: const Text('Today'),
                  onPressed: () =>
                      setState(() => _dueAt = dateOnly(DateTime.now())),
                ),
                ActionChip(
                  avatar: const Icon(LucideIcons.sunrise, size: 14),
                  label: const Text('Tomorrow'),
                  onPressed: () => setState(
                    () => _dueAt = dateOnly(
                      DateTime.now().add(const Duration(days: 1)),
                    ),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(LucideIcons.calendar, size: 14),
                  label: Text(
                    _dueAt == null
                        ? 'No date'
                        : DateFormat('MMM d').format(_dueAt!),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueAt ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() {
                        if (_scheduleKind == TaskScheduleKind.timed &&
                            _dueAt != null) {
                          _dueAt = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            _dueAt!.hour,
                            _dueAt!.minute,
                          );
                        } else {
                          _dueAt = picked;
                        }
                      });
                    }
                  },
                ),
                if (_dueAt != null)
                  ActionChip(
                    avatar: const Icon(LucideIcons.clock, size: 14),
                    label: Text(
                      _scheduleKind == TaskScheduleKind.timed
                          ? DateFormat('HH:mm').format(_dueAt!)
                          : 'Add time',
                    ),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          _dueAt ?? DateTime.now(),
                        ),
                      );
                      if (picked != null && _dueAt != null) {
                        setState(() {
                          _dueAt = DateTime(
                            _dueAt!.year,
                            _dueAt!.month,
                            _dueAt!.day,
                            picked.hour,
                            picked.minute,
                          );
                          _scheduleKind = TaskScheduleKind.timed;
                          _durationMinutes ??= 30;
                        });
                      }
                    },
                  ),
                if (_dueAt != null && _scheduleKind == TaskScheduleKind.timed) ...[
                  ActionChip(
                    label: Text('${_durationMinutes ?? 30}m'),
                    onPressed: () {
                      const steps = [15, 30, 45, 60, 90, 120];
                      final idx = steps.indexOf(_durationMinutes ?? 30);
                      setState(() {
                        _durationMinutes = steps[(idx + 1) % steps.length];
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('All-day'),
                    onPressed: () => setState(() {
                      _dueAt = dateOnly(_dueAt!);
                      _scheduleKind = TaskScheduleKind.allDay;
                      _durationMinutes = null;
                    }),
                  ),
                ],
                if (_dueAt != null)
                  ActionChip(
                    label: const Text('Clear date'),
                    onPressed: () => setState(() {
                      _dueAt = null;
                      _scheduleKind = TaskScheduleKind.allDay;
                      _durationMinutes = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Priority selector P1-P4
            Row(
              children: [
                Text(
                  'Priority:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                for (final p in [1, 2, 3, 4])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('P$p'),
                      selected: _priority == p,
                      selectedColor: colors.priorityColor(p).withValues(
                        alpha: 0.2,
                      ),
                      onSelected: (_) => setState(() => _priority = p),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Recurrence & Pomodoro estimate
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TaskRecurrenceUnit?>(
                    initialValue: _recurrence?.unit,
                    decoration: const InputDecoration(labelText: 'Repeat'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No repeat'),
                      ),
                      for (final unit in TaskRecurrenceUnit.values)
                        DropdownMenuItem(value: unit, child: Text(unit.label)),
                    ],
                    onChanged: (unit) {
                      setState(() {
                        _recurrence = unit == null
                            ? null
                            : TaskRecurrence(interval: 1, unit: unit);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Icon(LucideIcons.timer, size: 16, color: colors.accent),
                    IconButton(
                      onPressed: _estimatedPomodoros > 0
                          ? () => setState(() => _estimatedPomodoros--)
                          : null,
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    Text(
                      '$_estimatedPomodoros',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.merge(AppTheme.monoTextStyle),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _estimatedPomodoros++),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Project selector
            DropdownButtonFormField<String?>(
              initialValue: projectStore.activeProjects.any((p) => p.id == _projectId)
                  ? _projectId
                  : null,
              decoration: const InputDecoration(labelText: 'Project'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No project'),
                ),
                for (final project in projectStore.activeProjects)
                  DropdownMenuItem<String?>(
                    value: project.id,
                    child: Text(project.name),
                  ),
              ],
              onChanged: (v) => setState(() => _projectId = v),
            ),
            if (projectStore.labels.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final label in projectStore.labels)
                    FilterChip(
                      label: Text(label.name),
                      selected: _labelIds.contains(label.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _labelIds.add(label.id);
                          } else {
                            _labelIds.remove(label.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('task-save-button'),
                  onPressed: _save,
                  child: Text(widget.existing == null ? 'Add task' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
