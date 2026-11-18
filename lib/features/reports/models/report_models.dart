class DayFocusStat {
  const DayFocusStat({
    required this.day,
    required this.focusSeconds,
    required this.completedIntervals,
    required this.completedTasks,
  });

  final DateTime day;
  final int focusSeconds;
  final int completedIntervals;
  final int completedTasks;

  int get focusMinutes => (focusSeconds / 60).round();
}

class ProjectFocusStat {
  const ProjectFocusStat({
    required this.projectId,
    required this.projectName,
    required this.colorHex,
    required this.focusSeconds,
    required this.completedIntervals,
  });

  final String? projectId;
  final String projectName;
  final String colorHex;
  final int focusSeconds;
  final int completedIntervals;
}

class TaskFocusStat {
  const TaskFocusStat({
    required this.taskId,
    required this.taskTitle,
    required this.focusSeconds,
    required this.completedIntervals,
  });

  final String taskId;
  final String taskTitle;
  final int focusSeconds;
  final int completedIntervals;
}

class ProductivitySummary {
  const ProductivitySummary({
    required this.todayFocusSeconds,
    required this.weekFocusSeconds,
    required this.weekCompletedIntervals,
    required this.weekCompletedTasks,
    required this.last7Days,
    required this.byProject,
    required this.byTask,
  });

  final int todayFocusSeconds;
  final int weekFocusSeconds;
  final int weekCompletedIntervals;
  final int weekCompletedTasks;
  final List<DayFocusStat> last7Days;
  final List<ProjectFocusStat> byProject;
  final List<TaskFocusStat> byTask;
}

String formatFocusDurationSummary(int totalSeconds) {
  final totalMinutes = (totalSeconds / 60).round();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  return '${minutes}m';
}
