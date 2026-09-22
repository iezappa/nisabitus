import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/vacation.dart';

/// Collects one break. Returns null when dismissed.
Future<VacationDraft?> showVacationForm(
  BuildContext context, {
  required DateTime today,
  VacationPeriod? existing,
  Future<void> Function()? onDelete,
}) => showDialog<VacationDraft>(
  context: context,
  builder: (context) =>
      _VacationFormDialog(today: today, existing: existing, onDelete: onDelete),
);

class _VacationFormDialog extends StatefulWidget {
  const _VacationFormDialog({
    required this.today,
    this.existing,
    this.onDelete,
  });

  /// The day a new break starts on, unless the user picks another.
  ///
  /// Passed in rather than read off the clock here: the rest of the app
  /// works from one idea of what day it is, and a dialog with its own would
  /// disagree with it at midnight and in every test.
  final DateTime today;

  final VacationPeriod? existing;
  final Future<void> Function()? onDelete;

  @override
  State<_VacationFormDialog> createState() => _VacationFormDialogState();
}

class _VacationFormDialogState extends State<_VacationFormDialog> {
  late DateTime _start = widget.existing?.start ?? widget.today;
  late DateTime? _end = widget.existing?.endsOn;
  late final _note = TextEditingController(text: widget.existing?.note ?? '');

  /// Set when the dates disagree, so the dialog says so instead of throwing.
  bool _backwards = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final end = _end;
    if (end != null && end.isBefore(_start)) {
      setState(() => _backwards = true);
      return;
    }

    Navigator.of(context)
        .pop(VacationDraft(start: _start, end: end, note: _note.text));
  }

  Future<void> _pick({required bool start}) async {
    final anchor = start ? _start : _end ?? _start;
    final picked = await showDatePicker(
      context: context,
      initialDate: anchor,
      firstDate: DateTime(anchor.year - 5),
      lastDate: DateTime(anchor.year + 5),
    );
    if (picked == null) return;

    setState(() {
      _backwards = false;
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final format = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return AlertDialog(
      title: DialogTitle(
        text: l10n.vacationEditTitle,
        deleteLabel: widget.existing == null ? null : format.format(_start),
        onDelete: widget.onDelete,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateField(
                label: l10n.vacationFrom,
                value: format.format(_start),
                onTap: () => _pick(start: true),
              ),
              const SizedBox(height: Gap.md),
              _DateField(
                label: l10n.vacationUntil,
                value: _end == null
                    ? l10n.vacationUntilOpen
                    : format.format(_end!),
                onTap: () => _pick(start: false),
                // An open end is the normal case while the break is on, so
                // clearing the date has to be one tap rather than a trip
                // back through the picker.
                onClear: _end == null
                    ? null
                    : () => setState(() => _end = null),
              ),
              if (_backwards)
                Padding(
                  padding: const EdgeInsets.only(top: Gap.sm),
                  child: Text(
                    l10n.vacationBackwards,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: Gap.md),
              TextField(
                controller: _note,
                maxLength: VacationDraft.maxNoteLength,
                decoration: InputDecoration(
                  labelText: l10n.vacationNote,
                  // Helper, not hint: a hint is painted where the user
                  // types and overlaps what they write.
                  helperText: l10n.vacationNoteHint,
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
}

/// A date shown as a field, opening the picker when tapped.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onClear == null
              ? const Icon(Icons.event_outlined)
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: l10n.vacationUntilOpen,
                  onPressed: onClear,
                ),
        ),
        child: Text(value),
      ),
    );
  }
}
