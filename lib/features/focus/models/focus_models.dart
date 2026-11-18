enum FocusViewMode {
  full('full'),
  minimal('minimal');

  const FocusViewMode(this.storageValue);
  final String storageValue;

  static FocusViewMode fromStorage(String? value) =>
      value == 'full' ? FocusViewMode.full : FocusViewMode.minimal;
}

enum FocusTimerVisualStyle {
  circle('circle'),
  bar('bar');

  const FocusTimerVisualStyle(this.storageValue);
  final String storageValue;

  static FocusTimerVisualStyle fromStorage(String? value) =>
      value == 'bar' ? FocusTimerVisualStyle.bar : FocusTimerVisualStyle.circle;
}

enum FocusSessionDisplay {
  compact('compact'),
  icons('icons');

  const FocusSessionDisplay(this.storageValue);
  final String storageValue;

  static FocusSessionDisplay fromStorage(String? value) =>
      value == 'icons'
          ? FocusSessionDisplay.icons
          : FocusSessionDisplay.compact;
}

enum FocusSoundSet {
  softKalimba('soft_kalimba', 'Soft kalimba'),
  neonPulse('neon_pulse', 'Neon pulse'),
  orbitBloom('orbit_bloom', 'Orbit bloom');

  const FocusSoundSet(this.storageValue, this.displayName);
  final String storageValue;
  final String displayName;

  static FocusSoundSet fromStorage(String? value) => switch (value) {
    'neon_pulse' => FocusSoundSet.neonPulse,
    'orbit_bloom' => FocusSoundSet.orbitBloom,
    _ => FocusSoundSet.softKalimba,
  };
}

enum FocusSoundCue {
  start('focus_start.wav'),
  complete('focus_complete.wav'),
  pause('focus_pause.wav'),
  resume('focus_resume.wav');

  const FocusSoundCue(this.fileName);
  final String fileName;
}

enum FocusIntervalType {
  work('work', 'Focus'),
  shortBreak('shortBreak', 'Short break'),
  longBreak('longBreak', 'Long break');

  const FocusIntervalType(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static FocusIntervalType fromStorage(String? value) => switch (value) {
    'shortBreak' => FocusIntervalType.shortBreak,
    'longBreak' => FocusIntervalType.longBreak,
    _ => FocusIntervalType.work,
  };
}

enum FocusIntervalStatus {
  ready('ready'),
  running('running'),
  paused('paused'),
  completed('completed'),
  skipped('skipped'),
  stopped('stopped');

  const FocusIntervalStatus(this.storageValue);
  final String storageValue;

