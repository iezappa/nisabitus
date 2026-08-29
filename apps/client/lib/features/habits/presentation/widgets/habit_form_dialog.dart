import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/habit.dart';
import '../../domain/habit_draft.dart';
import '../../domain/habit_frequency.dart';
import '../habit_labels.dart';

/// Collects the fields of a habit. Returns null when dismissed.
Future<HabitDraft?> showHabitForm(
  BuildContext context, {
  Habit? existing,
  HabitFrequency initialFrequency = HabitFrequency.daily,
}) => showDialog<HabitDraft>(
  context: context,
  builder: (context) => _HabitFormDialog(
    existing: existing,
    initialFrequency: initialFrequency,
  ),
);

class _HabitFormDialog extends StatefulWidget {
  const _HabitFormDialog({
    required this.existing,
    required this.initialFrequency,
  });

  final Habit? existing;
  final HabitFrequency initialFrequency;

  @override
  State<_HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<_HabitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
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
    _category = TextEditingController(text: existing?.category ?? '');
    _target = TextEditingController(text: '${existing?.targetCount ?? 1}');
    _frequency = existing?.frequency ?? widget.initialFrequency;
    _repeatDays = {...?existing?.repeatDays};
    _repeatForever = existing?.repeatForever ?? false;
    _endDate = existing?.endDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _target.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      HabitDraft(
        name: _name.text,
        category: _category.text.trim().isEmpty ? null : _category.text.trim(),
        frequency: _frequency,
        targetCount: int.tryParse(_target.text) ?? 1,
        endDate: _endDate,
        repeatForever: _repeatForever,
        // Weekdays only mean something for daily and weekly habits.
        repeatDays: _frequency.supportsRepeatDays ? _repeatDays : const {},
      ),
    );
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
      title: Text(widget.existing == null ? l10n.habitNew : l10n.habitEdit),
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
                  controller: _category,
                  decoration: InputDecoration(labelText: l10n.fieldCategory),
                  maxLength: 255,
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
                  _WeekdayPicker(
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
class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onChanged});

  final Set<Weekday> selected;
  final ValueChanged<Set<Weekday>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: 6,
      children: [
        for (final day in Weekday.values)
          ChoiceChip(
            shape: const CircleBorder(),
            showCheckmark: false,
            label: SizedBox(
              width: 16,
              child: Center(
                child: Text(
                  l10n.weekdayShort(day),
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ),
            selected: selected.contains(day),
            onSelected: (isSelected) => onChanged({
              ...selected,
              if (isSelected) day,
            }..removeWhere((value) => !isSelected && value == day)),
          ),
      ],
    );
  }
}
