import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/pomodoro_draft.dart';
import '../../domain/pomodoro_session.dart';

/// Collects the fields of a focus session. Returns null when dismissed.
Future<PomodoroDraft?> showPomodoroForm(
  BuildContext context, {
  PomodoroSession? existing,
}) => showDialog<PomodoroDraft>(
  context: context,
  builder: (context) => _PomodoroFormDialog(existing: existing),
);

class _PomodoroFormDialog extends StatefulWidget {
  const _PomodoroFormDialog({this.existing});

  final PomodoroSession? existing;

  @override
  State<_PomodoroFormDialog> createState() => _PomodoroFormDialogState();
}

class _PomodoroFormDialogState extends State<_PomodoroFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _category = TextEditingController(
    text: widget.existing?.category ?? '',
  );
  late final _purpose = TextEditingController(
    text: widget.existing?.purpose ?? '',
  );
  late final _focus = TextEditingController(
    text: '${widget.existing?.focusDuration ?? 25}',
  );
  late final _rest = TextEditingController(
    text: '${widget.existing?.breakDuration ?? 5}',
  );
  late final _cycles = TextEditingController(
    text: '${widget.existing?.cycles ?? 4}',
  );

  @override
  void dispose() {
    for (final c in [_name, _category, _purpose, _focus, _rest, _cycles]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      PomodoroDraft(
        name: _name.text,
        category: _text(_category),
        purpose: _text(_purpose),
        cycles: int.parse(_cycles.text),
        focusDuration: int.parse(_focus.text),
        breakDuration: int.parse(_rest.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        widget.existing == null ? l10n.pomodoroNew : l10n.pomodoroEdit,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  maxLength: 255,
                  decoration: InputDecoration(labelText: l10n.fieldName),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.validationNameRequired
                      : null,
                ),
                TextFormField(
                  controller: _category,
                  maxLength: 255,
                  decoration: InputDecoration(labelText: l10n.fieldCategory),
                ),
                TextFormField(
                  controller: _purpose,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l10n.pomodoroPurpose),
                ),
                const SizedBox(height: Gap.lg),
                _Number(
                  controller: _focus,
                  label: l10n.pomodoroFocusMinutes,
                  min: 1,
                  max: 180,
                ),
                const SizedBox(height: Gap.md),
                _Number(
                  controller: _rest,
                  label: l10n.pomodoroBreakMinutes,
                  min: 0,
                  max: 60,
                ),
                const SizedBox(height: Gap.md),
                _Number(
                  controller: _cycles,
                  label: l10n.pomodoroCycles,
                  min: 1,
                  max: 12,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.actionSave)),
      ],
    );
  }
}

class _Number extends StatelessWidget {
  const _Number({
    required this.controller,
    required this.label,
    required this.min,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse(value ?? '');
        return parsed == null || parsed < min || parsed > max
            ? l10n.pomodoroValidationRange(min, max)
            : null;
      },
    );
  }
}
