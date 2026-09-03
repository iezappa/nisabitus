import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/time/weekday.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../core/widgets/weekday_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/exercise.dart';
import '../../domain/exercise_repository.dart';
import '../../domain/scheduled_exercise.dart';

/// What the form hands back: the day's exercise, and how it repeats.
typedef ScheduledExerciseResult = ({
  ScheduledExerciseDraft draft,
  ExerciseRecurrence? recurrence,
});

/// Collects one exercise for one day, and optionally the days it repeats on.
///
/// One form, because it is one thing. The repetition is only asked about when
/// creating: every later day is written down as its own row, so editing one
/// of them is editing that day and nothing else.
Future<ScheduledExerciseResult?> showScheduledExerciseForm(
  BuildContext context, {
  required List<Exercise> catalogue,
  required DateTime day,
  ScheduledExercise? existing,
  Future<void> Function()? onDelete,
  Future<Exercise?> Function()? onCreateExercise,
}) => showDialog<ScheduledExerciseResult>(
  context: context,
  builder: (context) => _ScheduledExerciseDialog(
    catalogue: catalogue,
    day: day,
    existing: existing,
    onDelete: onDelete,
    onCreateExercise: onCreateExercise,
  ),
);

class _ScheduledExerciseDialog extends StatefulWidget {
  const _ScheduledExerciseDialog({
    required this.catalogue,
    required this.day,
    this.existing,
    this.onDelete,
    this.onCreateExercise,
  });

  final List<Exercise> catalogue;
  final DateTime day;
  final ScheduledExercise? existing;
  final Future<void> Function()? onDelete;

  /// Writes down a movement the catalogue did not have yet, and hands it
  /// back. Without it, discovering mid-form that the exercise is missing
  /// means cancelling, going somewhere else, and starting over.
  final Future<Exercise?> Function()? onCreateExercise;

  @override
  State<_ScheduledExerciseDialog> createState() =>
      _ScheduledExerciseDialogState();
}

class _ScheduledExerciseDialogState extends State<_ScheduledExerciseDialog> {
  final _formKey = GlobalKey<FormState>();

  /// A copy, because the form can add to it without closing.
  late final List<Exercise> _catalogue = [...widget.catalogue];

  late int? _exerciseId =
      widget.existing?.exerciseId ??
      (widget.catalogue.isEmpty ? null : widget.catalogue.first.id);

  /// The dropdown entry that is not a movement. Negative so it can never
  /// collide with a real id.
  static const _createId = -1;

  late final _sets = TextEditingController(
    text: '${widget.existing?.sets ?? 4}',
  );
  late final _reps = TextEditingController(
    text: '${widget.existing?.reps ?? 10}',
  );
  late final _weight = TextEditingController(
    text: widget.existing?.weightKg == null
        ? ''
        : widget.existing!.weightKg!.toStringAsFixed(0),
  );
  late final _rpe = TextEditingController(
    text: widget.existing?.rpe == null ? '' : '${widget.existing!.rpe}',
  );
  late final _comments = TextEditingController(
    text: widget.existing?.comments ?? '',
  );

  bool _repeat = false;
  final Set<Weekday> _days = {};
  RecurrenceType _type = RecurrenceType.weeks;
  final _weeks = TextEditingController(text: '4');
  late DateTime _until = widget.day.add(const Duration(days: 28));

  @override
  void initState() {
    super.initState();
    // The day being written on is pre-selected: whoever asked to repeat this
    // almost certainly wants it on this weekday too, and unticking is easier
    // than hunting for the right chip.
    _days.add(Weekday.of(widget.day));
  }

