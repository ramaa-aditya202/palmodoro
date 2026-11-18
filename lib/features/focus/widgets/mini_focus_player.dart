import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/bottom_panel_surface.dart';
import 'package:pomodoro_app/features/focus/models/focus_models.dart';
import 'package:pomodoro_app/features/focus/store/focus_store.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';

class MiniFocusPlayer extends StatelessWidget {
  const MiniFocusPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusStore>();
    final tasks = context.watch<TaskStore>();
    final run = focus.activeRun;
    final interval = focus.activeInterval;
    if (run == null || interval == null) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final remaining = focus.remainingAt(DateTime.now());
    final preset = focus.activeOrSelectedPreset;
    final task = tasks.byId(run.taskId);
    final isReady = interval.status == FocusIntervalStatus.ready;
    final isPaused = interval.status == FocusIntervalStatus.paused;
    final canPause =
        isReady ||
        isPaused ||
        preset.allowPause ||
        interval.type != FocusIntervalType.work;

    return BottomPanelSurface(
      key: const Key('mini-focus-player'),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: InkWell(
        onTap: () => context.go('/focus'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                interval.type == FocusIntervalType.work
                    ? LucideIcons.timer
                    : LucideIcons.coffee,
                color: colors.accent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isReady ? 'Ready · ' : ''}${interval.type.label} · ${formatDurationDigital(remaining)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium
                          ?.merge(AppTheme.monoTextStyle)
                          .copyWith(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (focus.strictExitRemainingSeconds != null)
                      Text(
                        'Strict mode: wait ${focus.strictExitRemainingSeconds}s',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (task != null)
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              if (focus.strictExitRemainingSeconds != null)
                TextButton(
                  onPressed: focus.cancelStrictExit,
                  child: const Text('Cancel'),
                )
              else ...[
                IconButton(
                  tooltip: isReady
                      ? 'Start'
                      : (isPaused ? 'Resume' : 'Pause'),
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
                  style: IconButton.styleFrom(
                    backgroundColor: colors.accentTint,
                    foregroundColor: colors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    isReady || isPaused ? LucideIcons.play : LucideIcons.pause,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Stop',
                  onPressed: () => focus.requestStopOrSkip(isStop: true),
                  icon: const Icon(LucideIcons.square, size: 18),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
