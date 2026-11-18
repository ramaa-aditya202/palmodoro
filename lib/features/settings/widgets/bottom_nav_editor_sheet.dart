import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/theme/theme_controller.dart';
import 'package:pomodoro_app/core/widgets/app_bottom_navigation.dart';

class BottomNavEditorSheet extends StatefulWidget {
  const BottomNavEditorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BottomNavEditorSheet(),
    );
  }

  @override
  State<BottomNavEditorSheet> createState() => _BottomNavEditorSheetState();
}

class _BottomNavEditorSheetState extends State<BottomNavEditorSheet> {
  late BottomNavStyle _style;
  late List<BottomNavDestination> _selected;

  @override
  void initState() {
    super.initState();
    final theme = context.read<ThemeController>();
    _style = theme.bottomNavStyle;
    _selected = [...theme.bottomNavDestinations];
  }

  void _toggleDestination(BottomNavDestination dest) {
    setState(() {
      if (_selected.contains(dest)) {
        _selected.remove(dest);
      } else if (_selected.length < 5) {
        _selected.add(dest);
      }
    });
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _selected.length) return;
    setState(() {
      final item = _selected.removeAt(index);
      _selected.insert(target, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = context.read<ThemeController>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bottom Navigation (0–5 tabs)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _style = BottomNavStyle.soft;
                    _selected = [...AppBottomNavigation.defaultDestinations];
                  });
                },
                child: const Text('Use defaults'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<BottomNavStyle>(
            segments: const [
              ButtonSegment(
                value: BottomNavStyle.soft,
                label: Text('Soft accent'),
              ),
              ButtonSegment(
                value: BottomNavStyle.labels,
                label: Text('With labels'),
              ),
            ],
            selected: {_style},
            onSelectionChanged: (s) => setState(() => _style = s.first),
          ),
          const SizedBox(height: 12),
          if (_selected.isNotEmpty) ...[
            Text(
              'Pinned order (${_selected.length}/5):',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.secondaryText,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _selected.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceTint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (i > 0)
                          InkWell(
                            onTap: () => _move(i, -1),
                            child: const Icon(
                              LucideIcons.chevronLeft,
                              size: 14,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(_selected[i].label),
                        ),
                        if (i < _selected.length - 1)
                          InkWell(
                            onTap: () => _move(i, 1),
                            child: const Icon(
                              LucideIcons.chevronRight,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final dest in BottomNavDestination.values)
                FilterChip(
                  avatar: Icon(dest.icon, size: 14),
                  label: Text(dest.label),
                  selected: _selected.contains(dest),
                  onSelected: (_) => _toggleDestination(dest),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _selected.clear()),
                child: const Text('Remove all'),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('bottom-nav-save-button'),
                onPressed: () async {
                  await theme.saveBottomNav(
                    style: _style,
                    destinations: _selected,
                  );
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
