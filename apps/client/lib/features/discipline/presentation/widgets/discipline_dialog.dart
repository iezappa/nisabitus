import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/time/weekday.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../core/widgets/weekday_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../exercise/domain/scheduled_exercise.dart';
import '../../domain/discipline.dart';
import '../../domain/discipline_repository.dart';

/// What the form hands back: the day's session, and how it repeats.
typedef DisciplineResult = ({
  DisciplineDraft draft,
  ExerciseRecurrence? recurrence,
});

/// Collects one session of something practised for a time.
///
/// The name is typed rather than picked: there is no catalogue behind this on
/// purpose, because "Natación" does not need a definition somewhere else
/// before it can be written down.
Future<DisciplineResult?> showDisciplineForm(
  BuildContext context, {
  required DateTime day,
  Discipline? existing,
  Future<void> Function()? onDelete,
}) => showDialog<DisciplineResult>(
  context: context,
  builder: (context) =>
      _DisciplineDialog(day: day, existing: existing, onDelete: onDelete),
);

class _DisciplineDialog extends StatefulWidget {
  const _DisciplineDialog({required this.day, this.existing, this.onDelete});

  final DateTime day;
  final Discipline? existing;
  final Future<void> Function()? onDelete;

  @override
  State<_DisciplineDialog> createState() => _DisciplineDialogState();
}

