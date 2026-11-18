import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_date_format.dart';
import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/theme/theme_controller.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/focus/models/focus_models.dart';
import 'package:pomodoro_app/features/focus/store/focus_store.dart';
import 'package:pomodoro_app/features/projects/store/project_store.dart';
import 'package:pomodoro_app/features/settings/services/csv_task_service.dart';
import 'package:pomodoro_app/features/settings/widgets/bottom_nav_editor_sheet.dart';
import 'package:pomodoro_app/features/settings/widgets/custom_theme_editor_dialog.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final focusStore = context.watch<FocusStore>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        CompactShellHeader(
          title: 'Settings',
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              // Appearance section
              Material(
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance & Navigation',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Theme mode',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(LucideIcons.smartphone, size: 16),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(LucideIcons.sun, size: 16),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(LucideIcons.moon, size: 16),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {themeController.themeMode},
                        onSelectionChanged: (selection) {
                          themeController.setThemeMode(selection.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Color palette',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final entry in const [
                              ('classic', 'Classic'),
                              ('ocean', 'Ocean'),
                              ('forest', 'Forest'),
                              ('sepia', 'Sepia'),
                              ('graphite', 'Graphite'),
                              ('custom', 'Custom'),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(entry.$2),
                                  selected:
                                      themeController.paletteId == entry.$1,
                                  onSelected: (_) =>
                                      themeController.setPaletteId(entry.$1),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            key: const Key('open-custom-theme-editor-button'),
                            onPressed: () =>
                                CustomThemeEditorDialog.show(context),
                            icon: const Icon(LucideIcons.palette, size: 16),
                            label: const Text('Customize theme & photo'),
                          ),
                          OutlinedButton.icon(
                            key: const Key('open-bottom-nav-editor-button'),
                            onPressed: () => BottomNavEditorSheet.show(context),
                            icon: const Icon(LucideIcons.panelBottom, size: 16),
                            label: const Text('Customize bottom navigation'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<AppDateFormat>(
                        key: const Key('settings-date-format-dropdown'),
                        initialValue: themeController.dateFormat,
                        decoration: const InputDecoration(
                          labelText: 'Date format',
                        ),
                        items: [
                          for (final fmt in AppDateFormat.values)
                            DropdownMenuItem(
                              value: fmt,
                              child: Text(fmt.label),
                            ),
                        ],
                        onChanged: (fmt) {
                          if (fmt != null) {
                            themeController.setDateFormat(fmt);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Focus & Sounds section
              Material(
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Focus & Sounds',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Focus sound cues'),
                        value: focusStore.soundEnabled,
                        activeThumbColor: colors.accent,
                        onChanged: focusStore.setSoundEnabled,
                      ),
                      const Divider(height: 16),
                      DropdownButtonFormField<FocusSoundSet>(
                        initialValue: focusStore.soundSet,
                        decoration: const InputDecoration(
                          labelText: 'Sound set',
                        ),
                        items: [
                          for (final set in FocusSoundSet.values)
                            DropdownMenuItem(
                              value: set,
                              child: Text(set.displayName),
                            ),
                        ],
                        onChanged: (set) {
                          if (set != null) focusStore.setSoundSet(set);
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: focusStore.previewSound,
                          icon: const Icon(LucideIcons.volume2, size: 16),
                          label: const Text('Preview sound'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<FocusTimerVisualStyle>(
                        initialValue: focusStore.timerVisualStyle,
                        decoration: const InputDecoration(
                          labelText: 'Timer visual style',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: FocusTimerVisualStyle.circle,
                            child: Text('Circle'),
                          ),
                          DropdownMenuItem(
                            value: FocusTimerVisualStyle.bar,
                            child: Text('Bar'),
                          ),
                        ],
                        onChanged: (style) {
                          if (style != null) {
                            focusStore.setTimerVisualStyle(style);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<FocusViewMode>(
                        initialValue: focusStore.viewMode,
                        decoration: const InputDecoration(
                          labelText: 'Default Focus view mode',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: FocusViewMode.full,
                            child: Text('Full'),
                          ),
                          DropdownMenuItem(
                            value: FocusViewMode.minimal,
                            child: Text('Minimal'),
                          ),
                        ],
                        onChanged: (mode) {
                          if (mode != null) {
                            focusStore.setViewMode(mode);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Data & CSV Backup section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data & CSV Backup',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Export or import tasks in canonical Pomodoist CSV format.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('settings-export-csv-button'),
                          onPressed: () => _showExportCsvDialog(context),
                          icon: const Icon(LucideIcons.download, size: 16),
                          label: const Text('Export tasks to CSV'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('settings-import-csv-button'),
                          onPressed: () => _showImportCsvDialog(context),
                          icon: const Icon(LucideIcons.upload, size: 16),
                          label: const Text('Import tasks from CSV'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Onboarding & Tour section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Onboarding & Guide',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Re-open the welcome screen and interactive learning tour.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('settings-replay-onboarding-button'),
                      onPressed: () async {
                        await themeController.setTourCompleted(false);
                        await themeController.setOnboardingCompleted(false);
                      },
                      icon: const Icon(LucideIcons.sparkles, size: 16),
                      label: const Text('Replay onboarding & tour'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showExportCsvDialog(BuildContext context) async {
    final taskStore = context.read<TaskStore>();
    final projectStore = context.read<ProjectStore>();
    final csv = CsvTaskService.exportTasks(
      tasks: taskStore.tasks,
      projectStore: projectStore,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Export tasks to CSV'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: SelectableText(
                csv,
                key: const Key('csv-export-selectable-text'),
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              key: const Key('csv-export-copy-button'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV copied to clipboard')),
                  );
                }
              },
              icon: const Icon(LucideIcons.copy, size: 16),
              label: const Text('Copy CSV'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImportCsvDialog(BuildContext context) async {
    final taskStore = context.read<TaskStore>();
    final projectStore = context.read<ProjectStore>();
    final controller = TextEditingController();
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final colors = dialogContext.appColors;
            return AlertDialog(
              title: const Text('Import tasks from CSV'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const Key('csv-import-text-field'),
                      controller: controller,
                      minLines: 4,
                      maxLines: 8,
                      style: const TextStyle(
                        fontFamily: 'GeistMono',
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Pomodoist CSV content',
                        hintText: 'key,content,project,priority...',
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        key: const Key('csv-import-error-text'),
                        style: TextStyle(color: colors.error, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  key: const Key('csv-import-confirm-button'),
                  onPressed: () async {
                    try {
                      final count = await CsvTaskService.importCsv(
                        csvContent: controller.text,
                        taskStore: taskStore,
                        projectStore: projectStore,
                      );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Imported $count task(s) from CSV'),
                          ),
                        );
                      }
                    } on CsvImportFormatException catch (e) {
                      setDialogState(() => errorMessage = e.message);
                    }
                  },
                  icon: const Icon(LucideIcons.upload, size: 16),
                  label: const Text('Import'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }
}
