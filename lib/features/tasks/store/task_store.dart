import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:pomodoro_app/core/notifications/notification_service.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';

class DeletedTaskSnapshot {
  const DeletedTaskSnapshot({
    required this.task,
    this.blockerIds = const [],
    this.blockedIds = const [],
  });

  final TaskItem task;
  final List<String> blockerIds;
  final List<String> blockedIds;
}

class TaskStore extends ChangeNotifier {
  TaskStore(this._db, {NotificationService? notifications})
    : _notifications = notifications;

  final Database _db;
  final NotificationService? _notifications;
  final Uuid _uuid = const Uuid();

  List<TaskItem> _tasks = const [];
  Map<String, List<String>> _blockersByTask = const {};

  List<TaskItem> get tasks => _tasks;

  List<TaskItem> get activeTasks =>
      _tasks.where((t) => !t.isCompleted).toList(growable: false);

  List<TaskItem> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList(growable: false);

  TaskItem? byId(String? id) {
    if (id == null) return null;
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  List<TaskItem> subtasksOf(String parentId) {
    return _tasks
        .where((task) => task.parentId == parentId)
        .toList(growable: false);
  }

  ({int completed, int total}) subtaskProgress(String parentId) {
    var total = 0;
    var completed = 0;
    for (final task in _tasks) {
      if (task.parentId == parentId) {
        total++;
        if (task.isCompleted) completed++;
      }
    }
    return (completed: completed, total: total);
  }

  List<TaskItem> blockersOf(String taskId) {
    final ids = _blockersByTask[taskId];
    if (ids == null || ids.isEmpty) return const [];
    final result = <TaskItem>[];
    for (final id in ids) {
      final blocker = byId(id);
      if (blocker != null) result.add(blocker);
    }
    return result;
  }

  List<TaskItem> incompleteBlockersOf(String taskId) {
    return blockersOf(
      taskId,
    ).where((blocker) => !blocker.isCompleted).toList(growable: false);
  }

  bool isTaskBlocked(String taskId) => incompleteBlockersOf(taskId).isNotEmpty;

  void requireUnblocked(String taskId) {
    final blockers = incompleteBlockersOf(taskId);
    if (blockers.isNotEmpty) {
      throw TaskBlockedException(
        blockers.map((b) => b.title).toList(growable: false),
      );
    }
  }

  bool _createsCycle({
    required String blockerTaskId,
    required String blockedTaskId,
  }) {
    if (blockerTaskId == blockedTaskId) return true;
    // Check if blockedTaskId already directly or transitively blocks blockerTaskId
    final visited = <String>{};
    final stack = <String>[blockerTaskId];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (current == blockedTaskId) return true;
      if (!visited.add(current)) continue;
      final upstream = _blockersByTask[current];
      if (upstream != null) {
        stack.addAll(upstream);
      }
    }
    return false;
  }

