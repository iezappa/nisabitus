import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/focus_sound.dart';

/// Collects one sound for the library. Returns null when dismissed.
Future<FocusSoundDraft?> showFocusSoundForm(
  BuildContext context, {
  FocusSound? existing,
  Future<void> Function()? onDelete,
}) => showDialog<FocusSoundDraft>(
  context: context,
  builder: (context) =>
      _FocusSoundDialog(existing: existing, onDelete: onDelete),
);

class _FocusSoundDialog extends StatefulWidget {
  const _FocusSoundDialog({this.existing, this.onDelete});

  final FocusSound? existing;
  final Future<void> Function()? onDelete;

  @override
  State<_FocusSoundDialog> createState() => _FocusSoundDialogState();
}

class _FocusSoundDialogState extends State<_FocusSoundDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _url = TextEditingController(text: widget.existing?.url ?? '');

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context)
        .pop(FocusSoundDraft(name: _name.text, url: _url.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: DialogTitle(
        text: widget.existing == null
            ? l10n.pomodoroSoundAdd
            : l10n.pomodoroSoundEdit,
        deleteLabel: widget.existing?.name,
        onDelete: widget.onDelete,
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: FocusSoundDraft.maxNameLength,
                decoration: InputDecoration(
                  labelText: l10n.pomodoroSoundName,
                  helperText: l10n.pomodoroSoundNameHint,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.validationNameRequired
                    : null,
              ),
              const SizedBox(height: Gap.md),
              TextFormField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.pomodoroSoundUrl,
                  helperText: l10n.pomodoroSoundUrlHint,
                ),
                // Checked here rather than when it is played: finding out
                // the link is unusable in the middle of a focus session is
                // a worse moment than the one where it was pasted.
                validator: (value) =>
                    _playable(value) ? null : l10n.pomodoroSoundInvalid,
              ),
              const SizedBox(height: Gap.sm),
              Text(
                l10n.pomodoroSoundNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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

  /// Whether the draft would accept this link, asked without throwing.
  static bool _playable(String? value) {
    try {
      FocusSoundDraft(name: 'x', url: value ?? '');
      return true;
    } on ArgumentError {
      return false;
    }
  }
}
