import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/dialog_title.dart';
import '../../../../core/l10n/sort_key.dart';
import '../../../../core/widgets/name_prompt_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/habit.dart';
import '../../domain/habit_draft.dart';
import '../../domain/habit_frequency.dart';
import '../habit_labels.dart';
import '../../../../core/time/weekday.dart';
import '../../../../core/widgets/weekday_picker.dart';

/// Collects the fields of a habit. Returns null when dismissed.
Future<HabitDraft?> showHabitForm(
  BuildContext context, {
  Habit? existing,
  HabitFrequency initialFrequency = HabitFrequency.daily,
  Future<void> Function()? onDelete,
  List<String> categories = const [],
}) => showDialog<HabitDraft>(
  context: context,
  builder: (context) => _HabitFormDialog(
    existing: existing,
    initialFrequency: initialFrequency,
    onDelete: onDelete,
    categories: categories,
  ),
);

class _HabitFormDialog extends StatefulWidget {
  const _HabitFormDialog({
    required this.existing,
    required this.initialFrequency,
    this.onDelete,
    this.categories = const [],
  });

  final Habit? existing;
  final HabitFrequency initialFrequency;
  final Future<void> Function()? onDelete;

  /// Categories the user has already filed a habit under.
  ///
  /// Passed in rather than read here, the same way the food form is told
  /// which meal to start on: a dialog that goes to the database is a
  /// dialog that cannot be built in a test without one.
  final List<String> categories;

  @override
  State<_HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<_HabitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;

  /// The category as chosen, or null for none.
  ///
  /// A value rather than a controller: the field is a dropdown now, and
  /// a new category is typed into the prompt it opens rather than into
  /// the field itself.
  late String? _category;
  late final TextEditingController _target;

