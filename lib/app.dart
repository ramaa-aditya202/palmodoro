import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' as shad;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/theme/theme_controller.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/features/calendar/screens/calendar_screen.dart';
import 'package:pomodoro_app/features/calendar/store/calendar_store.dart';
import 'package:pomodoro_app/features/focus/screens/focus_screen.dart';
import 'package:pomodoro_app/features/focus/store/focus_store.dart';
import 'package:pomodoro_app/features/focus/widgets/mini_focus_player.dart';
import 'package:pomodoro_app/features/habits/screens/habits_screen.dart';
import 'package:pomodoro_app/features/habits/store/habit_store.dart';
import 'package:pomodoro_app/features/kanban/screens/kanban_screen.dart';
import 'package:pomodoro_app/features/matrix/screens/priority_matrix_screen.dart';
import 'package:pomodoro_app/features/onboarding/widgets/onboarding_overlay.dart';
import 'package:pomodoro_app/features/projects/screens/projects_screen.dart';
import 'package:pomodoro_app/features/projects/store/project_store.dart';
import 'package:pomodoro_app/features/reports/screens/reports_screen.dart';
import 'package:pomodoro_app/features/reports/store/reports_store.dart';
import 'package:pomodoro_app/features/settings/screens/settings_screen.dart';
import 'package:pomodoro_app/features/tasks/screens/browse_screen.dart';
import 'package:pomodoro_app/features/tasks/screens/search_screen.dart';
import 'package:pomodoro_app/features/tasks/screens/task_detail_screen.dart';
import 'package:pomodoro_app/features/tasks/screens/today_screen.dart';
import 'package:pomodoro_app/features/tasks/screens/upcoming_screen.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_editor_sheet.dart';
import 'package:pomodoro_app/features/timeline/screens/timeline_screen.dart';

class PomodoroApp extends StatefulWidget {
  const PomodoroApp({
    required this.themeController,
    required this.projectStore,
    required this.taskStore,
    required this.focusStore,
    this.calendarStore,
    this.habitStore,
    this.reportsStore,
    super.key,
  });

  final ThemeController themeController;
  final ProjectStore projectStore;
  final TaskStore taskStore;
  final FocusStore focusStore;
  final CalendarStore? calendarStore;
  final HabitStore? habitStore;
  final ReportsStore? reportsStore;

  @override
  State<PomodoroApp> createState() => _PomodoroAppState();
}

class _PomodoroAppState extends State<PomodoroApp> {
  late final CalendarStore _calendarStore =
      widget.calendarStore ?? CalendarStore();

  late final GoRouter _router = GoRouter(
    initialLocation: '/today',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.toString();
          final onFocusRoute = location.startsWith('/focus');
          return OnboardingGate(
            child: AdaptiveShell(
              currentLocation: location,
              miniPlayer: onFocusRoute ? null : const MiniFocusPlayer(),
              onAddTask: () => TaskEditorSheet.show(context),
              child: child,
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/today',
            builder: (context, state) => const TodayScreen(),
          ),
          GoRoute(
            path: '/upcoming',
            builder: (context, state) => const UpcomingScreen(),
          ),
          GoRoute(
            path: '/focus',
            builder: (context, state) => const FocusScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectsScreen(),
          ),
          GoRoute(
            path: '/project/:id',
            builder: (context, state) => ProjectDetailScreen(
              projectId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/label/:id',
            builder: (context, state) => LabelDetailScreen(
              labelId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/timeline',
            builder: (context, state) => const TimelineScreen(),
          ),
          GoRoute(
            path: '/kanban',
            builder: (context, state) => const KanbanScreen(),
          ),
          GoRoute(
            path: '/priority-matrix',
            builder: (context, state) => const PriorityMatrixScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/browse',
            builder: (context, state) => const BrowseScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitsScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/task/:id',
        builder: (context, state) => TaskDetailScreen(
          taskId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.themeController),
        ChangeNotifierProvider.value(value: widget.projectStore),
        ChangeNotifierProvider.value(value: widget.taskStore),
        ChangeNotifierProvider.value(value: widget.focusStore),
        ChangeNotifierProvider.value(value: _calendarStore),
        if (widget.habitStore != null)
          ChangeNotifierProvider.value(value: widget.habitStore!),
        if (widget.reportsStore != null)
          ChangeNotifierProvider.value(value: widget.reportsStore!),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) {
          final lightMaterial = AppTheme.light(palette: theme.lightPalette);
          final darkMaterial = AppTheme.dark(palette: theme.darkPalette);

          return shad.ShadApp.custom(
            themeMode: theme.themeMode,
            theme: AppTheme.shadFromMaterial(lightMaterial),
            darkTheme: AppTheme.shadFromMaterial(darkMaterial),
            appBuilder: (context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Pomodoro',
              themeMode: theme.themeMode,
              theme: lightMaterial,
              darkTheme: darkMaterial,
              routerConfig: _router,
              builder: (context, child) =>
                  shad.ShadAppBuilder(child: child ?? const SizedBox.shrink()),
            ),
          );
        },
      ),
    );
  }
}
