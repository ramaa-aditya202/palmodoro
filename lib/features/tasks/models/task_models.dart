import 'package:pomodoro_app/core/theme/app_theme.dart';

class TaskDependencyCycleException implements Exception {
  const TaskDependencyCycleException();

  @override
  String toString() => 'Cannot create a circular task dependency.';
}

class TaskBlockedException implements Exception {
  const TaskBlockedException(this.blockerTitles);
  final List<String> blockerTitles;

  @override
  String toString() =>
      'Blocked by: ${blockerTitles.isEmpty ? "another task" : blockerTitles.join(", ")}';
}

enum TaskScheduleKind {
  allDay('allDay'),
  timed('timed');

  const TaskScheduleKind(this.storageValue);
  final String storageValue;

  static TaskScheduleKind fromStorage(String? value) =>
      value == 'timed' ? TaskScheduleKind.timed : TaskScheduleKind.allDay;
}

enum TaskRecurrenceUnit {
  day('day', 'Daily'),
  week('week', 'Weekly'),
  month('month', 'Monthly');

  const TaskRecurrenceUnit(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static TaskRecurrenceUnit? fromStorage(String? value) {
    return switch (value) {
      'day' => TaskRecurrenceUnit.day,
      'week' => TaskRecurrenceUnit.week,
      'month' => TaskRecurrenceUnit.month,
      _ => null,
    };
  }
}

class TaskRecurrence {
  const TaskRecurrence({required this.interval, required this.unit})
    : assert(interval > 0);

  final int interval;
  final TaskRecurrenceUnit unit;

  DateTime nextDueDate(DateTime currentDue) {
    switch (unit) {
      case TaskRecurrenceUnit.day:
        return DateTime(
          currentDue.year,
          currentDue.month,
          currentDue.day + interval,
          currentDue.hour,
          currentDue.minute,
          currentDue.second,
        );
      case TaskRecurrenceUnit.week:
        return DateTime(
          currentDue.year,
          currentDue.month,
          currentDue.day + (7 * interval),
          currentDue.hour,
          currentDue.minute,
          currentDue.second,
        );
      case TaskRecurrenceUnit.month:
        final totalMonths = (currentDue.year * 12 + (currentDue.month - 1)) + interval;
        final targetYear = totalMonths ~/ 12;
        final targetMonth = (totalMonths % 12) + 1;
        final maxDayInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        final clampedDay = currentDue.day <= maxDayInTargetMonth
            ? currentDue.day
            : maxDayInTargetMonth;
        return DateTime(
          targetYear,
          targetMonth,
          clampedDay,
          currentDue.hour,
          currentDue.minute,
          currentDue.second,
        );
    }
  }

  String get summary {
    if (interval == 1) return unit.label;
    return 'Every $interval ${unit.storageValue}s';
  }
}

DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isBeforeCalendarDay(DateTime candidate, DateTime referenceDay) =>
    dateOnly(candidate).isBefore(dateOnly(referenceDay));

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.projectId,
    this.parentId,
    this.priority = 4,
    this.dueAt,
    this.scheduleKind = TaskScheduleKind.allDay,
    this.durationMinutes,
    this.recurrence,
    this.estimatedPomodoros = 0,
    this.completedPomodoros = 0,
    this.kanbanStatus = 'todo',
    this.isCompleted = false,
    this.completedAt,
    this.reminderAt,
    this.sortOrder = 0,
    this.labelIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String? projectId;
  final String? parentId;
  final int priority;
  final DateTime? dueAt;
  final TaskScheduleKind scheduleKind;
  final int? durationMinutes;
  final TaskRecurrence? recurrence;
  final int estimatedPomodoros;
  final int completedPomodoros;
  final String kanbanStatus;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? reminderAt;
  final int sortOrder;
  final List<String> labelIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskTimeState timeState(DateTime now) {
    if (isCompleted) return TaskTimeState.completed;
    final due = dueAt;
    if (due == null) return TaskTimeState.future;
    if (scheduleKind == TaskScheduleKind.timed) {
      if (due.isBefore(now)) return TaskTimeState.overdue;
      if (isSameCalendarDay(due, now)) return TaskTimeState.current;
      return TaskTimeState.future;
    }
    if (isBeforeCalendarDay(due, now)) return TaskTimeState.overdue;
    if (isSameCalendarDay(due, now)) return TaskTimeState.current;
    return TaskTimeState.future;
  }

  TaskItem copyWith({
    String? title,
    String? description,
    String? projectId,
    bool clearProject = false,
    String? parentId,
    bool clearParent = false,
    int? priority,
    DateTime? dueAt,
    bool clearDueAt = false,
    TaskScheduleKind? scheduleKind,
    int? durationMinutes,
    bool clearDuration = false,
    TaskRecurrence? recurrence,
    bool clearRecurrence = false,
    int? estimatedPomodoros,
    int? completedPomodoros,
    String? kanbanStatus,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    int? sortOrder,
    List<String>? labelIds,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      projectId: clearProject ? null : (projectId ?? this.projectId),
      parentId: clearParent ? null : (parentId ?? this.parentId),
      priority: priority ?? this.priority,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      scheduleKind: scheduleKind ?? this.scheduleKind,
      durationMinutes:
          clearDuration ? null : (durationMinutes ?? this.durationMinutes),
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      kanbanStatus: kanbanStatus ?? this.kanbanStatus,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
      sortOrder: sortOrder ?? this.sortOrder,
      labelIds: labelIds ?? this.labelIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'project_id': projectId,
    'parent_id': parentId,
    'priority': priority.clamp(1, 4),
    'due_at': dueAt?.millisecondsSinceEpoch,
    'schedule_kind': scheduleKind.storageValue,
    'duration_minutes': durationMinutes,
    'recurrence_interval': recurrence?.interval,
    'recurrence_unit': recurrence?.unit.storageValue,
    'estimated_pomodoros': estimatedPomodoros,
    'completed_pomodoros': completedPomodoros,
    'kanban_status': kanbanStatus,
    'is_completed': isCompleted ? 1 : 0,
    'completed_at': completedAt?.millisecondsSinceEpoch,
    'reminder_at': reminderAt?.millisecondsSinceEpoch,
    'sort_order': sortOrder,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory TaskItem.fromMap(
    Map<String, Object?> map, {
    List<String> labelIds = const [],
  }) {
    final recInterval = map['recurrence_interval'] as int?;
    final recUnit = TaskRecurrenceUnit.fromStorage(
      map['recurrence_unit'] as String?,
    );
    return TaskItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      projectId: map['project_id'] as String?,
      parentId: map['parent_id'] as String?,
      priority: (map['priority'] as int? ?? 4).clamp(1, 4),
      dueAt: map['due_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['due_at'] as int),
      scheduleKind: TaskScheduleKind.fromStorage(
        map['schedule_kind'] as String?,
      ),
      durationMinutes: map['duration_minutes'] as int?,
      recurrence: (recInterval != null && recInterval > 0 && recUnit != null)
          ? TaskRecurrence(interval: recInterval, unit: recUnit)
          : null,
      estimatedPomodoros: map['estimated_pomodoros'] as int? ?? 0,
      completedPomodoros: map['completed_pomodoros'] as int? ?? 0,
      kanbanStatus: map['kanban_status'] as String? ?? 'todo',
      isCompleted: (map['is_completed'] as int? ?? 0) != 0,
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int),
      reminderAt: map['reminder_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['reminder_at'] as int),
      sortOrder: map['sort_order'] as int? ?? 0,
      labelIds: List.unmodifiable(labelIds),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
