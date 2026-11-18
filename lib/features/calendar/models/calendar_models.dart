import 'package:pomodoro_app/features/tasks/models/task_models.dart';

enum MobileCalendarMode {
  day('day', 'Day'),
  month('month', 'Month'),
  rhythm('rhythm', 'Rhythm');

  const MobileCalendarMode(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static MobileCalendarMode fromStorage(String? value) => switch (value) {
    'day' => MobileCalendarMode.day,
    'month' => MobileCalendarMode.month,
    _ => MobileCalendarMode.rhythm,
  };
}

class RoutinePeriod {
  const RoutinePeriod({
    required this.id,
    required this.name,
    required this.startMinutes,
    required this.endMinutes,
  });

  final String id;
  final String name;
  final int startMinutes;
  final int endMinutes;

  bool containsMinuteOfDay(int minuteOfDay) =>
      minuteOfDay >= startMinutes && minuteOfDay < endMinutes;

  String get timeRangeLabel =>
      '${formatMinutesOfDay(startMinutes)} – ${formatMinutesOfDay(endMinutes)}';

  RoutinePeriod copyWith({
    String? name,
    int? startMinutes,
    int? endMinutes,
  }) {
    return RoutinePeriod(
      id: id,
      name: name ?? this.name,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
  };

  factory RoutinePeriod.fromJson(Map<String, Object?> json) {
    return RoutinePeriod(
      id: json['id'] as String,
      name: json['name'] as String,
      startMinutes: json['startMinutes'] as int,
      endMinutes: json['endMinutes'] as int,
    );
  }

  static const List<RoutinePeriod> defaultPeriods = [
    RoutinePeriod(
      id: 'morning',
      name: 'Morning',
      startMinutes: 6 * 60,
      endMinutes: 12 * 60,
    ),
    RoutinePeriod(
      id: 'afternoon',
      name: 'Afternoon',
      startMinutes: 12 * 60,
      endMinutes: 17 * 60,
    ),
    RoutinePeriod(
      id: 'evening',
      name: 'Evening',
      startMinutes: 17 * 60,
      endMinutes: 22 * 60,
    ),
  ];

  static bool areValidNonOverlapping(List<RoutinePeriod> periods) {
    if (periods.isEmpty) return false;
    for (final p in periods) {
      if (p.name.trim().isEmpty) return false;
      if (p.startMinutes < 0 ||
          p.endMinutes > 1440 ||
          p.startMinutes >= p.endMinutes) {
        return false;
      }
    }
    final sorted = [...periods]
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].startMinutes < sorted[i - 1].endMinutes) {
        return false;
      }
    }
    return true;
  }
}

class RhythmDayGroups {
  const RhythmDayGroups({
    required this.allDay,
    required this.byPeriodId,
    required this.outsidePeriods,
  });

  final List<TaskItem> allDay;
  final Map<String, List<TaskItem>> byPeriodId;
  final List<TaskItem> outsidePeriods;
}

String formatMinutesOfDay(int minutes) {
  final clamped = minutes.clamp(0, 1440);
  final h = (clamped ~/ 60).toString().padLeft(2, '0');
  final m = (clamped % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