  late HabitFrequency _frequency;
  late Set<Weekday> _repeatDays;
  late bool _repeatForever;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _category = existing?.category?.trim();
    _target = TextEditingController(text: '${existing?.targetCount ?? 1}');
    _frequency = existing?.frequency ?? widget.initialFrequency;
    _repeatDays = {...?existing?.repeatDays};
    _repeatForever = existing?.repeatForever ?? false;
    _endDate = existing?.endDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      HabitDraft(
        name: _name.text,
        description: _blankToNull(_description.text),
        category: _category?.trim().isEmpty ?? true ? null : _category,
        frequency: _frequency,
        targetCount: int.tryParse(_target.text) ?? 1,
        endDate: _endDate,
        repeatForever: _repeatForever,
        // Weekdays only mean something for daily and weekly habits.
        repeatDays: _frequency.supportsRepeatDays ? _repeatDays : const {},
      ),
    );
  }

  /// An untouched optional field is absent, not an empty string.
  static String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: DialogTitle(
        text: widget.existing == null ? l10n.habitNew : l10n.habitEdit,
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
                  decoration: InputDecoration(labelText: l10n.fieldName),
                  maxLength: 255,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.validationNameRequired
                      : null,
                ),
                TextFormField(
                  controller: _description,
                  decoration: InputDecoration(labelText: l10n.fieldDescription),
                  maxLength: 5000,
                  maxLines: 2,
                  minLines: 1,
                ),
                // The app's own text field with a caret on it, rather than
                // a `DropdownMenu`: that one brings its own decoration and
                // ignores the app's, so it rendered as an outlined box in a
                // form of filled ones. This is the same widget as every
                // field above it and wears the same theme as `Frecuencia`
                // below.
                //
                // Still a text field underneath, because the categories are
                // offered and not imposed: a closed list would mean the first
                // habit of a new category could not be written at all.
                _CategoryField(
                  value: _category,
                  categories: widget.categories,
                  onChanged: (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<HabitFrequency>(
                  initialValue: _frequency,
                  decoration: InputDecoration(labelText: l10n.fieldFrequency),
                  items: [
                    for (final frequency in HabitFrequency.values)
                      DropdownMenuItem(
                        value: frequency,
                        child: Text(l10n.frequencyName(frequency)),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _frequency = value ?? _frequency),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _target,
                  decoration: InputDecoration(labelText: l10n.fieldTarget),
                  keyboardType: TextInputType.number,
                ),
                if (_frequency.supportsRepeatDays) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.habitRepeatDays,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  WeekdayPicker(
                    selected: _repeatDays,
                    onChanged: (days) => setState(() => _repeatDays = days),
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.habitRepeatForever),
                  value: _repeatForever,
                  onChanged: (value) => setState(() {
                    _repeatForever = value;
                    // The two can never disagree, so choosing "forever"
                    // clears any end date already picked.
                    if (value) _endDate = null;
                  }),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: !_repeatForever,
                  title: Text(l10n.habitEndDate),
                  subtitle: Text(
                    _endDate == null
                        ? '—'
                        : DateFormat('dd/MM/yyyy').format(_endDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                  onTap: _repeatForever ? null : _pickEndDate,
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

/// The seven days as round toggles. Nothing selected means every day.

/// The category field.
///
/// A `DropdownButtonFormField`, the same widget `Frecuencia` uses, because
/// nothing else makes the two look alike **open**: a `MenuAnchor` draws its
/// own kind of menu and a `DropdownMenu` brings its own decoration, and both
/// were visibly not this form.
///
/// Which leaves writing a category that does not exist yet, since a dropdown
/// cannot be typed into. The last entry opens the same name prompt the app
/// already uses for a new project, so it is a gesture the user has met
/// before rather than one invented here.
class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  final String? value;
  final List<String> categories;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // The habit's own category belongs in the list even when nothing else
    // uses it any more — otherwise editing that habit would show a dropdown
    // whose value is not one of its options.
    final options = [
      ...categories,
      if (value case final current? when current.isNotEmpty)
        if (!categories.contains(current)) current,
    ]..sort((a, b) => sortKey(a).compareTo(sortKey(b)));

    return DropdownButtonFormField<_CategoryChoice>(
      initialValue: value == null || value!.isEmpty
          ? const _NoCategory()
          : _Existing(value!),
      decoration: InputDecoration(labelText: l10n.fieldCategory),
      items: [
        DropdownMenuItem(
          value: const _NoCategory(),
          child: Text(l10n.habitsNoCategory),
        ),
        for (final category in options)
          DropdownMenuItem(value: _Existing(category), child: Text(category)),
        DropdownMenuItem(
          value: const _NewCategory(),
          child: Text(l10n.habitsNewCategory),
        ),
      ],
      onChanged: (choice) async {
        switch (choice) {
          case _NoCategory():
            onChanged(null);
          case _Existing(:final name):
            onChanged(name);
          case _NewCategory():
            final name = await promptForName(
              context,
              title: l10n.habitsNewCategory,
            );
            // Dismissing the prompt leaves the category where it was. A
            // cancelled dialog must not be a way to clear a field.
            if (name != null) onChanged(name.trim());
          case null:
            break;
        }
      },
    );
  }
}

/// What the category dropdown can be set to.
///
/// A type rather than a `String?` with a magic value in it: a category is
/// free text, so any sentinel string is a category somebody could type.
sealed class _CategoryChoice {
  const _CategoryChoice();
}

class _NoCategory extends _CategoryChoice {
  const _NoCategory();

  @override
  bool operator ==(Object other) => other is _NoCategory;

  @override
  int get hashCode => 0;
}

class _NewCategory extends _CategoryChoice {
  const _NewCategory();

  @override
  bool operator ==(Object other) => other is _NewCategory;

  @override
  int get hashCode => 1;
}

class _Existing extends _CategoryChoice {
  const _Existing(this.name);

  final String name;

  // Compared by name, because the dropdown matches its value against the
  // items by equality and they are rebuilt on every frame.
  @override
  bool operator ==(Object other) => other is _Existing && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
