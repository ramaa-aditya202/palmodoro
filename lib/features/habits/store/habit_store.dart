import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:pomodoro_app/features/habits/models/habit_models.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';

class HabitStore extends ChangeNotifier {
  HabitStore(this._db);

  final Database _db;
  final Uuid _uuid = const Uuid();

  List<HabitItem> _habits = const [];
  List<HabitCheckInItem> _checkIns = const [];

  List<HabitItem> get habits =>
      _habits.where((h) => !h.isArchived).toList(growable: false);

  HabitItem? byId(String id) {
    for (final h in _habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  int checkInCountForDay(String habitId, DateTime day) {
    final keyMs = dateOnly(day).millisecondsSinceEpoch;
    var count = 0;
    for (final ci in _checkIns) {
      if (ci.habitId == habitId && ci.dayEpochMs == keyMs) {
        count++;
      }
    }
    return count;
  }

  bool isCompletedOnDay(HabitItem habit, DateTime day) =>
      checkInCountForDay(habit.id, day) >= habit.targetPerDay;

  int currentStreak(HabitItem habit, DateTime today) {
    var streak = 0;
    var cursor = dateOnly(today);
    final start = dateOnly(habit.startDate);

    while (!cursor.isBefore(start)) {
      if (!habit.isScheduledOn(cursor)) {
        cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
        continue;
      }
      if (isCompletedOnDay(habit, cursor)) {
        streak++;
        cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> load() async {
    final habitRows = await _db.query('habits', orderBy: 'created_at ASC');
    final checkInRows = await _db.query(
      'habit_check_ins',
      orderBy: 'created_at ASC',
    );
    _habits = List.unmodifiable(habitRows.map(HabitItem.fromMap));
    _checkIns = List.unmodifiable(checkInRows.map(HabitCheckInItem.fromMap));
    notifyListeners();
  }

  Future<HabitItem> createHabit({
    required String title,
    String icon = 'check',
    String? projectId,
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
    int targetPerDay = 1,
    HabitDayPeriod dayPeriod = HabitDayPeriod.anytime,
    int? reminderMinutes,
    DateTime? startDate,
  }) async {
    final now = DateTime.now();
    final item = HabitItem(
      id: _uuid.v4(),
      title: title.trim(),
      icon: icon,
      projectId: projectId,
      weekdays: weekdays.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : weekdays,
      targetPerDay: targetPerDay.clamp(1, 20),
      dayPeriod: dayPeriod,
      reminderMinutes: reminderMinutes,
      startDate: dateOnly(startDate ?? now),
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert('habits', item.toMap());
    await load();
    return byId(item.id) ?? item;
  }

  Future<void> updateHabit(HabitItem updated) async {
    final item = updated.copyWith(updatedAt: DateTime.now());
    await _db.update(
      'habits',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    await load();
  }

  Future<void> deleteHabit(String habitId) async {
    await _db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
    await load();
  }

  Future<void> toggleOrIncrementCheckIn(String habitId, DateTime day) async {
    final habit = byId(habitId);
    if (habit == null) return;
    final keyMs = dateOnly(day).millisecondsSinceEpoch;
    final currentCount = checkInCountForDay(habitId, day);

    if (currentCount >= habit.targetPerDay) {
      await _db.delete(
        'habit_check_ins',
        where: 'habit_id = ? AND day_epoch_ms = ?',
        whereArgs: [habitId, keyMs],
      );
    } else {
      final checkIn = HabitCheckInItem(
        id: _uuid.v4(),
        habitId: habitId,
        dayEpochMs: keyMs,
        dayPeriod: habit.dayPeriod.storageValue,
        createdAt: DateTime.now(),
      );
      await _db.insert('habit_check_ins', checkIn.toMap());
    }
    await load();
  }
}
