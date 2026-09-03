import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/meal.dart';
import '../../domain/nutrition.dart';
import '../../domain/nutrition_repository.dart';
import '../nutrition_labels.dart';
import 'saved_food_picker.dart';

/// Collects one food entry. Returns null when dismissed.
///
/// [initialMeal] is which meal a new entry starts on. It is asked for rather
/// than worked out here because working it out means reading the clock, and a
/// dialog that reads the clock cannot be photographed: the same screenshot
/// comes out different depending on the hour the test happened to run.
Future<FoodDraft?> showFoodForm(
  BuildContext context, {
  FoodEntry? existing,
  Future<void> Function()? onDelete,
  Meal? initialMeal,
}) => showDialog<FoodDraft>(
  context: context,
  builder: (context) => _FoodFormDialog(
    existing: existing,
    onDelete: onDelete,
    initialMeal: initialMeal,
  ),
);

class _FoodFormDialog extends StatefulWidget {
  const _FoodFormDialog({this.existing, this.onDelete, this.initialMeal});

  final FoodEntry? existing;
  final Future<void> Function()? onDelete;
  final Meal? initialMeal;

  @override
  State<_FoodFormDialog> createState() => _FoodFormDialogState();
}

class _FoodFormDialogState extends State<_FoodFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _portion = TextEditingController(
    text: widget.existing?.portion ?? '',
  );
  late final _calories = _number(widget.existing?.macros.calories);
  late final _protein = _number(widget.existing?.macros.protein);
  late final _carbs = _number(widget.existing?.macros.carbs);
  late final _fat = _number(widget.existing?.macros.fat);

  /// An existing entry starts on whatever it was filed under, a new one on
  /// what the caller suggested. Only a starting point: the common case is
  /// writing down what you are eating right now, and that case should need no
  /// answer at all.
  late Meal? _meal = widget.existing?.meal ?? widget.initialMeal;

  TextEditingController _number(int? value) =>
      TextEditingController(text: value == null || value == 0 ? '' : '$value');

  @override
  void dispose() {
    for (final c in [_name, _portion, _calories, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  int _read(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  Future<void> _pickSaved() async {
    final food = await showSavedFoodPicker(context);
    if (food == null || !mounted) return;

    setState(() {
      _name.text = food.name;
      _portion.text = food.portion ?? '';
      _calories.text = _text(food.macros.calories);
      _protein.text = _text(food.macros.protein);
      _carbs.text = _text(food.macros.carbs);
      _fat.text = _text(food.macros.fat);
    });
  }

  /// Zero reads as blank, the same way the fields started: a food logged
  /// without its fat known should not come back claiming zero grams of it.
  String _text(int value) => value == 0 ? '' : '$value';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      FoodDraft(
        name: _name.text,
        portion: _portion.text.trim().isEmpty ? null : _portion.text.trim(),
        macros: Macros(
          calories: _read(_calories),
          protein: _read(_protein),
          carbs: _read(_carbs),
          fat: _read(_fat),
        ),
        meal: _meal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: DialogTitle(
        text: widget.existing == null
            ? l10n.nutritionAdd
            : l10n.nutritionEditEntry,
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
                // Only offered on a new entry: editing one is correcting
                // what was written, and a button that overwrites the whole
                // form is not a correction.
                if (widget.existing == null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _pickSaved,
                      icon: const Icon(Icons.history),
                      label: Text(l10n.nutritionPickSaved),
                    ),
                  ),
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
                  controller: _portion,
                  maxLength: 255,
                  decoration: InputDecoration(
                    labelText: l10n.nutritionPortion,
                    hintText: l10n.nutritionPortionHint,
                  ),
                ),
                const SizedBox(height: Gap.sm),
                _MacroField(
                  controller: _calories,
                  label: l10n.nutritionCalories,
                  suffix: 'kcal',
                  max: 20000,
                ),
                const SizedBox(height: Gap.md),
                Row(
                  children: [
                    Expanded(
                      child: _MacroField(
                        controller: _protein,
                        label: l10n.nutritionProtein,
                        suffix: 'g',
                        max: 2000,
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: _MacroField(
                        controller: _carbs,
                        label: l10n.nutritionCarbs,
                        suffix: 'g',
                        max: 2000,
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: _MacroField(
                        controller: _fat,
                        label: l10n.nutritionFat,
                        suffix: 'g',
                        max: 2000,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.xl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.nutritionMeal,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: Gap.sm),
                _MealPicker(
                  selected: _meal,
                  onChanged: (meal) => setState(() => _meal = meal),
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

/// Which meal the entry belongs to, or none.
///
/// `emptySelectionAllowed`, because "I do not know which meal this was" has
/// to be sayable — every entry written before the app asked is in exactly
/// that state, and editing one must not force an answer onto it.
class _MealPicker extends StatelessWidget {
  const _MealPicker({required this.selected, required this.onChanged});

  final Meal? selected;
  final ValueChanged<Meal?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SegmentedButton<Meal>(
      showSelectedIcon: false,
      emptySelectionAllowed: true,
      segments: [
        for (final meal in Meal.values)
          ButtonSegment(value: meal, label: Text(l10n.mealName(meal))),
      ],
      selected: {?selected},
      onSelectionChanged: (selection) =>
          onChanged(selection.isEmpty ? null : selection.first),
    );
  }
}

/// A whole number field that treats blank as zero.
///
/// Logging a food without knowing its fat is normal; forcing a zero in
/// would make the form argue about something the user does not know.
class _MacroField extends StatelessWidget {
  const _MacroField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) return null;

        final parsed = int.tryParse(text);
        return parsed == null || parsed < 0 || parsed > max
            ? l10n.nutritionValidationNumber(max)
            : null;
      },
    );
  }
}
