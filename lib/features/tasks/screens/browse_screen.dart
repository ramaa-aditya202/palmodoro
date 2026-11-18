import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_list_item.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({this.initialTab = 0, super.key});

  final int initialTab; // 0: Overdue, 1: Completed

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final taskStore = context.watch<TaskStore>();
    final colors = context.appColors;
    final now = DateTime.now();
    final overdue = taskStore.overdueTasks(now);
    final completed = taskStore.completedTasks;
    final currentList = _tab == 0 ? overdue : completed;

    return Column(
      children: [
        CompactShellHeader(
          title: 'Browse',
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                label: Text('Overdue (${overdue.length})'),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Completed (${completed.length})'),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
        ),
        Expanded(
          child: currentList.isEmpty
              ? Center(
                  child: Text(
                    _tab == 0
                        ? 'No overdue tasks.'
                        : 'No completed tasks yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.secondaryText,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
                  children: [
                    for (final task in currentList) TaskListItem(task: task),
                  ],
                ),
        ),
      ],
    );
  }
}