  @override
  void dispose() {
    for (final c in [_sets, _reps, _weight, _rpe, _comments, _weeks]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _weightValue() {
    final raw = _weight.text.trim().replaceAll(',', '.');
    return raw.isEmpty ? null : double.tryParse(raw);
  }

  /// Writes down a movement the catalogue did not have, and selects it.
  ///
  /// Nothing else in the form is touched: the point is to keep going, not to
  /// start over somewhere else.
  Future<void> _createExercise() async {
    final created = await widget.onCreateExercise!();
    if (created == null || !mounted) return;

    setState(() {
      _catalogue.add(created);
      _exerciseId = created.id;
    });
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
    if (!_formKey.currentState!.validate() ||
        _exerciseId == null ||
        (_repeat && _days.isEmpty)) {
      setState(() {});
      return;
    }

    final draft = ScheduledExerciseDraft(
      exerciseId: _exerciseId!,
      sets: int.parse(_sets.text.trim()),
      reps: int.parse(_reps.text.trim()),
      weightKg: _weightValue(),
      rpe: int.tryParse(_rpe.text.trim()),
      comments: _comments.text.trim().isEmpty ? null : _comments.text.trim(),
      feedback: widget.existing?.feedback,
    );

    Navigator.of(context).pop((
      draft: draft,
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
        text: isNew ? l10n.planAdd : l10n.planEdit,
        deleteLabel: isNew ? null : l10n.planEdit,
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
                DropdownButtonFormField<int>(
                  initialValue: _exerciseId,
                  decoration: InputDecoration(
                    labelText: l10n.exerciseCatalogue,
                  ),
                  items: [
                    for (final exercise in _catalogue)
                      DropdownMenuItem(
                        value: exercise.id,
                        child: Text(exercise.name),
                      ),
                    // The way out of a catalogue that does not have what you
                    // are about to write down. Without it, finding that out
                    // mid-form means cancelling and starting over elsewhere.
                    if (widget.onCreateExercise != null)
                      DropdownMenuItem(
                        value: _createId,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 18),
                            const SizedBox(width: Gap.sm),
                            Text(l10n.exerciseNew),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) => value == _createId
                      ? _createExercise()
                      : setState(() => _exerciseId = value),
                ),
                const SizedBox(height: Gap.md),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        controller: _sets,
                        label: l10n.exerciseSets,
                        max: 100,
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: _NumberField(
                        controller: _reps,
                        label: l10n.exerciseReps,
                        max: 1000,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.md),
                Row(
                  // Aligned at the top on purpose. The weight field carries a
                  // helper line and the RPE field does not, so centring them
                  // floats RPE below its neighbour and the helper line reads
                  // as a label for the wrong field.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.exerciseWeight,
                          suffixText: 'kg',
                          helperText: l10n.exerciseBodyweight,
                        ),
                        // Blank is allowed and is not zero: a chin-up carries
                        // no external load, and 0 kg would claim it was
                        // measured.
                        validator: (value) {
                          final text = (value ?? '').trim().replaceAll(
                            ',',
                            '.',
                          );
                          if (text.isEmpty) return null;

                          final parsed = double.tryParse(text);
                          return parsed == null ||
                                  parsed < 0 ||
                                  parsed > ScheduledExercise.maxWeightKg
                              ? l10n.planValidationNumber(1000)
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _rpe,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'RPE'),
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) return null;

                          final parsed = int.tryParse(text);
                          return parsed == null || parsed < 1 || parsed > 10
                              ? l10n.planValidationRpe
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.md),
                TextFormField(
                  controller: _comments,
                  maxLength: 1000,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.planComments,
                    hintText: l10n.planCommentsHint,
                    alignLabelWithHint: true,
                  ),
                ),
                // Only when creating. Every later day is already its own row,
                // so a repetition cannot be edited from one of them without
                // reaching into days the user is not looking at.
                // What to do stops here; how often it comes round starts
                // below. Separated by air and by its own headings, not by a
                // rule: no other dialog in this app draws one, and the one
                // tried here was invisible anyway — the divider colour is
                // tuned for the page, not for the tinted surface of a dialog.
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
                      _NumberField(
                        controller: _weeks,
                        label: l10n.planRepeatWeeksValue,
                        max: ExerciseRecurrence.maxWeeks,
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

/// The heading that opens a block inside a dialog.
///
/// `labelLarge`, left-aligned, carrying its own gap below — which is what the
/// habit form already uses. Not `SectionLabel`: that is the uppercase heading
/// of the settings column, and borrowing it here would make a dialog read
/// like a page.
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

/// A whole-number field.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse((value ?? '').trim());
        return parsed == null || parsed < 1 || parsed > max
            ? l10n.planValidationNumber(max)
            : null;
      },
    );
  }
}

/// Asks what actually happened, on the way to ticking an exercise off.
///
/// Everything is optional and everything is pre-filled with what was planned,
/// so the common case — it went as written — is one tap on Guardar. What is
/// left alone stays as planned rather than being overwritten with a blank.
Future<ExerciseCompletion?> showCompletionForm(
  BuildContext context, {
  required ScheduledExercise scheduled,
}) => showDialog<ExerciseCompletion>(
  context: context,
  builder: (context) => _CompletionDialog(scheduled: scheduled),
);

class _CompletionDialog extends StatefulWidget {
  const _CompletionDialog({required this.scheduled});

  final ScheduledExercise scheduled;

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _weight = TextEditingController(
    text: widget.scheduled.weightKg == null
        ? ''
        : widget.scheduled.weightKg!.toStringAsFixed(0),
  );
  late final _rpe = TextEditingController(
    text: widget.scheduled.rpe == null ? '' : '${widget.scheduled.rpe}',
  );
  late final _feedback = TextEditingController(
    text: widget.scheduled.feedback ?? '',
  );

  @override
  void dispose() {
    for (final c in [_weight, _rpe, _feedback]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final raw = _weight.text.trim().replaceAll(',', '.');
    Navigator.of(context).pop(
      ExerciseCompletion(
        weightKg: raw.isEmpty ? null : double.parse(raw),
        rpe: int.tryParse(_rpe.text.trim()),
        feedback: _feedback.text.trim().isEmpty ? null : _feedback.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.planCompleteTitle),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.planCompleteHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Gap.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.exerciseWeight,
                        suffixText: 'kg',
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim().replaceAll(',', '.');
                        if (text.isEmpty) return null;

                        final parsed = double.tryParse(text);
                        return parsed == null ||
                                parsed < 0 ||
                                parsed > ScheduledExercise.maxWeightKg
                            ? l10n.planValidationNumber(1000)
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _rpe,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'RPE'),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return null;

                        final parsed = int.tryParse(text);
                        return parsed == null || parsed < 1 || parsed > 10
                            ? l10n.planValidationRpe
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
