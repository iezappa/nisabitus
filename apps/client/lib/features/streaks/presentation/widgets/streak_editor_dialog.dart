import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/streak.dart';

/// Everything that can be done to a streak other than adding to it.
///
/// Renaming, resetting and deleting live together here so the card itself
/// keeps a single obvious action.
Future<String?> showStreakEditor(
  BuildContext context, {
  required Streak streak,
  required DateTime today,
  required Future<void> Function() onReset,
  required Future<void> Function() onDelete,
  required Future<void> Function(DateTime day) onRecordDay,
}) => showDialog<String>(
  context: context,
  builder: (context) => _StreakEditorDialog(
    streak: streak,
    today: today,
    onReset: onReset,
    onDelete: onDelete,
    onRecordDay: onRecordDay,
  ),
);

class _StreakEditorDialog extends StatefulWidget {
  const _StreakEditorDialog({
    required this.streak,
    required this.today,
    required this.onReset,
    required this.onDelete,
    required this.onRecordDay,
  });

  final Streak streak;

  /// The app's idea of today, so the calendar cannot offer a day that has
  /// not happened yet.
  final DateTime today;

  final Future<void> Function() onReset;
  final Future<void> Function() onDelete;

  /// Adds the day the user forgot to record at the time.
  final Future<void> Function(DateTime day) onRecordDay;

  @override
  State<_StreakEditorDialog> createState() => _StreakEditorDialogState();
}

class _StreakEditorDialogState extends State<_StreakEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.streak.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_name.text.trim());
  }

  /// Records a day the user did the thing on but never ticked.
  ///
  /// A run only breaks on a day with nothing recorded, so filling that day
  /// in is what rescues it — but only until the next midnight, after which
  /// the day after the gap has broken it too.
  Future<void> _recordMissedDay() async {
    final today = widget.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      // A year back is as far as a forgotten day is worth chasing; nothing
      // ahead, because a day that has not happened cannot have been missed.
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: today,
    );
    if (picked == null) return;

    await widget.onRecordDay(picked);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: DialogTitle(
        text: l10n.actionEdit,
        deleteLabel: widget.streak.name,
        onDelete: widget.onDelete,
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: 255,
                decoration: InputDecoration(labelText: l10n.fieldName),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.validationNameRequired
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                l10n.streakRecord(widget.streak.maxStreak),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: Gap.lg),
              OutlinedButton.icon(
                onPressed: _recordMissedDay,
                icon: const Icon(Icons.event_available, size: 18),
                label: Text(l10n.streakMissedDay),
              ),
              const SizedBox(height: Gap.sm),
              OutlinedButton.icon(
                onPressed: () async {
                  await widget.onReset();
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(l10n.streakReset),
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
