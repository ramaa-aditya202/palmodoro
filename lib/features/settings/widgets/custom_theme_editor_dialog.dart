import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/theme/theme_controller.dart';

class CustomThemeEditorDialog extends StatefulWidget {
  const CustomThemeEditorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const CustomThemeEditorDialog(),
    );
  }

  @override
  State<CustomThemeEditorDialog> createState() =>
      _CustomThemeEditorDialogState();
}

class _CustomThemeEditorDialogState extends State<CustomThemeEditorDialog> {
  bool _editDark = false;
  late Map<String, TextEditingController> _lightControllers;
  late Map<String, TextEditingController> _darkControllers;
  late TextEditingController _photoPathController;
  late double _dimming;
  late double _blur;
  String? _errorText;

  static const List<(String, String)> _editableRoles = [
    ('canvas', 'Background canvas'),
    ('surface', 'Card surface'),
    ('primaryText', 'Primary text'),
    ('secondaryText', 'Secondary text'),
    ('border', 'Border'),
    ('accent', 'Accent'),
    ('accentFill', 'Primary button fill'),
    ('accentTint', 'Soft accent tint'),
  ];

  @override
  void initState() {
    super.initState();
    final controller = context.read<ThemeController>();
    final lightMap = controller.customLight.toJson();
    final darkMap = controller.customDark.toJson();
    _lightControllers = {
      for (final entry in lightMap.entries)
        entry.key: TextEditingController(text: entry.value),
    };
    _darkControllers = {
      for (final entry in darkMap.entries)
        entry.key: TextEditingController(text: entry.value),
    };
    _photoPathController = TextEditingController(
      text: controller.backgroundPhotoPath ?? '',
    );
    _dimming = controller.backgroundDimming;
    _blur = controller.backgroundBlur;
  }

  @override
  void dispose() {
    for (final c in _lightControllers.values) {
      c.dispose();
    }
    for (final c in _darkControllers.values) {
      c.dispose();
    }
    _photoPathController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final controller = context.read<ThemeController>();
    final lightHex = {
      for (final entry in _lightControllers.entries)
        entry.key: entry.value.text.trim(),
    };
    final darkHex = {
      for (final entry in _darkControllers.entries)
        entry.key: entry.value.text.trim(),
    };
    final ok = await controller.saveCustomPalettes(
      lightHex: lightHex,
      darkHex: darkHex,
    );
    if (!ok) {
      setState(() {
        _errorText = 'Invalid HEX color (use 6-digit #RRGGBB).';
      });
      return;
    }
    await controller.setPhotoBackground(
      path: _photoPathController.text.trim(),
      clearPath: _photoPathController.text.trim().isEmpty,
      dimming: _dimming,
      blur: _blur,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeMap = _editDark ? _darkControllers : _lightControllers;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Custom Theme & Background',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await context
                          .read<ThemeController>()
                          .resetCustomToClassic();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Reset to Classic'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Light palette')),
                  ButtonSegment(value: true, label: Text('Dark palette')),
                ],
                selected: {_editDark},
                onSelectionChanged: (s) => setState(() => _editDark = s.first),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: TextStyle(color: colors.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    for (final role in _editableRoles)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TextField(
                          controller: activeMap[role.$1],
                          decoration: InputDecoration(
                            labelText: role.$2,
                            hintText: '#RRGGBB',
                          ),
                        ),
                      ),
                    const Divider(height: 24),
                    Text(
                      'Photo Background (Optional)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('custom-photo-path-input'),
                      controller: _photoPathController,
                      decoration: const InputDecoration(
                        labelText: 'Local image file path',
                        hintText: '/storage/emulated/0/Download/wallpaper.jpg',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Dimming: ${(_dimming * 100).round()}%'),
                    Slider(
                      value: _dimming,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) => setState(() => _dimming = v),
                    ),
                    Text('Blur: ${_blur.round()} px'),
                    Slider(
                      value: _blur,
                      min: 0.0,
                      max: 20.0,
                      onChanged: (v) => setState(() => _blur = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('custom-theme-save-button'),
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