  static FocusIntervalStatus fromStorage(String? value) => switch (value) {
    'ready' => FocusIntervalStatus.ready,
    'paused' => FocusIntervalStatus.paused,
    'completed' => FocusIntervalStatus.completed,
    'skipped' => FocusIntervalStatus.skipped,
    'stopped' => FocusIntervalStatus.stopped,
    _ => FocusIntervalStatus.running,
  };
}

class FocusPresetItem {
  const FocusPresetItem({
    required this.id,
    required this.name,
    required this.workSeconds,
    required this.shortBreakSeconds,
    required this.longBreakSeconds,
    required this.intervalsBeforeLongBreak,
    this.autoStartBreaks = false,
    this.autoStartWork = false,
    this.allowPause = true,
    this.strictMode = false,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int workSeconds;
  final int shortBreakSeconds;
  final int longBreakSeconds;
  final int intervalsBeforeLongBreak;
  final bool autoStartBreaks;
  final bool autoStartWork;
  final bool allowPause;
  final bool strictMode;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  int durationFor(FocusIntervalType type) => switch (type) {
    FocusIntervalType.work => workSeconds,
    FocusIntervalType.shortBreak => shortBreakSeconds,
    FocusIntervalType.longBreak => longBreakSeconds,
  };

  FocusPresetItem copyWith({
    String? id,
    String? name,
    int? workSeconds,
    int? shortBreakSeconds,
    int? longBreakSeconds,
    int? intervalsBeforeLongBreak,
    bool? autoStartBreaks,
    bool? autoStartWork,
    bool? allowPause,
    bool? strictMode,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return FocusPresetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      workSeconds: workSeconds ?? this.workSeconds,
      shortBreakSeconds: shortBreakSeconds ?? this.shortBreakSeconds,
      longBreakSeconds: longBreakSeconds ?? this.longBreakSeconds,
      intervalsBeforeLongBreak:
          intervalsBeforeLongBreak ?? this.intervalsBeforeLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartWork: autoStartWork ?? this.autoStartWork,
      allowPause: allowPause ?? this.allowPause,
      strictMode: strictMode ?? this.strictMode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'work_seconds': workSeconds,
    'short_break_seconds': shortBreakSeconds,
    'long_break_seconds': longBreakSeconds,
    'intervals_before_long_break': intervalsBeforeLongBreak,
    'auto_start_breaks': autoStartBreaks ? 1 : 0,
    'auto_start_work': autoStartWork ? 1 : 0,
    'allow_pause': allowPause ? 1 : 0,
    'strict_mode': strictMode ? 1 : 0,
    'is_default': isDefault ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory FocusPresetItem.fromMap(Map<String, Object?> map) {
    return FocusPresetItem(
      id: map['id'] as String,
      name: map['name'] as String,
      workSeconds: map['work_seconds'] as int,
      shortBreakSeconds: map['short_break_seconds'] as int,
      longBreakSeconds: map['long_break_seconds'] as int,
      intervalsBeforeLongBreak: map['intervals_before_long_break'] as int,
      autoStartBreaks: (map['auto_start_breaks'] as int? ?? 0) != 0,
      autoStartWork: (map['auto_start_work'] as int? ?? 0) != 0,
      allowPause: (map['allow_pause'] as int? ?? 1) != 0,
      strictMode: (map['strict_mode'] as int? ?? 0) != 0,
      isDefault: (map['is_default'] as int? ?? 0) != 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}

class FocusRunItem {
  const FocusRunItem({
    required this.id,
    required this.presetId,
    this.taskId,
    required this.status,
    required this.completedWorkIntervals,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String presetId;
  final String? taskId;
  final String status;
  final int completedWorkIntervals;
  final DateTime startedAt;
  final DateTime? endedAt;

  FocusRunItem copyWith({
    String? taskId,
    String? status,
    int? completedWorkIntervals,
    DateTime? endedAt,
  }) {
    return FocusRunItem(
      id: id,
      presetId: presetId,
      taskId: taskId ?? this.taskId,
      status: status ?? this.status,
      completedWorkIntervals:
          completedWorkIntervals ?? this.completedWorkIntervals,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'preset_id': presetId,
    'task_id': taskId,
    'status': status,
    'completed_work_intervals': completedWorkIntervals,
    'started_at': startedAt.millisecondsSinceEpoch,
    'ended_at': endedAt?.millisecondsSinceEpoch,
  };

  factory FocusRunItem.fromMap(Map<String, Object?> map) {
    return FocusRunItem(
      id: map['id'] as String,
      presetId: map['preset_id'] as String,
      taskId: map['task_id'] as String?,
      status: map['status'] as String,
      completedWorkIntervals: map['completed_work_intervals'] as int? ?? 0,
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
      endedAt: map['ended_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['ended_at'] as int),
    );
  }
}

class FocusIntervalItem {
  const FocusIntervalItem({
    required this.id,
    required this.runId,
    required this.type,
    required this.status,
    required this.sequenceIndex,
    required this.durationSeconds,
    this.startedAt,
    this.pausedAt,
    this.accumulatedPausedSeconds = 0,
    this.endedAt,
  });

  final String id;
  final String runId;
  final FocusIntervalType type;
  final FocusIntervalStatus status;
  final int sequenceIndex;
  final int durationSeconds;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final int accumulatedPausedSeconds;
  final DateTime? endedAt;

  Duration remainingAt(DateTime now) {
    if (status == FocusIntervalStatus.ready || startedAt == null) {
      return Duration(seconds: durationSeconds);
    }
    if (status == FocusIntervalStatus.completed ||
        status == FocusIntervalStatus.skipped ||
        status == FocusIntervalStatus.stopped) {
      return Duration.zero;
    }
    final effectiveNow =
        (status == FocusIntervalStatus.paused && pausedAt != null)
            ? pausedAt!
            : now;
    final rawElapsed = effectiveNow.difference(startedAt!).inSeconds;
    final activeElapsed = (rawElapsed - accumulatedPausedSeconds).clamp(
      0,
      durationSeconds,
    );
    final remainingSeconds = (durationSeconds - activeElapsed).clamp(
      0,
      durationSeconds,
    );
    return Duration(seconds: remainingSeconds);
  }

  DateTime? expectedEndAt() {
    if (status != FocusIntervalStatus.running || startedAt == null) {
      return null;
    }
    return startedAt!.add(
      Duration(seconds: durationSeconds + accumulatedPausedSeconds),
    );
  }

  FocusIntervalItem copyWith({
    FocusIntervalStatus? status,
    int? durationSeconds,
    DateTime? startedAt,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    int? accumulatedPausedSeconds,
    DateTime? endedAt,
  }) {
    return FocusIntervalItem(
      id: id,
      runId: runId,
      type: type,
      status: status ?? this.status,
      sequenceIndex: sequenceIndex,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      accumulatedPausedSeconds:
          accumulatedPausedSeconds ?? this.accumulatedPausedSeconds,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'run_id': runId,
    'type': type.storageValue,
    'status': status.storageValue,
    'sequence_index': sequenceIndex,
    'duration_seconds': durationSeconds,
    'started_at': startedAt?.millisecondsSinceEpoch,
    'paused_at': pausedAt?.millisecondsSinceEpoch,
    'accumulated_paused_seconds': accumulatedPausedSeconds,
    'ended_at': endedAt?.millisecondsSinceEpoch,
  };

  factory FocusIntervalItem.fromMap(Map<String, Object?> map) {
    return FocusIntervalItem(
      id: map['id'] as String,
      runId: map['run_id'] as String,
      type: FocusIntervalType.fromStorage(map['type'] as String?),
      status: FocusIntervalStatus.fromStorage(map['status'] as String?),
      sequenceIndex: map['sequence_index'] as int? ?? 0,
      durationSeconds: map['duration_seconds'] as int,
      startedAt: map['started_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
      pausedAt: map['paused_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['paused_at'] as int),
      accumulatedPausedSeconds:
          map['accumulated_paused_seconds'] as int? ?? 0,
      endedAt: map['ended_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['ended_at'] as int),
    );
  }
}

String formatDurationDigital(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 99 * 3600);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$mm:$ss';
  }
  return '$mm:$ss';
}
