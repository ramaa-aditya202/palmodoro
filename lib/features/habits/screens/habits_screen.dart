import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/habits/models/habit_models.dart';
import 'package:pomodoro_app/features/habits/store/habit_store.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final DateTime _selectedDay = dateOnly(DateTime.now());

  Future<void> _showCreateOrEditHabitDialog({HabitItem? existing}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _HabitEditorDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitStore = context.watch<HabitStore>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final habits = habitStore.habits;

    return Column(
      children: [
        CompactShellHeader(
          title: 'Habits',
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
          trailing: [
            IconButton(
              key: const Key('habit-new-button'),
              tooltip: 'New habit',
              onPressed: () => _showCreateOrEditHabitDialog(),
              icon: Icon(LucideIcons.plus, size: 20, color: colors.accent),
            ),
          ],
        ),
        Expanded(
          child: habits.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.repeat,
                          size: 40,
                          color: colors.secondaryText,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Build daily habits',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to track your daily routines and streaks.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                  children: [
                    for (final habit in habits)
                      _HabitCard(
                        habit: habit,
                        selectedDay: _selectedDay,
                        habitStore: habitStore,
                        onEdit: () =>
                            _showCreateOrEditHabitDialog(existing: habit),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.selectedDay,
    required this.habitStore,
    required this.onEdit,
  });

  final HabitItem habit;
  final DateTime selectedDay;
  final HabitStore habitStore;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final today = dateOnly(DateTime.now());
    final count = habitStore.checkInCountForDay(habit.id, selectedDay);
    final completed = habitStore.isCompletedOnDay(habit, selectedDay);
    final streak = habitStore.currentStreak(habit, today);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: completed ? colors.success : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: completed ? colors.accentTint : colors.surfaceTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  habit.iconData,
                  size: 18,
                  color: completed ? colors.accent : colors.secondaryText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primaryText,
                      ),
                    ),
                    Text(
                      '${habit.dayPeriod.label} · $count/${habit.targetPerDay} today · $streak day streak',
                      style: textTheme.labelSmall
                          ?.merge(AppTheme.monoTextStyle)
                          .copyWith(color: colors.secondaryText),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                key: ValueKey('habit-checkin-${habit.id}'),
                onPressed: () =>
                    habitStore.toggleOrIncrementCheckIn(habit.id, selectedDay),
                icon: Icon(
                  completed ? LucideIcons.check : LucideIcons.plus,
                  size: 16,
                ),
                label: Text('$count/${habit.targetPerDay}'),
              ),
              PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') {
                    onEdit();
                  } else if (action == 'delete') {
                    habitStore.deleteHabit(habit.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Last 7 days mini check-in strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 6; i >= 0; i--)
                Builder(
                  builder: (context) {
                    final day = DateTime(
                      today.year,
                      today.month,
                      today.day - i,
                    );
                    final done = habitStore.isCompletedOnDay(habit, day);
                    return GestureDetector(
                      onTap: () =>
                          habitStore.toggleOrIncrementCheckIn(habit.id, day),
                      child: Container(
                        width: 36,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: done ? colors.accentTint : colors.surfaceTint,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: done ? colors.accent : colors.border,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('E').format(day).substring(0, 1),
                              style: textTheme.labelSmall?.copyWith(
                                color: done
                                    ? colors.accent
                                    : colors.secondaryText,
                              ),
                            ),
                            Text(
                              '${day.day}',
                              style: textTheme.labelSmall
                                  ?.merge(AppTheme.monoTextStyle)
                                  .copyWith(
                                    color: done
                                        ? colors.accent
                                        : colors.primaryText,
                                    fontWeight: done
                                        ? FontWeight.w700
                                        : FontWeight.w500,
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
        ],
      ),
    );
  }
}

class _HabitEditorDialog extends StatefulWidget {
  const _HabitEditorDialog({required this.existing});

  final HabitItem? existing;

  @override
  State<_HabitEditorDialog> createState() => _HabitEditorDialogState();
}

class _HabitEditorDialogState extends State<_HabitEditorDialog> {
  late final TextEditingController _titleController;
  late String _icon;
  late int _targetPerDay;
  late HabitDayPeriod _period;
  late Set<int> _weekdays;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _icon = existing?.icon ?? 'check';
    _targetPerDay = existing?.targetPerDay ?? 1;
    _period = existing?.dayPeriod ?? HabitDayPeriod.anytime;
    _weekdays = {...(existing?.weekdays ?? const [1, 2, 3, 4, 5, 6, 7])};
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New habit' : 'Edit habit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('habit-title-input'),
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Habit name'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in HabitIconChoice.values)
                  ChoiceChip(
                    label: Icon(choice.iconData, size: 16),
                    selected: _icon == choice.storageValue,
                    onSelected: (_) =>
                        setState(() => _icon = choice.storageValue),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Text('Daily target')),
                IconButton(
                  onPressed: _targetPerDay > 1
                      ? () => setState(() => _targetPerDay--)
                      : null,
                  icon: const Icon(Icons.remove, size: 18),
                ),
                Text(
                  '$_targetPerDay',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.merge(AppTheme.monoTextStyle),
                ),
                IconButton(
                  onPressed: () => setState(() => _targetPerDay++),
                  icon: const Icon(Icons.add, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<HabitDayPeriod>(
              initialValue: _period,
              decoration: const InputDecoration(labelText: 'Time of day'),
              items: [
                for (final p in HabitDayPeriod.values)
                  DropdownMenuItem(value: p, child: Text(p.label)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _period = v);
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in const [
                  (1, 'M'),
                  (2, 'T'),
                  (3, 'W'),
                  (4, 'T'),
                  (5, 'F'),
                  (6, 'S'),
                  (7, 'S'),
                ])
                  FilterChip(
                    label: Text(entry.$2),
                    selected: _weekdays.contains(entry.$1),
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _weekdays.add(entry.$1);
                        } else if (_weekdays.length > 1) {
                          _weekdays.remove(entry.$1);
                        }
                      });
                    },
                  ),
              ],
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
          key: const Key('habit-save-button'),
          onPressed: () async {
            final text = _titleController.text.trim();
            if (text.isEmpty) return;
            final store = context.read<HabitStore>();
            final sortedDays = _weekdays.toList()..sort();
            final existing = widget.existing;
            if (existing == null) {
              await store.createHabit(
                title: text,
                icon: _icon,
                targetPerDay: _targetPerDay,
                dayPeriod: _period,
                weekdays: sortedDays,
              );
            } else {
              await store.updateHabit(
                existing.copyWith(
                  title: text,
                  icon: _icon,
                  targetPerDay: _targetPerDay,
                  dayPeriod: _period,
                  weekdays: sortedDays,
                ),
              );
            }
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