class _DisciplineDialogState extends State<_DisciplineDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _minutes = TextEditingController(
    text: '${widget.existing?.durationMinutes ?? 30}',
  );
  late final _distance = TextEditingController(
    text: widget.existing?.distanceKm == null
        ? ''
        : '${widget.existing!.distanceKm}',
  );
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');

  bool _repeat = false;
  final Set<Weekday> _days = {};
  RecurrenceType _type = RecurrenceType.weeks;
  final _weeks = TextEditingController(text: '4');
  late DateTime _until = widget.day.add(const Duration(days: 28));

  @override
  void initState() {
    super.initState();
    _days.add(Weekday.of(widget.day));
  }

  @override
  void dispose() {
    for (final c in [_name, _minutes, _distance, _notes, _weeks]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _distanceValue() {
    final raw = _distance.text.trim().replaceAll(',', '.');
    return raw.isEmpty ? null : double.tryParse(raw);
  }

  Future<void> _pickUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _until,
      firstDate: widget.day,
      lastDate: DateTime(widget.day.year + 5),
    );
    if (picked != null) setState(() => _until = picked);
  }

  void _submit() {
    // The day chips are not a form field, so they are checked by hand.
    if (!_formKey.currentState!.validate() || (_repeat && _days.isEmpty)) {
      setState(() {});
      return;
    }

    Navigator.of(context).pop((
      draft: DisciplineDraft(
        name: _name.text,
        durationMinutes: int.parse(_minutes.text.trim()),
        distanceKm: _distanceValue(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
      recurrence: !_repeat
          ? null
          : ExerciseRecurrence(
              days: _days,
              type: _type,
              weeks: int.tryParse(_weeks.text.trim()),
              endDate: _until,
            ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isNew = widget.existing == null;

    return AlertDialog(
      title: DialogTitle(
        text: isNew ? l10n.disciplineAdd : l10n.disciplineEdit,
        deleteLabel: widget.existing?.name,
        onDelete: widget.onDelete,
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  maxLength: 255,
                  decoration: InputDecoration(
                    labelText: l10n.disciplineName,
                    hintText: l10n.disciplineNameHint,
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.validationNameRequired
                      : null,
                ),
                Row(
                  // Aligned at the top: the distance field is optional and
                  // says so, so the two are not the same height.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minutes,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.disciplineDuration,
                          suffixText: 'min',
                        ),
                        validator: (value) {
                          final parsed = int.tryParse((value ?? '').trim());
                          return parsed == null ||
                                  parsed < 1 ||
                                  parsed > Discipline.maxMinutes
                              ? l10n.disciplineValidationMinutes(
                                  Discipline.maxMinutes,
                                )
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _distance,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.disciplineDistance,
                          suffixText: 'km',
                        ),
                        // Blank is allowed: a yoga class has a duration and
                        // no kilometres, and zero would claim it was measured.
                        validator: (value) {
                          final text = (value ?? '').trim().replaceAll(
                            ',',
                            '.',
                          );
                          if (text.isEmpty) return null;

                          final parsed = double.tryParse(text);
                          return parsed == null ||
                                  parsed <= 0 ||
                                  parsed > Discipline.maxDistanceKm
                              ? l10n.disciplineValidationDistance(1000)
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.md),
                TextFormField(
                  controller: _notes,
                  maxLength: 1000,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.disciplineNotes,
                    alignLabelWithHint: true,
                  ),
                ),
                if (isNew) ...[
                  const SizedBox(height: Gap.lg),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.planRepeat),
                    value: _repeat,
                    onChanged: (value) => setState(() => _repeat = value),
                  ),
                  if (_repeat) ...[
                    const SizedBox(height: Gap.md),
                    _Heading(l10n.planRepeatDays),
                    WeekdayPicker(
                      selected: _days,
                      onChanged: (days) => setState(() {
                        _days
                          ..clear()
                          ..addAll(days);
                      }),
                    ),
                    if (_days.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: Gap.xs),
                        child: Text(
                          l10n.planValidationDays,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: Gap.lg),
                    _Heading(l10n.planRepeatUntilLabel),
                    SegmentedButton<RecurrenceType>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: RecurrenceType.weeks,
                          label: Text(l10n.planRepeatWeeks),
                        ),
                        ButtonSegment(
                          value: RecurrenceType.until,
                          label: Text(l10n.planRepeatUntil),
                        ),
                        ButtonSegment(
                          value: RecurrenceType.forever,
                          label: Text(l10n.planRepeatForever),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (selection) =>
                          setState(() => _type = selection.first),
                    ),
                    if (_type == RecurrenceType.weeks) ...[
                      const SizedBox(height: Gap.md),
                      TextFormField(
                        controller: _weeks,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.planRepeatWeeksValue,
                        ),
                        validator: (value) {
                          final parsed = int.tryParse((value ?? '').trim());
                          return parsed == null ||
                                  parsed < 1 ||
                                  parsed > ExerciseRecurrence.maxWeeks
                              ? l10n.planValidationNumber(
                                  ExerciseRecurrence.maxWeeks,
                                )
                              : null;
                        },
                      ),
                    ],
                    if (_type == RecurrenceType.until)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: Text(l10n.planRepeatUntilValue),
                        trailing: Text(DateFormat('dd/MM/yyyy').format(_until)),
                        onTap: _pickUntil,
                      ),
                  ],
                ],
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

/// Asks what actually happened, on the way to ticking a session off.
Future<DisciplineCompletion?> showDisciplineCompletion(
  BuildContext context, {
  required Discipline discipline,
}) => showDialog<DisciplineCompletion>(
  context: context,
  builder: (context) => _DisciplineCompletionDialog(discipline: discipline),
);

class _DisciplineCompletionDialog extends StatefulWidget {
  const _DisciplineCompletionDialog({required this.discipline});

  final Discipline discipline;

  @override
  State<_DisciplineCompletionDialog> createState() =>
      _DisciplineCompletionDialogState();
}

class _DisciplineCompletionDialogState
    extends State<_DisciplineCompletionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _minutes = TextEditingController(
    text: '${widget.discipline.durationMinutes}',
  );
  late final _distance = TextEditingController(
    text: widget.discipline.distanceKm == null
        ? ''
        : '${widget.discipline.distanceKm}',
  );
  late final _feedback = TextEditingController(
    text: widget.discipline.feedback ?? '',
  );

  @override
  void dispose() {
    for (final c in [_minutes, _distance, _feedback]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final raw = _distance.text.trim().replaceAll(',', '.');
    Navigator.of(context).pop(
      DisciplineCompletion(
        durationMinutes: int.tryParse(_minutes.text.trim()),
        distanceKm: raw.isEmpty ? null : double.parse(raw),
        feedback: _feedback.text.trim().isEmpty ? null : _feedback.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.disciplineCompleteTitle),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.disciplineCompleteHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Gap.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minutes,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.disciplineDuration,
                        suffixText: 'min',
                      ),
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        return parsed == null ||
                                parsed < 1 ||
                                parsed > Discipline.maxMinutes
                            ? l10n.disciplineValidationMinutes(
                                Discipline.maxMinutes,
                              )
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _distance,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.disciplineDistance,
                        suffixText: 'km',
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim().replaceAll(',', '.');
                        if (text.isEmpty) return null;

                        final parsed = double.tryParse(text);
                        return parsed == null ||
                                parsed <= 0 ||
                                parsed > Discipline.maxDistanceKm
                            ? l10n.disciplineValidationDistance(1000)
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              TextFormField(
                controller: _feedback,
                autofocus: true,
                maxLength: 1000,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.planFeedback,
                  hintText: l10n.planFeedbackHint,
                  alignLabelWithHint: true,
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

/// The heading that opens a block inside a dialog. Matches the one the
/// scheduling form uses, which matches the one the habit form uses.
class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    ),
  );
}
