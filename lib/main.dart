import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro_app/app.dart';
import 'package:pomodoro_app/core/audio/focus_sound_service.dart';
import 'package:pomodoro_app/core/db/app_database.dart';
import 'package:pomodoro_app/core/notifications/notification_service.dart';
import 'package:pomodoro_app/core/theme/theme_controller.dart';
import 'package:pomodoro_app/features/calendar/store/calendar_store.dart';
import 'package:pomodoro_app/features/focus/store/focus_store.dart';
import 'package:pomodoro_app/features/habits/store/habit_store.dart';
import 'package:pomodoro_app/features/projects/store/project_store.dart';
import 'package:pomodoro_app/features/reports/store/reports_store.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final db = await AppDatabase.open();
  final notifications = LocalNotificationService();
  await notifications.init();
  final sounds = AudioPlayersFocusSoundService();

  final themeController = ThemeController(
    prefs,
    defaultOnboardingCompleted: false,
  );
  final taskStore = TaskStore(db, notifications: notifications);
  final projectStore = ProjectStore(db, onChanged: taskStore.load);
  final focusStore = FocusStore(
    db: db,
    taskStore: taskStore,
    notifications: notifications,
    sounds: sounds,
    prefs: prefs,
  );
  final calendarStore = CalendarStore(prefs);
  final habitStore = HabitStore(db);
  final reportsStore = ReportsStore(db);

  await projectStore.load();
  await taskStore.load();
  await focusStore.load();
  await habitStore.load();
  await reportsStore.computeSummary();

  runApp(
    PomodoroApp(
      themeController: themeController,
      projectStore: projectStore,
      taskStore: taskStore,
      focusStore: focusStore,
      calendarStore: calendarStore,
      habitStore: habitStore,
      reportsStore: reportsStore,
    ),
  );
}
