import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationService {
  Future<void> init();
  Future<void> scheduleFocusEnd({
    required DateTime endAt,
    required String title,
    required String body,
  });
  Future<void> cancelFocusEnd();
  Future<void> scheduleTaskReminder({
    required String taskId,
    required DateTime reminderAt,
    required String title,
  });
  Future<void> cancelTaskReminder(String taskId);
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService();

  static const int _focusNotificationId = 1001;
  static const String _focusChannelId = 'focus_timer_channel';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {}
    _initialized = true;
  }

  @override
  Future<void> scheduleFocusEnd({
    required DateTime endAt,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    if (!endAt.isAfter(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: _focusNotificationId,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(endAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _focusChannelId,
            'Focus Timer',
            channelDescription: 'Notifications when a Pomodoro interval ends',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Ignore on unsupported desktop test hosts.
    }
  }

  @override
  Future<void> cancelFocusEnd() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _focusNotificationId);
    } catch (_) {}
  }

  int _reminderIdFor(String taskId) => 2000 + (taskId.hashCode.abs() % 100000);

  @override
  Future<void> scheduleTaskReminder({
    required String taskId,
    required DateTime reminderAt,
    required String title,
  }) async {
    if (!_initialized) return;
    if (!reminderAt.isAfter(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: _reminderIdFor(taskId),
        title: 'Task reminder',
        body: title,
        scheduledDate: tz.TZDateTime.from(reminderAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminder_channel',
            'Task Reminders',
            channelDescription: 'Scheduled reminders for tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _reminderIdFor(taskId));
    } catch (_) {}
  }
}

class FakeNotificationService implements NotificationService {
  DateTime? scheduledEndAt;
  String? lastTitle;
  String? lastBody;
  final Map<String, DateTime> taskReminders = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleFocusEnd({
    required DateTime endAt,
    required String title,
    required String body,
  }) async {
    scheduledEndAt = endAt;
    lastTitle = title;
    lastBody = body;
  }

  @override
  Future<void> cancelFocusEnd() async {
    scheduledEndAt = null;
  }

  @override
  Future<void> scheduleTaskReminder({
    required String taskId,
    required DateTime reminderAt,
    required String title,
  }) async {
    taskReminders[taskId] = reminderAt;
  }

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    taskReminders.remove(taskId);
  }
}
