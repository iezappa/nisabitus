import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/journal_content.dart';

/// The six fields of the entry for the selected day.
///
/// The whole form is one value: it is saved or replaced as a unit, so the
/// state lives here and leaves as a single [JournalContent].
class JournalForm extends StatefulWidget {
  const JournalForm({
    required this.initial,
    required this.hasEntry,
    required this.onSave,
    required this.onDelete,
    super.key,
  });

  final JournalContent initial;
  final bool hasEntry;
  final ValueChanged<JournalContent> onSave;
  final VoidCallback onDelete;

  @override
  State<JournalForm> createState() => _JournalFormState();
}

class _JournalFormState extends State<JournalForm> {
  late final _mood = TextEditingController(text: widget.initial.mood);
  late final _gratitude = TextEditingController(text: widget.initial.gratitude);
  late final _focus = TextEditingController(text: widget.initial.focus);
  late final _reflection = TextEditingController(
    text: widget.initial.reflection,
  );
  late final _intention = TextEditingController(text: widget.initial.intention);

  late EnergyLevel? _energy = widget.initial.energy;
  bool _justSaved = false;

  @override
  void didUpdateWidget(JournalForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The strip moved to another day, so the fields follow that day's entry.
    if (oldWidget.initial != widget.initial) {
      _mood.text = widget.initial.mood;
      _gratitude.text = widget.initial.gratitude;
      _focus.text = widget.initial.focus;
      _reflection.text = widget.initial.reflection;
      _intention.text = widget.initial.intention;
      setState(() {
        _energy = widget.initial.energy;
        _justSaved = false;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _mood,
      _gratitude,
      _focus,
      _reflection,
      _intention,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    widget.onSave(
      JournalContent(
        mood: _mood.text,
        energy: _energy,
        gratitude: _gratitude.text,
        focus: _focus.text,
        reflection: _reflection.text,
        intention: _intention.text,
      ),
    );
    setState(() => _justSaved = true);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Field(
              controller: _mood,
              label: l10n.journalMood,
              hint: l10n.journalMoodHint,
            ),
            const SizedBox(height: Gap.lg),
            Text(
              l10n.journalEnergy.toUpperCase(),
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: Gap.sm),
            _EnergyPicker(
              value: _energy,
              // Tapping the chosen level again clears it: the spec allows the
              // field to stay empty.
              onChanged: (value) =>
                  setState(() => _energy = _energy == value ? null : value),
            ),
            const SizedBox(height: Gap.lg),
            _Field(
              controller: _gratitude,
              label: l10n.journalGratitude,
              hint: l10n.journalGratitudeHint,
              lines: 2,
            ),
            const SizedBox(height: Gap.lg),
            _Field(
              controller: _focus,
              label: l10n.journalFocus,
              hint: l10n.journalFocusHint,
              lines: 2,
            ),
            const SizedBox(height: Gap.lg),
            _Field(
              controller: _reflection,
              label: l10n.journalReflection,
              hint: l10n.journalReflectionHint,
              lines: 6,
            ),
            const SizedBox(height: Gap.lg),
            _Field(
              controller: _intention,
              label: l10n.journalIntention,
              hint: l10n.journalIntentionHint,
              lines: 2,
            ),
            const SizedBox(height: Gap.lg),
            Row(
              children: [
                if (_justSaved)
                  Padding(
                    padding: const EdgeInsets.only(right: Gap.md),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: Gap.xs),
                        Text(
                          l10n.journalSaved,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (widget.hasEntry)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.actionDelete,
                    onPressed: widget.onDelete,
                  ),
                const SizedBox(width: Gap.sm),
                FilledButton(
                  onPressed: _submit,
                  child: Text(
                    widget.hasEntry ? l10n.journalUpdate : l10n.journalSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.lines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int lines;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    minLines: lines,
    maxLines: lines == 1 ? 1 : lines + 4,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(labelText: label, hintText: hint),
  );
}

class _EnergyPicker extends StatelessWidget {
  const _EnergyPicker({required this.value, required this.onChanged});

  final EnergyLevel? value;
  final ValueChanged<EnergyLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    String label(EnergyLevel level) => switch (level) {
      EnergyLevel.low => l10n.journalEnergyLow,
      EnergyLevel.medium => l10n.journalEnergyMedium,
      EnergyLevel.high => l10n.journalEnergyHigh,
    };

    return Wrap(
      spacing: Gap.sm,
      children: [
        for (final level in EnergyLevel.values)
          ChoiceChip(
            label: Text(label(level)),
            selected: value == level,
            onSelected: (_) => onChanged(level),
          ),
      ],
    );
  }
}
