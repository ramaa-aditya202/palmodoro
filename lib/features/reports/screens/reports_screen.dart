import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/focus/store/focus_store.dart';
import 'package:pomodoro_app/features/projects/models/project_models.dart';
import 'package:pomodoro_app/features/reports/models/report_models.dart';
import 'package:pomodoro_app/features/reports/store/reports_store.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportsStore>().computeSummary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch FocusStore and TaskStore so Reports refreshes when sessions/tasks change
    context.watch<FocusStore>();
    context.watch<TaskStore>();
    final reportsStore = context.watch<ReportsStore>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final summary = reportsStore.latest;

    return Column(
      children: [
        CompactShellHeader(
          title: 'Reports',
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
          trailing: [
            IconButton(
              tooltip: 'Refresh reports',
              onPressed: () => reportsStore.computeSummary(),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
            ),
          ],
        ),
        Expanded(
          child: summary == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                  children: [
                    // KPI summary grid
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            label: 'Today Focus',
                            value: formatFocusDurationSummary(
                              summary.todayFocusSeconds,
                            ),
                            icon: LucideIcons.timer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiCard(
                            label: '7-Day Focus',
                            value: formatFocusDurationSummary(
                              summary.weekFocusSeconds,
                            ),
                            icon: LucideIcons.flame,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            label: '7-Day Intervals',
                            value: '${summary.weekCompletedIntervals}',
                            icon: LucideIcons.circleCheck,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiCard(
                            label: '7-Day Tasks Done',
                            value: '${summary.weekCompletedTasks}',
                            icon: LucideIcons.listChecks,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 7-day trend bar chart
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last 7 Days Focus Trend',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _WeeklyFocusBarChart(days: summary.last7Days),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Breakdown by project
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus by Project (7 Days)',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (summary.byProject.isEmpty)
                            Text(
                              'No completed focus intervals yet.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.secondaryText,
                              ),
                            )
                          else
                            for (final p in summary.byProject)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: ProjectColors.parse(p.colorHex),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(p.projectName)),
                                    Text(
                                      '${formatFocusDurationSummary(p.focusSeconds)} (${p.completedIntervals})',
                                      style: textTheme.bodySmall
                                          ?.merge(AppTheme.monoTextStyle)
                                          .copyWith(
                                            color: colors.secondaryText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Breakdown by task
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus by Task (7 Days)',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (summary.byTask.isEmpty)
                            Text(
                              'No task-linked focus intervals yet.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.secondaryText,
                              ),
                            )
                          else
                            for (final t in summary.byTask)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(t.taskTitle)),
                                    Text(
                                      '${formatFocusDurationSummary(t.focusSeconds)} (${t.completedIntervals})',
                                      style: textTheme.bodySmall
                                          ?.merge(AppTheme.monoTextStyle)
                                          .copyWith(
                                            color: colors.secondaryText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineSmall
                ?.merge(AppTheme.monoTextStyle)
                .copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyFocusBarChart extends StatelessWidget {
  const _WeeklyFocusBarChart({required this.days});

  final List<DayFocusStat> days;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    var maxSec = 1800;
    for (final d in days) {
      maxSec = math.max(maxSec, d.focusSeconds);
    }

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final d in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${d.focusMinutes}m',
                      style: textTheme.labelSmall
                          ?.merge(AppTheme.monoTextStyle)
                          .copyWith(fontSize: 10, color: colors.secondaryText),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: (68.0 * (d.focusSeconds / maxSec)).clamp(
                        4.0,
                        68.0,
                      ),
                      decoration: BoxDecoration(
                        color: d.focusSeconds > 0
                            ? colors.accent
                            : colors.surfaceHover,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('EEE').format(d.day),
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
