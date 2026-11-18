import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/features/tasks/models/task_models.dart';

enum HabitDayPeriod {
  anytime('anytime', 'Anytime'),
  morning('morning', 'Morning'),
  afternoon('afternoon', 'Afternoon'),
  evening('evening', 'Evening'),
  night('night', 'Night');

  const HabitDayPeriod(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static HabitDayPeriod fromStorage(String? value) {
    return HabitDayPeriod.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => HabitDayPeriod.anytime,
    );
  }
}

enum HabitIconChoice {
  check('check', LucideIcons.circleCheck),
  flame('flame', LucideIcons.flame),
  book('book', LucideIcons.bookOpen),
  dumbbell('dumbbell', LucideIcons.dumbbell),
  droplet('droplet', LucideIcons.droplet),
  moon('moon', LucideIcons.moon),
  heart('heart', LucideIcons.heart),
  sparkles('sparkles', LucideIcons.sparkles);

  const HabitIconChoice(this.storageValue, this.iconData);
  final String storageValue;
  final IconData iconData;

  static HabitIconChoice fromStorage(String? value) {
    return HabitIconChoice.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => HabitIconChoice.check,
    );
  }
}

class HabitItem {
  const HabitItem({
    required this.id,
    required this.title,
    this.icon = 'check',
    this.projectId,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.targetPerDay = 1,
    this.dayPeriod = HabitDayPeriod.anytime,
    this.reminderMinutes,
    required this.startDate,
    this.endDate,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String icon;
  final String? projectId;
  final List<int> weekdays; // 1 = Monday .. 7 = Sunday
  final int targetPerDay;
  final HabitDayPeriod dayPeriod;
  final int? reminderMinutes;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  IconData get iconData => HabitIconChoice.fromStorage(icon).iconData;

  bool isScheduledOn(DateTime day) {
    final normalized = dateOnly(day);
    if (normalized.isBefore(dateOnly(startDate))) return false;
    if (endDate != null && normalized.isAfter(dateOnly(endDate!))) {
      return false;
    }
    return weekdays.contains(normalized.weekday);
  }

  HabitItem copyWith({
    String? title,
    String? icon,
    String? projectId,
    List<int>? weekdays,
    int? targetPerDay,
    HabitDayPeriod? dayPeriod,
    int? reminderMinutes,
    bool clearReminder = false,
    DateTime? startDate,
    DateTime? endDate,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return HabitItem(
      id: id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      projectId: projectId ?? this.projectId,
      weekdays: weekdays ?? this.weekdays,
      targetPerDay: targetPerDay ?? this.targetPerDay,
      dayPeriod: dayPeriod ?? this.dayPeriod,
      reminderMinutes:
          clearReminder ? null : (reminderMinutes ?? this.reminderMinutes),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'icon': icon,
    'project_id': projectId,
    'weekdays_csv': weekdays.join(','),
    'target_per_day': targetPerDay.clamp(1, 20),
    'day_period': dayPeriod.storageValue,
    'reminder_minutes': reminderMinutes,
    'start_date': dateOnly(startDate).millisecondsSinceEpoch,
    'end_date':
        endDate == null ? null : dateOnly(endDate!).millisecondsSinceEpoch,
    'is_archived': isArchived ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory HabitItem.fromMap(Map<String, Object?> map) {
    final csv = (map['weekdays_csv'] as String? ?? '1,2,3,4,5,6,7')
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toList();
    return HabitItem(
      id: map['id'] as String,
      title: map['title'] as String,
      icon: map['icon'] as String? ?? 'check',
      projectId: map['project_id'] as String?,
      weekdays: csv.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : csv,
      targetPerDay: (map['target_per_day'] as int? ?? 1).clamp(1, 20),
      dayPeriod: HabitDayPeriod.fromStorage(map['day_period'] as String?),
      reminderMinutes: map['reminder_minutes'] as int?,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      endDate: map['end_date'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int),
      isArchived: (map['is_archived'] as int? ?? 0) != 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}

class HabitCheckInItem {
  const HabitCheckInItem({
    required this.id,
    required this.habitId,
    required this.dayEpochMs,
    this.dayPeriod,
    required this.createdAt,
  });

  final String id;
  final String habitId;
  final int dayEpochMs;
  final String? dayPeriod;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'habit_id': habitId,
    'day_epoch_ms': dayEpochMs,
    'day_period': dayPeriod,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory HabitCheckInItem.fromMap(Map<String, Object?> map) {
    return HabitCheckInItem(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      dayEpochMs: map['day_epoch_ms'] as int,
      dayPeriod: map['day_period'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
