import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/theme/theme_controller.dart';
import 'package:pomodoro_app/core/widgets/app_bottom_navigation.dart';
import 'package:pomodoro_app/core/widgets/draggable_add_task_fab.dart';
import 'package:pomodoro_app/features/projects/store/project_store.dart';
import 'package:pomodoro_app/features/settings/widgets/bottom_nav_editor_sheet.dart';

class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({
    required this.child,
    required this.currentLocation,
    required this.onAddTask,
    this.miniPlayer,
    super.key,
  });

  final Widget child;
  final String currentLocation;
  final VoidCallback onAddTask;
  final Widget? miniPlayer;

  static ScaffoldState? maybeScaffoldOf(BuildContext context) =>
      context.findAncestorStateOfType<_AdaptiveShellState>()?._scaffoldKey.currentState;

  static void openDrawerOf(BuildContext context) {
    maybeScaffoldOf(context)?.openDrawer();
  }

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = context.watch<ThemeController>();
    final destinations = theme.bottomNavDestinations;
    final navStyle = theme.bottomNavStyle;
    final photoPath = theme.backgroundPhotoPath;
    final hasPhoto =
        photoPath != null &&
        photoPath.isNotEmpty &&
        File(photoPath).existsSync();

    final hasMiniPlayer = widget.miniPlayer != null;
    final hasBottomNav = destinations.isNotEmpty;
    final bottomClearance =
        16.0 + (hasBottomNav ? 72.0 : 0.0) + (hasMiniPlayer ? 76.0 : 0.0);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colors.canvas,
      drawer: _ShellDrawer(currentLocation: widget.currentLocation),
      body: SafeArea(
        child: Stack(
          children: [
            if (hasPhoto)
              Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: theme.backgroundBlur,
                        sigmaY: theme.backgroundBlur,
                      ),
                      child: Image.file(
                        File(photoPath),
                        fit: BoxFit.cover,
                      ),
                    ),
                    ColoredBox(
                      color: colors.canvas.withValues(
                        alpha: theme.backgroundDimming,
                      ),
                    ),
                  ],
                ),
              ),
            Column(
              children: [
                Expanded(child: widget.child),
                if (widget.miniPlayer != null) widget.miniPlayer!,
                if (hasBottomNav)
                  AppBottomNavigation(
                    destinations: destinations,
                    style: navStyle,
                    currentLocation: widget.currentLocation,
                    onSelect: (dest) => context.go(dest.path),
                    onLongPressEdit: () => BottomNavEditorSheet.show(context),
                  ),
              ],
            ),
            Positioned.fill(
              child: DraggableAddTaskFab(
                topClearance: 64,
                bottomClearance: bottomClearance,
                onPressed: widget.onAddTask,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellDrawer extends StatelessWidget {
  const _ShellDrawer({required this.currentLocation});

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final projectStore = context.watch<ProjectStore>();

    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.accentFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.timer,
                      size: 16,
                      color: colors.onAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pomodoro',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const _SectionLabel(label: 'DAILY'),
            for (final dest in const [
              BottomNavDestination.today,
              BottomNavDestination.upcoming,
              BottomNavDestination.focus,
              BottomNavDestination.habits,
              BottomNavDestination.search,
              BottomNavDestination.browse,
            ])
              _DrawerTile(
                icon: dest.icon,
                label: dest.label,
                selected: dest.matches(currentLocation),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(dest.path);
                },
              ),
            const SizedBox(height: 12),
            const _SectionLabel(label: 'VIEWS'),
            for (final dest in const [
              BottomNavDestination.calendar,
              BottomNavDestination.timeline,
              BottomNavDestination.kanban,
              BottomNavDestination.priorityMatrix,
              BottomNavDestination.projects,
              BottomNavDestination.reports,
            ])
              _DrawerTile(
                icon: dest.icon,
                label: dest.label,
                selected: dest.matches(currentLocation),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(dest.path);
                },
              ),
            if (projectStore.activeProjects.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SectionLabel(label: 'PROJECTS'),
              for (final project in projectStore.activeProjects)
                _DrawerTile(
                  icon: project.icon.iconData,
                  iconColor: project.color,
                  label: project.name,
                  selected: currentLocation == '/project/${project.id}',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/project/${project.id}');
                  },
                ),
            ],
            const Divider(height: 24),
            _DrawerTile(
              icon: BottomNavDestination.settings.icon,
              label: BottomNavDestination.settings.label,
              selected: BottomNavDestination.settings.matches(currentLocation),
              onTap: () {
                Navigator.of(context).pop();
                context.go(BottomNavDestination.settings.path);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.secondaryText,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? colors.accentTint : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color:
                      selected
                          ? colors.accent
                          : (iconColor ?? colors.secondaryText),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected ? colors.accent : colors.primaryText,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
