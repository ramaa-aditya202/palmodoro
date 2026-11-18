import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/theme/theme_controller.dart';

class OnboardingGate extends StatelessWidget {
  const OnboardingGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    if (!themeController.onboardingCompleted) {
      return const _OnboardingScreen(key: Key('onboarding-gate'));
    }

    return Column(
      children: [
        if (!themeController.tourCompleted)
          const LearningTourBanner(key: Key('learning-tour-banner')),
        Expanded(child: child),
      ],
    );
  }
}

class _OnboardingScreen extends StatelessWidget {
  const _OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.accentTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.timer,
                          color: colors.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Pomodoro',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '100% offline focus timer, tasks, habits, and planning views.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _OnboardingFeatureCard(
                    icon: LucideIcons.flame,
                    title: 'Focus Timer & Strict Mode',
                    subtitle:
                        'Customizable work/break intervals, 60-second strict exit hold, sound cues, and floating mini player.',
                  ),
                  const SizedBox(height: 10),
                  const _OnboardingFeatureCard(
                    icon: LucideIcons.calendarRange,
                    title: 'Tasks & Planning Views',
                    subtitle:
                        'Today, Upcoming, Calendar (Day/Month/Rhythm), Timeline, Kanban, Priority Matrix, and Project Map.',
                  ),
                  const SizedBox(height: 10),
                  const _OnboardingFeatureCard(
                    icon: LucideIcons.chartColumn,
                    title: 'Habits & Productivity Reports',
                    subtitle:
                        'Daily habit check-ins with streak tracking and 7-day focus breakdowns stored locally on your device.',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose your look',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                          onSelectionChanged: (s) =>
                              themeController.setThemeMode(s.first),
                        ),
                        const SizedBox(height: 12),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('onboarding-complete-button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accentFill,
                    foregroundColor: colors.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await themeController.setTourCompleted(false);
                    await themeController.setOnboardingCompleted(true);
                  },
                  icon: const Icon(LucideIcons.arrowRight, size: 18),
                  label: const Text('Get started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingFeatureCard extends StatelessWidget {
  const _OnboardingFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LearningTourBanner extends StatefulWidget {
  const LearningTourBanner({super.key});

  @override
  State<LearningTourBanner> createState() => _LearningTourBannerState();
}

class _LearningTourBannerState extends State<LearningTourBanner> {
  static const List<(String, String)> _steps = [
    (
      '1/4 · Quick Add Task',
      'Tap the floating + button or drag it to any screen corner to create tasks.',
    ),
    (
      '2/4 · Focus Timer',
      'Tap the play button on any task or open Focus for presets and 60s strict mode.',
    ),
    (
      '3/4 · Planning Views',
      'Open the navigation drawer for Calendar, Timeline, Kanban, Matrix, and Project Map.',
    ),
    (
      '4/4 · Habits & Reports',
      'Track daily habits with streaks and inspect your 7-day focus stats in Reports.',
    ),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final themeController = context.read<ThemeController>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final current = _steps[_index];

    return Material(
      color: colors.accentTint,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.sparkles, size: 18, color: colors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      current.$1,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.accent,
                      ),
                    ),
                    Text(
                      current.$2,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('learning-tour-next-button'),
                onPressed: () {
                  if (_index + 1 < _steps.length) {
                    setState(() => _index++);
                  } else {
                    themeController.setTourCompleted(true);
                  }
                },
                child: Text(_index + 1 < _steps.length ? 'Next' : 'Finish'),
              ),
              IconButton(
                key: const Key('learning-tour-dismiss-button'),
                tooltip: 'Dismiss tour',
                icon: const Icon(LucideIcons.x, size: 16),
                onPressed: () => themeController.setTourCompleted(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
