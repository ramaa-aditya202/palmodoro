import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro_app/features/calendar/models/calendar_models.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';

class CalendarStore extends ChangeNotifier {
  CalendarStore([this._prefs]) {
    _load();
  }

  static const String _mobileModeKey = 'calendar.mobileMode';
  static const String _periodsKey = 'calendar.routinePeriods';

  final SharedPreferences? _prefs;
  MobileCalendarMode _mobileMode = MobileCalendarMode.rhythm;
  List<RoutinePeriod> _periods = RoutinePeriod.defaultPeriods;
  DateTime _selectedDate = dateOnly(DateTime.now());
  String? _projectFilterId;

  MobileCalendarMode get mobileMode => _mobileMode;
  List<RoutinePeriod> get periods => _periods;
  DateTime get selectedDate => _selectedDate;
  String? get projectFilterId => _projectFilterId;

  void _load() {
    final p = _prefs;
    if (p == null) return;
    _mobileMode = MobileCalendarMode.fromStorage(p.getString(_mobileModeKey));
    final rawPeriods = p.getString(_periodsKey);
    if (rawPeriods != null) {
      try {
        final decoded = (jsonDecode(rawPeriods) as List)
            .cast<Map<String, Object?>>()
            .map(RoutinePeriod.fromJson)
            .toList(growable: false);
        if (RoutinePeriod.areValidNonOverlapping(decoded)) {
          _periods = List.unmodifiable(
            [...decoded]
              ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes)),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> setMobileMode(MobileCalendarMode mode) async {
    if (_mobileMode == mode) return;
    _mobileMode = mode;
    await _prefs?.setString(_mobileModeKey, mode.storageValue);
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = dateOnly(date);
    notifyListeners();
  }

  void setProjectFilterId(String? projectId) {
    _projectFilterId = projectId;
    notifyListeners();
  }

  Future<bool> savePeriods(List<RoutinePeriod> nextPeriods) async {
    if (!RoutinePeriod.areValidNonOverlapping(nextPeriods)) {
      return false;
    }
    final sorted = [...nextPeriods]
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    _periods = List.unmodifiable(sorted);
    await _prefs?.setString(
      _periodsKey,
      jsonEncode(_periods.map((p) => p.toJson()).toList()),
    );
    notifyListeners();
    return true;
  }

  RhythmDayGroups groupTasksByRhythm(Iterable<TaskItem> dayTasks) {
    final allDay = <TaskItem>[];
    final byPeriodId = <String, List<TaskItem>>{
      for (final period in _periods) period.id: <TaskItem>[],
    };
    final outside = <TaskItem>[];

    for (final task in dayTasks) {
      if (task.scheduleKind != TaskScheduleKind.timed || task.dueAt == null) {
        allDay.add(task);
        continue;
      }
      final minuteOfDay = task.dueAt!.hour * 60 + task.dueAt!.minute;
      RoutinePeriod? matched;
      for (final period in _periods) {
        if (period.containsMinuteOfDay(minuteOfDay)) {
          matched = period;
          break;
        }
      }
      if (matched != null) {
        byPeriodId[matched.id]!.add(task);
      } else {
        outside.add(task);
      }
    }

    return RhythmDayGroups(
      allDay: allDay,
      byPeriodId: byPeriodId,
      outsidePeriods: outside,
    );
  }
}
