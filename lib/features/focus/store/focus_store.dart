import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:pomodoro_app/core/audio/focus_sound_service.dart';
import 'package:pomodoro_app/core/notifications/notification_service.dart';
import 'package:pomodoro_app/features/focus/models/focus_models.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';

class FocusStore extends ChangeNotifier {
  FocusStore({
    required Database db,
    required TaskStore taskStore,
    required NotificationService notifications,
    required FocusSoundService sounds,
    SharedPreferences? prefs,
    bool enablePeriodicTicker = true,
  }) : _db = db,
       _taskStore = taskStore,
       _notifications = notifications,
       _sounds = sounds,
       _prefs = prefs {
    _loadPrefs();
    if (enablePeriodicTicker) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        unawaited(_onSecondTick());
      });
    }
  }

  static const int strictExitSeconds = 60;
  static const String _viewModeKey = 'focus.viewMode';
  static const String _timerVisualStyleKey = 'focus.timerVisualStyle';
  static const String _sessionDisplayKey = 'focus.sessionDisplay';
  static const String _soundSetKey = 'focus.soundSet';
  static const String _soundEnabledKey = 'focus.soundEnabled';

  final Database _db;
  final TaskStore _taskStore;
  final NotificationService _notifications;
  final FocusSoundService _sounds;
  final SharedPreferences? _prefs;
  final Uuid _uuid = const Uuid();

  Timer? _ticker;
  bool _ticking = false;
  List<FocusPresetItem> _presets = const [];
  String? _selectedPresetId;
  String? _linkedTaskId;
  FocusRunItem? _activeRun;
  FocusIntervalItem? _activeInterval;
  List<FocusIntervalItem> _sessionIntervals = const [];

  FocusViewMode _viewMode = FocusViewMode.full;
  FocusTimerVisualStyle _timerVisualStyle = FocusTimerVisualStyle.circle;
  FocusSessionDisplay _sessionDisplay = FocusSessionDisplay.compact;
  FocusSoundSet _soundSet = FocusSoundSet.softKalimba;
  bool _soundEnabled = true;

  DateTime? _strictExitStartedAt;
  bool _strictExitIsStop = true;
  int? _strictExitRemainingSeconds;
  bool _showCelebration = false;

  void _loadPrefs() {
    final p = _prefs;
    if (p == null) return;
    final storedView = p.getString(_viewModeKey);
    if (storedView != null) {
      _viewMode = FocusViewMode.fromStorage(storedView);
    }
    final storedVisual = p.getString(_timerVisualStyleKey);
    if (storedVisual != null) {
      _timerVisualStyle = FocusTimerVisualStyle.fromStorage(storedVisual);
    }
    final storedSession = p.getString(_sessionDisplayKey);
    if (storedSession != null) {
      _sessionDisplay = FocusSessionDisplay.fromStorage(storedSession);
    }
    final storedSound = p.getString(_soundSetKey);
    if (storedSound != null) {
      _soundSet = FocusSoundSet.fromStorage(storedSound);
    }
    _soundEnabled = p.getBool(_soundEnabledKey) ?? true;
  }

  List<FocusPresetItem> get presets => _presets;

  FocusPresetItem get selectedPreset {
    for (final preset in _presets) {
      if (preset.id == _selectedPresetId) return preset;
    }
    for (final preset in _presets) {
      if (preset.isDefault) return preset;
    }
    return _presets.first;
  }

  FocusPresetItem get activeOrSelectedPreset {
    final run = _activeRun;
    if (run != null) {
      for (final preset in _presets) {
        if (preset.id == run.presetId) return preset;
      }
    }
    return selectedPreset;
  }

  String? get linkedTaskId => _activeRun?.taskId ?? _linkedTaskId;
  FocusRunItem? get activeRun => _activeRun;
  FocusIntervalItem? get activeInterval => _activeInterval;
  List<FocusIntervalItem> get sessionIntervals => _sessionIntervals;

  FocusViewMode get viewMode => _viewMode;
  FocusTimerVisualStyle get timerVisualStyle => _timerVisualStyle;
  FocusSessionDisplay get sessionDisplay => _sessionDisplay;
  FocusSoundSet get soundSet => _soundSet;
  bool get soundEnabled => _soundEnabled;
  int? get strictExitRemainingSeconds => _strictExitRemainingSeconds;
  bool get showCelebration => _showCelebration;

  Duration remainingAt(DateTime now) {
    final interval = _activeInterval;
    if (interval == null) {
      return Duration(seconds: selectedPreset.workSeconds);
    }
    return interval.remainingAt(now);
  }

  Future<void> load({DateTime? now}) async {
    _loadPrefs();
    final presetRows = await _db.query(
      'focus_presets',
      orderBy: 'is_default DESC, created_at ASC',
    );
    _presets = List.unmodifiable(presetRows.map(FocusPresetItem.fromMap));
    if (_presets.isNotEmpty) {
      _selectedPresetId ??= _presets.first.id;
    }

    final activeRuns = await _db.query(
      'focus_runs',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (activeRuns.isNotEmpty) {
      _activeRun = FocusRunItem.fromMap(activeRuns.first);
      _linkedTaskId = _activeRun!.taskId;
      await _reloadSessionIntervals(_activeRun!.id);
      await reconcileWithClock(now: now);
      await _syncAlarm();
    }
    notifyListeners();
  }

  Future<void> _reloadSessionIntervals(String runId) async {
    final rows = await _db.query(
      'focus_intervals',
      where: 'run_id = ?',
      whereArgs: [runId],
      orderBy: 'sequence_index ASC',
    );
    _sessionIntervals = List.unmodifiable(rows.map(FocusIntervalItem.fromMap));
    _activeInterval = _sessionIntervals.isNotEmpty
        ? _sessionIntervals.last
        : null;
  }

  void selectPreset(String presetId) {
    _selectedPresetId = presetId;
    notifyListeners();
  }

  void setLinkedTaskId(String? taskId) {
    _linkedTaskId = taskId;
    notifyListeners();
  }

  Future<void> setViewMode(FocusViewMode mode) async {
    _viewMode = mode;
    await _prefs?.setString(_viewModeKey, mode.storageValue);
    notifyListeners();
  }

  Future<void> setTimerVisualStyle(FocusTimerVisualStyle style) async {
    _timerVisualStyle = style;
    await _prefs?.setString(_timerVisualStyleKey, style.storageValue);
    notifyListeners();
  }

  Future<void> setSessionDisplay(FocusSessionDisplay display) async {
    _sessionDisplay = display;
    await _prefs?.setString(_sessionDisplayKey, display.storageValue);
    notifyListeners();
  }

  Future<void> setSoundSet(FocusSoundSet set) async {
    _soundSet = set;
    await _prefs?.setString(_soundSetKey, set.storageValue);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _prefs?.setBool(_soundEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> previewSound() async {
    await _sounds.play(_soundSet, FocusSoundCue.start);
  }

  void dismissCelebration() {
    if (!_showCelebration) return;
    _showCelebration = false;
    notifyListeners();
  }

  Future<void> _playCue(FocusSoundCue cue) async {
    if (!_soundEnabled) return;
    await _sounds.play(_soundSet, cue);
  }

  Future<void> _syncAlarm() async {
    final interval = _activeInterval;
    final expectedEnd = interval?.expectedEndAt();
    if (interval != null &&
        interval.status == FocusIntervalStatus.running &&
        expectedEnd != null) {
      await _notifications.scheduleFocusEnd(
        endAt: expectedEnd,
        title: '${interval.type.label} complete',
        body: interval.type == FocusIntervalType.work
            ? 'Time for a break!'
            : 'Ready for your next focus interval.',
      );
    } else {
      await _notifications.cancelFocusEnd();
    }
  }

  Future<void> startSession({
    FocusPresetItem? preset,
    String? taskId,
    DateTime? now,
  }) async {
    final existingRun = _activeRun;
    final existingInterval = _activeInterval;
    if (existingRun != null && existingInterval != null) {
      final currentPreset = activeOrSelectedPreset;
      if (currentPreset.strictMode &&
          existingInterval.type == FocusIntervalType.work &&
          existingInterval.status != FocusIntervalStatus.ready) {
        return;
      }
    }

    final clock = now ?? DateTime.now();
    final chosenPreset = preset ?? selectedPreset;
    _selectedPresetId = chosenPreset.id;
    final effectiveTaskId = taskId ?? _linkedTaskId;
    if (effectiveTaskId != null) {
      _taskStore.requireUnblocked(effectiveTaskId);
    }
    _linkedTaskId = effectiveTaskId;
    _strictExitStartedAt = null;
    _strictExitRemainingSeconds = null;
    _showCelebration = false;

    final run = FocusRunItem(
      id: _uuid.v4(),
      presetId: chosenPreset.id,
      taskId: effectiveTaskId,
      status: 'active',
      completedWorkIntervals: 0,
      startedAt: clock,
    );
    final interval = FocusIntervalItem(
      id: _uuid.v4(),
      runId: run.id,
      type: FocusIntervalType.work,
      status: FocusIntervalStatus.running,
      sequenceIndex: 0,
      durationSeconds: chosenPreset.workSeconds,
      startedAt: clock,
    );

    await _db.transaction((txn) async {
      if (existingRun != null) {
        if (existingInterval != null) {
          final closedOldInterval = existingInterval.copyWith(
            status: FocusIntervalStatus.stopped,
            endedAt: clock,
          );
          await txn.update(
            'focus_intervals',
            closedOldInterval.toMap(),
            where: 'id = ?',
            whereArgs: [closedOldInterval.id],
          );
        }
        await txn.update(
          'focus_runs',
          {'status': 'stopped', 'ended_at': clock.millisecondsSinceEpoch},
          where: 'status = ?',
          whereArgs: ['active'],
        );
      }
      await txn.insert('focus_runs', run.toMap());
      await txn.insert('focus_intervals', interval.toMap());
    });

    _activeRun = run;
    _activeInterval = interval;
    _sessionIntervals = [interval];
    await _syncAlarm();
    await _playCue(FocusSoundCue.start);
    notifyListeners();
  }

  Future<void> startReadyInterval({DateTime? now}) async {
    final interval = _activeInterval;
    if (interval == null || interval.status != FocusIntervalStatus.ready) {
      return;
    }
    final clock = now ?? DateTime.now();
    final updated = interval.copyWith(
      status: FocusIntervalStatus.running,
      startedAt: clock,
      clearPausedAt: true,
      accumulatedPausedSeconds: 0,
    );
    await _db.update(
      'focus_intervals',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );
    await _reloadSessionIntervals(updated.runId);
    await _syncAlarm();
    await _playCue(FocusSoundCue.start);
    notifyListeners();
  }

  Future<void> pause({DateTime? now}) async {
    final interval = _activeInterval;
    if (interval == null || interval.status != FocusIntervalStatus.running) {
      return;
    }
    final preset = activeOrSelectedPreset;
    if (!preset.allowPause && interval.type == FocusIntervalType.work) {
      return;
    }
    final clock = now ?? DateTime.now();
    final updated = interval.copyWith(
      status: FocusIntervalStatus.paused,
      pausedAt: clock,
    );
    await _db.update(
      'focus_intervals',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );
    await _reloadSessionIntervals(updated.runId);
    await _syncAlarm();
    await _playCue(FocusSoundCue.pause);
    notifyListeners();
  }

  Future<void> resume({DateTime? now}) async {
    final interval = _activeInterval;
    if (interval == null || interval.status != FocusIntervalStatus.paused) {
      return;
    }
    final clock = now ?? DateTime.now();
    final extraPaused = interval.pausedAt == null
        ? 0
        : clock.difference(interval.pausedAt!).inSeconds.clamp(0, 86400 * 7);
    final updated = interval.copyWith(
      status: FocusIntervalStatus.running,
      clearPausedAt: true,
      accumulatedPausedSeconds:
          interval.accumulatedPausedSeconds + extraPaused,
    );
    await _db.update(
      'focus_intervals',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );
    await _reloadSessionIntervals(updated.runId);
    await _syncAlarm();
    await _playCue(FocusSoundCue.resume);
    notifyListeners();
  }

  Future<void> adjustActiveIntervalMinutes(
    int deltaMinutes, {
    DateTime? now,
  }) async {
    final interval = _activeInterval;
    if (interval == null) return;
    final nextSeconds = (interval.durationSeconds + (deltaMinutes * 60)).clamp(
      60,
      180 * 60,
    );
    final updated = interval.copyWith(durationSeconds: nextSeconds);
    await _db.update(
      'focus_intervals',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );
    await _reloadSessionIntervals(updated.runId);
    await _syncAlarm();
    notifyListeners();
  }

  Future<void> completeActiveInterval({DateTime? now}) async {
    final interval = _activeInterval;
    if (interval == null) return;
    if (interval.status == FocusIntervalStatus.ready) {
      return;
    }
    final clock = now ?? DateTime.now();
    final preset = activeOrSelectedPreset;
    if (preset.strictMode &&
        interval.type == FocusIntervalType.work &&
        interval.remainingAt(clock) > Duration.zero) {
      return;
    }
    await _finishInterval(skipped: false, now: clock);
  }

  Future<void> _finishInterval({
    required bool skipped,
    DateTime? now,
  }) async {
    final run = _activeRun;
    final interval = _activeInterval;
    if (run == null || interval == null) return;
    final clock = now ?? DateTime.now();
    final preset = activeOrSelectedPreset;

    _strictExitStartedAt = null;
    _strictExitRemainingSeconds = null;

    final completedStatus = skipped
        ? FocusIntervalStatus.skipped
        : FocusIntervalStatus.completed;
    final closedInterval = interval.copyWith(
      status: completedStatus,
      endedAt: clock,
    );

    final wasWork = interval.type == FocusIntervalType.work;
    final nextWorkCount = (!skipped && wasWork)
        ? run.completedWorkIntervals + 1
        : run.completedWorkIntervals;
    final updatedRun = run.copyWith(completedWorkIntervals: nextWorkCount);

    final FocusIntervalType nextType;
    if (wasWork) {
      final target = preset.intervalsBeforeLongBreak.clamp(1, 12);
      final dueLongBreak = nextWorkCount > 0 && (nextWorkCount % target == 0);
      nextType = dueLongBreak
          ? FocusIntervalType.longBreak
          : FocusIntervalType.shortBreak;
    } else {
      nextType = FocusIntervalType.work;
    }

    final autoStart = nextType == FocusIntervalType.work
        ? preset.autoStartWork
        : preset.autoStartBreaks;

    final nextInterval = FocusIntervalItem(
      id: _uuid.v4(),
      runId: run.id,
      type: nextType,
      status: autoStart
          ? FocusIntervalStatus.running
          : FocusIntervalStatus.ready,
      sequenceIndex: interval.sequenceIndex + 1,
      durationSeconds: preset.durationFor(nextType),
      startedAt: autoStart ? clock : null,
    );

    await _db.transaction((txn) async {
      await txn.update(
        'focus_intervals',
        closedInterval.toMap(),
        where: 'id = ?',
        whereArgs: [closedInterval.id],
      );
      await txn.update(
        'focus_runs',
        updatedRun.toMap(),
        where: 'id = ?',
        whereArgs: [updatedRun.id],
      );
      await txn.insert('focus_intervals', nextInterval.toMap());
    });

    if (!skipped && wasWork) {
      _showCelebration = true;
      if (run.taskId != null) {
        await _taskStore.incrementCompletedPomodoros(run.taskId!);
      }
    }

    _activeRun = updatedRun;
    await _reloadSessionIntervals(run.id);
    await _syncAlarm();
    if (!skipped) {
      await _playCue(FocusSoundCue.complete);
    }
    notifyListeners();
  }

  Future<void> requestStopOrSkip({
    required bool isStop,
    DateTime? now,
  }) async {
    final interval = _activeInterval;
    if (interval == null) return;
    final clock = now ?? DateTime.now();
    final preset = activeOrSelectedPreset;

    final requiresStrictHold =
        preset.strictMode &&
        interval.type == FocusIntervalType.work &&
        interval.status != FocusIntervalStatus.ready;

    if (requiresStrictHold) {
      _strictExitStartedAt ??= clock;
      _strictExitIsStop = isStop;
      final elapsed = clock.difference(_strictExitStartedAt!).inSeconds;
      _strictExitRemainingSeconds = (strictExitSeconds - elapsed).clamp(
        0,
        strictExitSeconds,
      );
      notifyListeners();
      return;
    }

    if (isStop) {
      await _stopRunImmediate(now: clock);
    } else {
      await _finishInterval(skipped: true, now: clock);
    }
  }

  void cancelStrictExit() {
    _strictExitStartedAt = null;
    _strictExitRemainingSeconds = null;
    notifyListeners();
  }

  Future<void> tickStrictExit({DateTime? now}) async {
    final started = _strictExitStartedAt;
    if (started == null) return;
    final clock = now ?? DateTime.now();
    final elapsed = clock.difference(started).inSeconds;
    final remaining = (strictExitSeconds - elapsed).clamp(0, strictExitSeconds);
    _strictExitRemainingSeconds = remaining;
    if (remaining <= 0) {
      final isStop = _strictExitIsStop;
      _strictExitStartedAt = null;
      _strictExitRemainingSeconds = null;
      if (isStop) {
        await _stopRunImmediate(now: clock);
      } else {
        await _finishInterval(skipped: true, now: clock);
      }
      return;
    }
    notifyListeners();
  }

  Future<void> _stopRunImmediate({DateTime? now}) async {
    final run = _activeRun;
    final interval = _activeInterval;
    if (run == null) return;
    final clock = now ?? DateTime.now();

    await _db.transaction((txn) async {
      if (interval != null) {
        final stoppedInterval = interval.copyWith(
          status: FocusIntervalStatus.stopped,
          endedAt: clock,
        );
        await txn.update(
          'focus_intervals',
          stoppedInterval.toMap(),
          where: 'id = ?',
          whereArgs: [stoppedInterval.id],
        );
      }
      final stoppedRun = run.copyWith(status: 'stopped', endedAt: clock);
      await txn.update(
        'focus_runs',
        stoppedRun.toMap(),
        where: 'id = ?',
        whereArgs: [stoppedRun.id],
      );
    });

    _activeRun = null;
    _activeInterval = null;
    _sessionIntervals = const [];
    _strictExitStartedAt = null;
    _strictExitRemainingSeconds = null;
    await _notifications.cancelFocusEnd();
    notifyListeners();
  }

  Future<void> reconcileWithClock({DateTime? now}) async {
    final interval = _activeInterval;
    if (interval == null || interval.status != FocusIntervalStatus.running) {
      return;
    }
    final clock = now ?? DateTime.now();
    if (interval.remainingAt(clock) <= Duration.zero) {
      await _finishInterval(skipped: false, now: clock);
    } else {
      notifyListeners();
    }
  }

  Future<void> _onSecondTick() async {
    if (_ticking) return;
    _ticking = true;
    try {
      final now = DateTime.now();
      if (_strictExitStartedAt != null) {
        await tickStrictExit(now: now);
      }
      await reconcileWithClock(now: now);
    } finally {
      _ticking = false;
    }
  }

  Future<FocusPresetItem> savePreset(FocusPresetItem preset) async {
    final now = DateTime.now();
    final exists = _presets.any((p) => p.id == preset.id);
    final item = preset.copyWith(updatedAt: now);

    await _db.transaction((txn) async {
      if (item.isDefault) {
        await txn.update('focus_presets', {'is_default': 0});
      }
      if (exists) {
        await txn.update(
          'focus_presets',
          item.toMap(),
          where: 'id = ?',
          whereArgs: [item.id],
        );
      } else {
        await txn.insert('focus_presets', item.toMap());
      }
    });
    _selectedPresetId = item.id;
    await load();
    return selectedPreset;
  }

  Future<void> deletePreset(String id) async {
    if (_presets.length <= 1) return;
    await _db.delete('focus_presets', where: 'id = ?', whereArgs: [id]);
    if (_selectedPresetId == id) {
      _selectedPresetId = null;
    }
    await load();
  }

  Future<void> disposeStore() async {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
