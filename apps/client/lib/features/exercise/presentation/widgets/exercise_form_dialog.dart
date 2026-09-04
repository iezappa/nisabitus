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
  late final _video = TextEditingController(
    text: widget.existing?.videoUrl ?? '',
  );

  @override
  void dispose() {
    for (final c in [_name, _group, _description, _video]) {
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
        videoUrl: _text(_video),
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
        // The bin here does not only remove a name from a list: the
        // scheduled rows cascade with it. The confirmation says that.
        deleteBody: l10n.exerciseDeleteBody,
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
                // On the movement, not on the routine: a squat is performed
                // the same way whoever prescribed it, so the link is right
                // once instead of copied into every plan that asks for one.
                TextFormField(
                  controller: _video,
                  maxLength: 2000,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: l10n.exerciseVideo,
                    hintText: l10n.exerciseVideoHint,
                    prefixIcon: const Icon(Icons.ondemand_video_outlined),
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
