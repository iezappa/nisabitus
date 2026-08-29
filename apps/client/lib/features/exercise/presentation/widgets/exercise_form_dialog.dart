import 'package:flutter/material.dart';

import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/exercise.dart';
import '../../domain/exercise_repository.dart';

/// Collects an exercise definition. Returns null when dismissed.
Future<ExerciseDraft?> showExerciseForm(
  BuildContext context, {
  Exercise? existing,
  Future<void> Function()? onDelete,
}) => showDialog<ExerciseDraft>(
  context: context,
  builder: (context) =>
      _ExerciseFormDialog(existing: existing, onDelete: onDelete),
);

class _ExerciseFormDialog extends StatefulWidget {
  const _ExerciseFormDialog({this.existing, this.onDelete});

  final Exercise? existing;
  final Future<void> Function()? onDelete;

  @override
  State<_ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends State<_ExerciseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _group = TextEditingController(
    text: widget.existing?.muscleGroup ?? '',
  );
  late final _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );

  @override
  void dispose() {
    for (final c in [_name, _group, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      ExerciseDraft(
        name: _name.text,
        muscleGroup: _text(_group),
        description: _text(_description),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: DialogTitle(
        text: widget.existing == null ? l10n.exerciseNew : l10n.exerciseEdit,
        deleteLabel: widget.existing?.name,
        onDelete: widget.onDelete,
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
                  controller: _group,
                  maxLength: 255,
                  decoration: InputDecoration(
                    labelText: l10n.exerciseMuscleGroup,
                  ),
                ),
                TextFormField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: l10n.exerciseDescription,
                  ),
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

/// Collects one set. Returns null when dismissed.
Future<({int reps, double? weight})?> showSetForm(
  BuildContext context, {
  ExerciseSet? existing,
  Future<void> Function()? onDelete,
}) => showDialog<({int reps, double? weight})>(
  context: context,
  builder: (context) => _SetFormDialog(existing: existing, onDelete: onDelete),
);

class _SetFormDialog extends StatefulWidget {
  const _SetFormDialog({this.existing, this.onDelete});

  final ExerciseSet? existing;
  final Future<void> Function()? onDelete;

  @override
  State<_SetFormDialog> createState() => _SetFormDialogState();
}

class _SetFormDialogState extends State<_SetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _reps = TextEditingController(
    text: '${widget.existing?.reps ?? 10}',
  );
  late final _weight = TextEditingController(
    text: widget.existing?.weight == null ? '' : '${widget.existing!.weight}',
  );

  @override
  void dispose() {
    _reps.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final raw = _weight.text.trim().replaceAll(',', '.');
    Navigator.of(context).pop((
      reps: int.parse(_reps.text),
      // Blank means bodyweight, which is not the same as zero.
      weight: raw.isEmpty ? null : double.parse(raw),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: DialogTitle(
        text: widget.existing == null
            ? l10n.exerciseAddSet
            : l10n.exerciseEditSet,
        onDelete: widget.onDelete,
        deleteLabel: l10n.exerciseEditSet,
      ),
      content: SizedBox(
        width: 320,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _reps,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.exerciseReps),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  return parsed == null || parsed < 1 || parsed > 1000
                      ? l10n.nutritionValidationNumber(1000)
                      : null;
                },
              ),
              TextFormField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.exerciseWeight,
                  helperText: l10n.exerciseBodyweight,
                ),
                validator: (value) {
                  final text = (value ?? '').trim().replaceAll(',', '.');
                  if (text.isEmpty) return null;

                  final parsed = double.tryParse(text);
                  return parsed == null || parsed < 0 || parsed > 1000
                      ? l10n.nutritionValidationNumber(1000)
                      : null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
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