  Future<void> addDependency({
    required String blockerTaskId,
    required String blockedTaskId,
  }) async {
    if (_createsCycle(
      blockerTaskId: blockerTaskId,
      blockedTaskId: blockedTaskId,
    )) {
      throw const TaskDependencyCycleException();
    }
    await _db.insert(
      'task_dependencies',
      {
        'blocker_task_id': blockerTaskId,
        'blocked_task_id': blockedTaskId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await load();
  }

  Future<void> removeDependency({
    required String blockerTaskId,
    required String blockedTaskId,
  }) async {
    await _db.delete(
      'task_dependencies',
      where: 'blocker_task_id = ? AND blocked_task_id = ?',
      whereArgs: [blockerTaskId, blockedTaskId],
    );
    await load();
  }

  List<TaskItem> searchTasks(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _tasks
        .where(
          (task) =>
              task.title.toLowerCase().contains(q) ||
              task.description.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  List<TaskItem> overdueTasks(DateTime now) {
    return _tasks
        .where((task) {
          if (task.isCompleted || task.dueAt == null || task.parentId != null) {
            return false;
          }
          return isBeforeCalendarDay(task.dueAt!, now);
        })
        .toList(growable: false);
  }

  List<TaskItem> todayTasks(DateTime now) {
    return _tasks
        .where((task) {
          if (task.isCompleted || task.dueAt == null || task.parentId != null) {
            return false;
          }
          return isSameCalendarDay(task.dueAt!, now);
        })
        .toList(growable: false);
  }

  List<TaskItem> tasksForDay(DateTime day, {bool includeCompleted = false}) {
    return _tasks
        .where((task) {
          if (task.parentId != null || task.dueAt == null) return false;
          if (!includeCompleted && task.isCompleted) return false;
          return isSameCalendarDay(task.dueAt!, day);
        })
        .toList(growable: false);
  }

  List<TaskItem> unscheduledTasks() {
    return _tasks
        .where(
          (task) =>
              !task.isCompleted && task.parentId == null && task.dueAt == null,
        )
        .toList(growable: false);
  }

  Map<DateTime, List<TaskItem>> upcomingByDay(
    DateTime startDay, {
    int days = 14,
  }) {
    final normalizedStart = dateOnly(startDay);
    final result = <DateTime, List<TaskItem>>{
      for (var i = 0; i < days; i++)
        DateTime(
          normalizedStart.year,
          normalizedStart.month,
          normalizedStart.day + i,
        ): <TaskItem>[],
    };

    for (final task in _tasks) {
      if (task.isCompleted || task.dueAt == null || task.parentId != null) {
        continue;
      }
      final key = dateOnly(task.dueAt!);
      final bucket = result[key];
      if (bucket != null) {
        bucket.add(task);
      }
    }
    return result;
  }

  List<TaskItem> tasksForProject(
    String? projectId, {
    bool includeCompleted = false,
  }) {
    return _tasks
        .where((task) {
          if (task.parentId != null) return false;
          if (!includeCompleted && task.isCompleted) return false;
          return task.projectId == projectId;
        })
        .toList(growable: false);
  }

  List<TaskItem> tasksForLabel(
    String labelId, {
    bool includeCompleted = false,
  }) {
    return _tasks
        .where((task) {
          if (task.parentId != null) return false;
          if (!includeCompleted && task.isCompleted) return false;
          return task.labelIds.contains(labelId);
        })
        .toList(growable: false);
  }

  Future<void> load() async {
    final rows = await _db.query(
      'tasks',
      orderBy:
          'is_completed ASC, priority ASC, CASE WHEN due_at IS NULL THEN 1 ELSE 0 END ASC, due_at ASC, sort_order ASC, created_at ASC',
    );
    final labelRows = await _db.query('task_labels');
    final labelsByTask = <String, List<String>>{};
    for (final row in labelRows) {
      final taskId = row['task_id'] as String;
      final labelId = row['label_id'] as String;
      (labelsByTask[taskId] ??= <String>[]).add(labelId);
    }

    final depRows = await _db.query('task_dependencies');
    final blockers = <String, List<String>>{};
    for (final row in depRows) {
      final blockerId = row['blocker_task_id'] as String;
      final blockedId = row['blocked_task_id'] as String;
      (blockers[blockedId] ??= <String>[]).add(blockerId);
    }

    _tasks = List.unmodifiable(
      rows.map(
        (row) => TaskItem.fromMap(
          row,
          labelIds: labelsByTask[row['id'] as String] ?? const [],
        ),
      ),
    );
    _blockersByTask = Map.unmodifiable(
      blockers.map((k, v) => MapEntry(k, List<String>.unmodifiable(v))),
    );
    notifyListeners();
  }

  Future<TaskItem> createTask({
    required String title,
    String description = '',
    String? projectId,
    String? parentId,
    int priority = 4,
    DateTime? dueAt,
    TaskScheduleKind scheduleKind = TaskScheduleKind.allDay,
    int? durationMinutes,
    TaskRecurrence? recurrence,
    int estimatedPomodoros = 0,
    String kanbanStatus = 'todo',
    DateTime? reminderAt,
    List<String> labelIds = const [],
  }) async {
    final now = DateTime.now();
    final item = TaskItem(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      projectId: projectId,
      parentId: parentId,
      priority: priority.clamp(1, 4),
      dueAt: dueAt,
      scheduleKind: scheduleKind,
      durationMinutes: durationMinutes,
      recurrence: recurrence,
      estimatedPomodoros: estimatedPomodoros,
      completedPomodoros: 0,
      kanbanStatus: kanbanStatus,
      isCompleted: kanbanStatus == 'done',
      completedAt: kanbanStatus == 'done' ? now : null,
      reminderAt: reminderAt,
      sortOrder: _tasks.length,
      labelIds: List.unmodifiable(labelIds.toSet()),
      createdAt: now,
      updatedAt: now,
    );

    await _db.transaction((txn) async {
      await txn.insert('tasks', item.toMap());
      for (final labelId in item.labelIds) {
        await txn.insert('task_labels', {
          'task_id': item.id,
          'label_id': labelId,
        });
      }
    });
    if (item.reminderAt != null) {
      await _notifications?.scheduleTaskReminder(
        taskId: item.id,
        reminderAt: item.reminderAt!,
        title: item.title,
      );
    }
    await load();
    return byId(item.id) ?? item;
  }

  Future<TaskItem> updateTask(TaskItem updated) async {
    final item = updated.copyWith(
      title: updated.title.trim(),
      labelIds: List.unmodifiable(updated.labelIds.toSet()),
      updatedAt: DateTime.now(),
    );
    await _db.transaction((txn) async {
      await txn.update(
        'tasks',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      await txn.delete(
        'task_labels',
        where: 'task_id = ?',
        whereArgs: [item.id],
      );
      for (final labelId in item.labelIds) {
        await txn.insert('task_labels', {
          'task_id': item.id,
          'label_id': labelId,
        });
      }
    });
    if (item.reminderAt != null && !item.isCompleted) {
      await _notifications?.scheduleTaskReminder(
        taskId: item.id,
        reminderAt: item.reminderAt!,
        title: item.title,
      );
    } else {
      await _notifications?.cancelTaskReminder(item.id);
    }
    await load();
    return byId(item.id) ?? item;
  }

  Future<TaskItem> setTaskReminder(String taskId, DateTime? reminderAt) async {
    final existing = byId(taskId);
    if (existing == null) throw StateError('Task not found: $taskId');
    final next = existing.copyWith(
      reminderAt: reminderAt,
      clearReminderAt: reminderAt == null,
      updatedAt: DateTime.now(),
    );
    return updateTask(next);
  }

  Future<TaskItem> setTaskPriority(String taskId, int priority) async {
    final existing = byId(taskId);
    if (existing == null) throw StateError('Task not found: $taskId');
    return updateTask(existing.copyWith(priority: priority.clamp(1, 4)));
  }

  Future<TaskItem> moveKanbanStatus(
    String taskId,
    String kanbanStatus, {
    DateTime? now,
  }) async {
    final existing = byId(taskId);
    if (existing == null) throw StateError('Task not found: $taskId');
    final clock = now ?? DateTime.now();

    if (kanbanStatus == 'done' && !existing.isCompleted) {
      requireUnblocked(taskId);
      if (existing.recurrence != null) {
        final baseDue = existing.dueAt ?? clock;
        final next = existing.copyWith(
          dueAt: existing.recurrence!.nextDueDate(baseDue),
          kanbanStatus: 'todo',
          isCompleted: false,
          clearCompletedAt: true,
          updatedAt: clock,
        );
        await _db.update(
          'tasks',
          next.toMap(),
          where: 'id = ?',
          whereArgs: [next.id],
        );
        await load();
        return byId(next.id) ?? next;
      }
      final next = existing.copyWith(
        kanbanStatus: 'done',
        isCompleted: true,
        completedAt: clock,
        updatedAt: clock,
      );
      await _db.update(
        'tasks',
        next.toMap(),
        where: 'id = ?',
        whereArgs: [next.id],
      );
      await _notifications?.cancelTaskReminder(next.id);
      await load();
      return byId(next.id) ?? next;
    }

    final next = existing.copyWith(
      kanbanStatus: kanbanStatus,
      isCompleted: kanbanStatus == 'done',
      completedAt: kanbanStatus == 'done' ? (existing.completedAt ?? clock) : null,
      clearCompletedAt: kanbanStatus != 'done',
      updatedAt: clock,
    );
    await _db.update(
      'tasks',
      next.toMap(),
      where: 'id = ?',
      whereArgs: [next.id],
    );
    await load();
    return byId(next.id) ?? next;
  }

  Future<TaskItem> toggleComplete(String taskId, {DateTime? now}) async {
    final existing = byId(taskId);
    if (existing == null) {
      throw StateError('Task not found: $taskId');
    }
    if (!existing.isCompleted) {
      requireUnblocked(taskId);
    }
    final clock = now ?? DateTime.now();

    TaskItem next;
    if (!existing.isCompleted && existing.recurrence != null) {
      final baseDue = existing.dueAt ?? clock;
      final advancedDue = existing.recurrence!.nextDueDate(baseDue);
      next = existing.copyWith(
        dueAt: advancedDue,
        isCompleted: false,
        clearCompletedAt: true,
        updatedAt: clock,
      );
    } else if (!existing.isCompleted) {
      next = existing.copyWith(
        isCompleted: true,
        completedAt: clock,
        kanbanStatus: 'done',
        updatedAt: clock,
      );
      await _notifications?.cancelTaskReminder(existing.id);
    } else {
      next = existing.copyWith(
        isCompleted: false,
        clearCompletedAt: true,
        kanbanStatus: 'todo',
        updatedAt: clock,
      );
    }

    await _db.update(
      'tasks',
      next.toMap(),
      where: 'id = ?',
      whereArgs: [next.id],
    );
    await load();
    return byId(next.id) ?? next;
  }

  Future<DeletedTaskSnapshot> deleteTask(String taskId) async {
    final existing = byId(taskId);
    if (existing == null) {
      throw StateError('Task not found: $taskId');
    }
    final blockerIds = List<String>.unmodifiable(
      _blockersByTask[taskId] ?? const [],
    );
    final blockedIds = <String>[
      for (final entry in _blockersByTask.entries)
        if (entry.value.contains(taskId)) entry.key,
    ];
    await _db.transaction((txn) async {
      await txn.delete(
        'task_labels',
        where: 'task_id = ?',
        whereArgs: [taskId],
      );
      await txn.delete(
        'task_dependencies',
        where: 'blocker_task_id = ? OR blocked_task_id = ?',
        whereArgs: [taskId, taskId],
      );
      await txn.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
    });
    await _notifications?.cancelTaskReminder(taskId);
    await load();
    return DeletedTaskSnapshot(
      task: existing,
      blockerIds: blockerIds,
      blockedIds: blockedIds,
    );
  }

  Future<void> restoreDeleted(DeletedTaskSnapshot snapshot) async {
    final task = snapshot.task;
    await _db.transaction((txn) async {
      await txn.insert(
        'tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final labelId in task.labelIds) {
        await txn.insert(
          'task_labels',
          {'task_id': task.id, 'label_id': labelId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      for (final blockerId in snapshot.blockerIds) {
        await txn.insert(
          'task_dependencies',
          {'blocker_task_id': blockerId, 'blocked_task_id': task.id},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      for (final blockedId in snapshot.blockedIds) {
        await txn.insert(
          'task_dependencies',
          {'blocker_task_id': task.id, 'blocked_task_id': blockedId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
    await load();
  }

  Future<void> incrementCompletedPomodoros(String taskId) async {
    final existing = byId(taskId);
    if (existing == null) return;
    final next = existing.copyWith(
      completedPomodoros: existing.completedPomodoros + 1,
      updatedAt: DateTime.now(),
    );
    await _db.update(
      'tasks',
      next.toMap(),
      where: 'id = ?',
      whereArgs: [next.id],
    );
    await load();
  }
}
