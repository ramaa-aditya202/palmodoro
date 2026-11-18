import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/features/focus/models/focus_models.dart';

class FocusPresetDialog extends StatefulWidget {
  const FocusPresetDialog({this.existing, super.key});

  final FocusPresetItem? existing;

  @override
  State<FocusPresetDialog> createState() => _FocusPresetDialogState();
}

class _FocusPresetDialogState extends State<FocusPresetDialog> {
  late final TextEditingController _nameController;
  late int _workMinutes;
  late int _shortBreakMinutes;
  late int _longBreakMinutes;
  late int _intervalsBeforeLongBreak;
  late bool _autoStartBreaks;
  late bool _autoStartWork;
  late bool _allowPause;
  late bool _strictMode;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? 'Custom Focus');
    _workMinutes = ((e?.workSeconds ?? 1500) / 60).round().clamp(1, 180);
    _shortBreakMinutes =
        ((e?.shortBreakSeconds ?? 300) / 60).round().clamp(1, 60);
    _longBreakMinutes =
        ((e?.longBreakSeconds ?? 900) / 60).round().clamp(1, 90);
    _intervalsBeforeLongBreak =
        (e?.intervalsBeforeLongBreak ?? 4).clamp(1, 12);
    _autoStartBreaks = e?.autoStartBreaks ?? false;
    _autoStartWork = e?.autoStartWork ?? false;
    _allowPause = e?.allowPause ?? true;
    _strictMode = e?.strictMode ?? false;
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final now = DateTime.now();
    final item = FocusPresetItem(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: name,
      workSeconds: _workMinutes * 60,
      shortBreakSeconds: _shortBreakMinutes * 60,
      longBreakSeconds: _longBreakMinutes * 60,
      intervalsBeforeLongBreak: _intervalsBeforeLongBreak,
      autoStartBreaks: _autoStartBreaks,
      autoStartWork: _autoStartWork,
      allowPause: _allowPause,
      strictMode: _strictMode,
      isDefault: _isDefault,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'New preset' : 'Edit preset',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Preset name'),
              ),
              const SizedBox(height: 12),
              _NumberRow(
                label: 'Focus duration (min)',
                value: _workMinutes,
                min: 1,
                max: 180,
                onChanged: (v) => setState(() => _workMinutes = v),
              ),
              _NumberRow(
                label: 'Short break (min)',
                value: _shortBreakMinutes,
                min: 1,
                max: 60,
                onChanged: (v) => setState(() => _shortBreakMinutes = v),
              ),
              _NumberRow(
                label: 'Long break (min)',
                value: _longBreakMinutes,
                min: 1,
                max: 90,
                onChanged: (v) => setState(() => _longBreakMinutes = v),
              ),
              _NumberRow(
                label: 'Intervals before long break',
                value: _intervalsBeforeLongBreak,
                min: 1,
                max: 12,
                onChanged: (v) =>
                    setState(() => _intervalsBeforeLongBreak = v),
              ),
              const Divider(height: 20),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-start breaks'),
                value: _autoStartBreaks,
                activeThumbColor: colors.accent,
                onChanged: (v) => setState(() => _autoStartBreaks = v),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-start focus'),
                value: _autoStartWork,
                activeThumbColor: colors.accent,
                onChanged: (v) => setState(() => _autoStartWork = v),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow pause'),
                value: _allowPause,
                activeThumbColor: colors.accent,
                onChanged: (v) => setState(() => _allowPause = v),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Strict mode (60s exit hold)'),
                value: _strictMode,
                activeThumbColor: colors.accent,
                onChanged: (v) => setState(() => _strictMode = v),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Default preset'),
                value: _isDefault,
                activeThumbColor: colors.accent,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
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

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.merge(AppTheme.monoTextStyle),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}
