import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:pomodoro_app/features/reports/models/report_models.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';

class ReportsStore extends ChangeNotifier {
  ReportsStore(this._db);

  final Database _db;
  ProductivitySummary? _latest;

  ProductivitySummary? get latest => _latest;

  Future<ProductivitySummary> computeSummary([DateTime? now]) async {
    final clock = now ?? DateTime.now();
    final today = dateOnly(clock);
    final startDay = DateTime(today.year, today.month, today.day - 6);
    final endExclusive = DateTime(today.year, today.month, today.day + 1);

    final workIntervalRows = await _db.rawQuery(
      '''
      SELECT
        fi.duration_seconds AS duration_seconds,
        fi.ended_at AS ended_at,
        fr.task_id AS task_id,
        t.title AS task_title,
        t.project_id AS project_id,
        p.name AS project_name,
        p.color_hex AS project_color
      FROM focus_intervals fi
      INNER JOIN focus_runs fr ON fr.id = fi.run_id
      LEFT JOIN tasks t ON t.id = fr.task_id
      LEFT JOIN projects p ON p.id = t.project_id
      WHERE fi.type = 'work'
        AND fi.status = 'completed'
        AND fi.ended_at IS NOT NULL
        AND fi.ended_at >= ?
        AND fi.ended_at < ?
      ''',
      [startDay.millisecondsSinceEpoch, endExclusive.millisecondsSinceEpoch],
    );

    final completedTaskRows = await _db.query(
      'tasks',
      columns: ['id', 'completed_at'],
      where: 'is_completed = 1 AND completed_at IS NOT NULL AND completed_at >= ? AND completed_at < ?',
      whereArgs: [
        startDay.millisecondsSinceEpoch,
        endExclusive.millisecondsSinceEpoch,
      ],
    );

    final focusSecondsByDay = <DateTime, int>{
      for (var i = 0; i < 7; i++)
        DateTime(startDay.year, startDay.month, startDay.day + i): 0,
    };
    final intervalsByDay = <DateTime, int>{
      for (var i = 0; i < 7; i++)
        DateTime(startDay.year, startDay.month, startDay.day + i): 0,
    };
    final tasksByDay = <DateTime, int>{
      for (var i = 0; i < 7; i++)
        DateTime(startDay.year, startDay.month, startDay.day + i): 0,
    };

    final projectMap = <String?, ({String name, String color, int sec, int count})>{};
    final taskMap = <String, ({String title, int sec, int count})>{};

    var weekFocusSeconds = 0;
    var weekCompletedIntervals = 0;

    for (final row in workIntervalRows) {
      final duration = row['duration_seconds'] as int? ?? 0;
      final endedMs = row['ended_at'] as int;
      final endedDay = dateOnly(DateTime.fromMillisecondsSinceEpoch(endedMs));
      if (focusSecondsByDay.containsKey(endedDay)) {
        focusSecondsByDay[endedDay] = focusSecondsByDay[endedDay]! + duration;
        intervalsByDay[endedDay] = intervalsByDay[endedDay]! + 1;
      }
      weekFocusSeconds += duration;
      weekCompletedIntervals++;

      final projectId = row['project_id'] as String?;
      final projectName = (row['project_name'] as String?) ?? 'No project';
      final projectColor = (row['project_color'] as String?) ?? '#737373';
      final prevProj = projectMap[projectId];
      projectMap[projectId] = (
        name: projectName,
        color: projectColor,
        sec: (prevProj?.sec ?? 0) + duration,
        count: (prevProj?.count ?? 0) + 1,
      );

      final taskId = row['task_id'] as String?;
      if (taskId != null) {
        final taskTitle = (row['task_title'] as String?) ?? 'Deleted task';
        final prevTask = taskMap[taskId];
        taskMap[taskId] = (
          title: taskTitle,
          sec: (prevTask?.sec ?? 0) + duration,
          count: (prevTask?.count ?? 0) + 1,
        );
      }
    }

    for (final row in completedTaskRows) {
      final completedMs = row['completed_at'] as int;
      final day = dateOnly(DateTime.fromMillisecondsSinceEpoch(completedMs));
      if (tasksByDay.containsKey(day)) {
        tasksByDay[day] = tasksByDay[day]! + 1;
      }
    }

    final last7Days = <DayFocusStat>[
      for (var i = 0; i < 7; i++)
        BuilderDayStat.build(
          DateTime(startDay.year, startDay.month, startDay.day + i),
          focusSecondsByDay,
          intervalsByDay,
          tasksByDay,
        ),
    ];

    final byProject = [
      for (final entry in projectMap.entries)
        ProjectFocusStat(
          projectId: entry.key,
          projectName: entry.value.name,
          colorHex: entry.value.color,
          focusSeconds: entry.value.sec,
          completedIntervals: entry.value.count,
        ),
    ]..sort((a, b) => b.focusSeconds.compareTo(a.focusSeconds));

    final byTask = [
      for (final entry in taskMap.entries)
        TaskFocusStat(
          taskId: entry.key,
          taskTitle: entry.value.title,
          focusSeconds: entry.value.sec,
          completedIntervals: entry.value.count,
        ),
    ]..sort((a, b) => b.focusSeconds.compareTo(a.focusSeconds));

    final summary = ProductivitySummary(
      todayFocusSeconds: focusSecondsByDay[today] ?? 0,
      weekFocusSeconds: weekFocusSeconds,
      weekCompletedIntervals: weekCompletedIntervals,
      weekCompletedTasks: completedTaskRows.length,
      last7Days: List.unmodifiable(last7Days),
      byProject: List.unmodifiable(byProject),
      byTask: List.unmodifiable(byTask),
    );
    _latest = summary;
    notifyListeners();
    return summary;
  }
}

abstract final class BuilderDayStat {
  static DayFocusStat build(
    DateTime day,
    Map<DateTime, int> sec,
    Map<DateTime, int> intervals,
    Map<DateTime, int> tasks,
  ) {
    return DayFocusStat(
      day: day,
      focusSeconds: sec[day] ?? 0,
      completedIntervals: intervals[day] ?? 0,
      completedTasks: tasks[day] ?? 0,
    );
  }
}
