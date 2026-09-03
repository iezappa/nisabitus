import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/meditation.dart';
import '../../domain/meditation_repository.dart';

/// Collects one sitting. Returns null when dismissed.
Future<MeditationDraft?> showMeditationForm(
  BuildContext context, {
  MeditationSession? existing,
  Future<void> Function()? onDelete,
}) => showDialog<MeditationDraft>(
  context: context,
  builder: (context) =>
      _MeditationFormDialog(existing: existing, onDelete: onDelete),
);

class _MeditationFormDialog extends StatefulWidget {
  const _MeditationFormDialog({this.existing, this.onDelete});

  final MeditationSession? existing;
  final Future<void> Function()? onDelete;

  @override
  State<_MeditationFormDialog> createState() => _MeditationFormDialogState();
}

class _MeditationFormDialogState extends State<_MeditationFormDialog> {
  /// The lengths people actually sit for, one tap each. Anything else is
  /// typed: a row of every number between one and eighty is not a shortcut.
  static const _presets = [5, 10, 20, 30];

  final _formKey = GlobalKey<FormState>();
  late final _minutes = TextEditingController(
    text: widget.existing == null ? '' : '${widget.existing!.minutes}',
  );
  late final _note = TextEditingController(text: widget.existing?.note ?? '');

  @override
  void dispose() {
    _minutes.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      MeditationDraft(
        minutes: int.parse(_minutes.text.trim()),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: DialogTitle(
        text: widget.existing == null
            ? l10n.meditationAdd
            : l10n.meditationEdit,
        deleteLabel: widget.existing == null
            ? null
            : l10n.meditationMinutes(widget.existing!.minutes),
        onDelete: widget.onDelete,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Gap.sm,
                  children: [
                    for (final minutes in _presets)
                      ActionChip(
                        label: Text(l10n.meditationMinutes(minutes)),
                        onPressed: () =>
                            setState(() => _minutes.text = '$minutes'),
                      ),
                  ],
                ),
                const SizedBox(height: Gap.md),
                TextFormField(
                  controller: _minutes,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.meditationDuration,
                    suffixText: 'min',
                  ),
                  validator: (value) {
                    final parsed = int.tryParse((value ?? '').trim());
                    return parsed == null ||
                            parsed < 1 ||
                            parsed > MeditationSession.maxMinutes
                        ? l10n.meditationValidationMinutes(
                            MeditationSession.maxMinutes,
                          )
                        : null;
                  },
                ),
                const SizedBox(height: Gap.md),
                TextFormField(
                  controller: _note,
                  maxLength: 1000,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.meditationNote,
                    hintText: l10n.meditationNoteHint,
                    alignLabelWithHint: true,
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
