import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_list_item.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskStore = context.watch<TaskStore>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final overdue = taskStore.overdueTasks(now);
    final today = taskStore.todayTasks(now);

    return Column(
      children: [
        CompactShellHeader(
          title: 'Today',
          isTodayHeader: true,
          todayDate: now,
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
        ),
        Expanded(
          child: overdue.isEmpty && today.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.calendarCheck,
                          size: 40,
                          color: colors.secondaryText,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'All clear for today',
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to plan a task or start a focus session.',
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
                    if (overdue.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Overdue (${overdue.length})',
                          style: textTheme.labelLarge?.copyWith(
                            color: colors.overdue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      for (final task in overdue) TaskListItem(task: task),
                      const SizedBox(height: 12),
                    ],
                    if (today.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Today (${today.length})',
                          style: textTheme.labelLarge?.copyWith(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      for (final task in today) TaskListItem(task: task),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
