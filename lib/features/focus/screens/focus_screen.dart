import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/focus/models/focus_models.dart';
import 'package:pomodoro_app/features/focus/store/focus_store.dart';
import 'package:pomodoro_app/features/focus/widgets/focus_completion_celebration.dart';
import 'package:pomodoro_app/features/focus/widgets/focus_preset_dialog.dart';
import 'package:pomodoro_app/features/focus/widgets/focus_timer_stage.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusStore>();
    final tasks = context.watch<TaskStore>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final run = focus.activeRun;
    final interval = focus.activeInterval;
    final preset = focus.activeOrSelectedPreset;
    final remaining = focus.remainingAt(DateTime.now());
    final linkedTask = tasks.byId(focus.linkedTaskId);
    final isIdle = run == null || interval == null;
    final minimal = focus.viewMode == FocusViewMode.minimal;

    return Column(
      children: [
        CompactShellHeader(
          title: 'Focus',
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
          trailing: [
            IconButton(
              tooltip: focus.timerVisualStyle == FocusTimerVisualStyle.circle
                  ? 'Bar timer'
                  : 'Circle timer',
              onPressed: () {
                final next =
                    focus.timerVisualStyle == FocusTimerVisualStyle.circle
                        ? FocusTimerVisualStyle.bar
                        : FocusTimerVisualStyle.circle;
                focus.setTimerVisualStyle(next);
              },
              icon: Icon(
                focus.timerVisualStyle == FocusTimerVisualStyle.circle
                    ? LucideIcons.slidersHorizontal
                    : LucideIcons.circleDot,
                size: 18,
              ),
            ),
            IconButton(
              tooltip: minimal ? 'Full view' : 'Minimal view',
              onPressed: () {
                focus.setViewMode(
                  minimal ? FocusViewMode.full : FocusViewMode.minimal,
                );
              },
              icon: Icon(
                minimal ? LucideIcons.maximize2 : LucideIcons.minimize2,
                size: 18,
              ),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (focus.showCelebration)
                  FocusCompletionCelebration(
                    completedCount: run?.completedWorkIntervals ?? 1,
                    onDismiss: focus.dismissCelebration,
                  ),
                if (focus.strictExitRemainingSeconds != null)
                  Container(
                    key: const Key('strict-mode-hold-banner'),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceTint,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.warning),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.shieldAlert,
                          color: colors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Strict mode: wait ${focus.strictExitRemainingSeconds}s to leave focus',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: focus.cancelStrictExit,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                if (!minimal) ...[
                  _PresetBar(focus: focus, isIdle: isIdle),
                  const SizedBox(height: 12),
                  _LinkedTaskBar(
                    focus: focus,
                    tasks: tasks,
                    linkedTaskTitle: linkedTask?.title,
                    isIdle: isIdle,
                  ),
                  const SizedBox(height: 20),
                ],
                Center(
                  child: FocusTimerVisual(
                    style: focus.timerVisualStyle,
                    remaining: remaining,
                    totalSeconds: isIdle
                        ? preset.workSeconds
                        : interval.durationSeconds,
                    phaseLabel: isIdle ? 'Focus' : interval.type.label,
                    isWork:
                        isIdle || interval.type == FocusIntervalType.work,
                    compact: minimal,
                  ),
                ),
                const SizedBox(height: 20),
                if (!minimal) ...[
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        focus.setSessionDisplay(
                          focus.sessionDisplay == FocusSessionDisplay.compact
                              ? FocusSessionDisplay.icons
                              : FocusSessionDisplay.compact,
                        );
                      },
                      child: FocusRhythmRail(
                        display: focus.sessionDisplay,
                        completedWorkIntervals:
                            run?.completedWorkIntervals ?? 0,
                        intervalsBeforeLongBreak:
                            preset.intervalsBeforeLongBreak,
                        isRunningWork:
                            !isIdle &&
                            interval.type == FocusIntervalType.work &&
                            interval.status == FocusIntervalStatus.running,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (isIdle)
                  FilledButton.icon(
                    key: const Key('focus-start-button'),
                    onPressed: () => focus.startSession(preset: preset),
                    icon: const Icon(LucideIcons.play, size: 18),
                    label: const Text('Start focus'),
                  )
                else
                  _ActiveControls(
                    focus: focus,
                    interval: interval,
                    preset: preset,
                    minimal: minimal,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetBar extends StatelessWidget {
  const _PresetBar({required this.focus, required this.isIdle});

  final FocusStore focus;
  final bool isIdle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final preset = focus.activeOrSelectedPreset;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.flame, size: 18, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: preset.id,
                onChanged: isIdle
                    ? (id) {
                        if (id != null) focus.selectPreset(id);
                      }
                    : null,
                items: [
                  for (final item in focus.presets)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Customize preset',
            onPressed: isIdle
                ? () async {
                    final edited = await showDialog<FocusPresetItem>(
                      context: context,
                      builder: (_) => FocusPresetDialog(existing: preset),
                    );
                    if (edited != null) {
                      await focus.savePreset(edited);
                    }
                  }
                : null,
            icon: const Icon(LucideIcons.pencil, size: 16),
          ),
          IconButton(
            tooltip: 'New preset',
            onPressed: isIdle
                ? () async {
                    final created = await showDialog<FocusPresetItem>(
                      context: context,
                      builder: (_) => const FocusPresetDialog(),
                    );
                    if (created != null) {
                      await focus.savePreset(created);
                    }
                  }
                : null,
            icon: const Icon(LucideIcons.plus, size: 16),
          ),
        ],
      ),
    );
  }
}

class _LinkedTaskBar extends StatelessWidget {
  const _LinkedTaskBar({
    required this.focus,
    required this.tasks,
    required this.linkedTaskTitle,
    required this.isIdle,
  });

  final FocusStore focus;
  final TaskStore tasks;
  final String? linkedTaskTitle;
  final bool isIdle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeTasks = tasks.activeTasks;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.circleCheck, size: 18, color: colors.secondaryText),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: activeTasks.any((t) => t.id == focus.linkedTaskId)
                    ? focus.linkedTaskId
                    : null,
                hint: const Text('Link a task (optional)'),
                onChanged: isIdle ? focus.setLinkedTaskId : null,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No linked task'),
                  ),
                  for (final task in activeTasks)
                    DropdownMenuItem<String?>(
                      value: task.id,
                      child: Text(
                        task.estimatedPomodoros > 0
                            ? '${task.title} (${task.completedPomodoros}/${task.estimatedPomodoros})'
                            : task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class _ActiveControls extends StatelessWidget {
  const _ActiveControls({
    required this.focus,
    required this.interval,
    required this.preset,
    required this.minimal,
  });

  final FocusStore focus;
  final FocusIntervalItem interval;
  final FocusPresetItem preset;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final isReady = interval.status == FocusIntervalStatus.ready;
    final isPaused = interval.status == FocusIntervalStatus.paused;
    final canPause =
        isReady ||
        isPaused ||
        preset.allowPause ||
        interval.type != FocusIntervalType.work;
    final canCompleteEarly =
        !isReady &&
        !(preset.strictMode && interval.type == FocusIntervalType.work);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              key: const Key('focus-primary-action-button'),
              onPressed: canPause
                  ? () {
                      if (isReady) {
                        focus.startReadyInterval();
                      } else if (isPaused) {
                        focus.resume();
                      } else {
                        focus.pause();
                      }
                    }
                  : null,
              icon: Icon(
                isReady || isPaused ? LucideIcons.play : LucideIcons.pause,
                size: 18,
              ),
              label: Text(
                isReady ? 'Start interval' : (isPaused ? 'Resume' : 'Pause'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              key: const Key('focus-complete-interval-button'),
              onPressed: canCompleteEarly
                  ? () => focus.completeActiveInterval()
                  : null,
              icon: const Icon(LucideIcons.check, size: 18),
              label: const Text('Complete'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              key: const Key('focus-skip-button'),
              onPressed: () => focus.requestStopOrSkip(isStop: false),
              icon: const Icon(LucideIcons.skipForward, size: 16),
              label: const Text('Skip'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              key: const Key('focus-stop-button'),
              onPressed: () => focus.requestStopOrSkip(isStop: true),
              icon: const Icon(LucideIcons.square, size: 16),
              label: const Text('Stop'),
            ),
            if (!minimal) ...[
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => focus.adjustActiveIntervalMinutes(5),
                child: const Text('+5m'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
