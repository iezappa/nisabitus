import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/food_portion.dart';
import '../../domain/meal.dart';
import '../../domain/nutrition.dart';
import '../../domain/nutrition_repository.dart';
import '../nutrition_labels.dart';
import 'food_database_dialog.dart';

/// What the form hands back: the entry, and whether to keep the combination.
///
/// A record rather than a flag on [FoodDraft], because "also file this as a
/// dish" is something the user asked the form to do, not a property of what
/// was eaten. The draft describes the plate; this says what else to do about
/// it.
typedef FoodFormResult = ({FoodDraft draft, bool saveAsDish});

/// Collects one food entry. Returns null when dismissed.
///
/// [initialMeal] is which meal a new entry starts on. It is asked for rather
/// than worked out here because working it out means reading the clock, and a
/// dialog that reads the clock cannot be photographed: the same screenshot
/// comes out different depending on the hour the test happened to run.
Future<FoodFormResult?> showFoodForm(
  BuildContext context, {
  FoodEntry? existing,
  Future<void> Function()? onDelete,
  Meal? initialMeal,
}) => showDialog<FoodFormResult>(
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

  /// What the plate is made of, while the form is open.
  ///
  /// A lunch is often two or three things, so this is a list rather than the
  /// single food it used to be. Only the figures are copied out of each one
  /// — nothing about the saved entry points back at the database, which is
  /// the rule everywhere here: correcting a food today must not rewrite what
  /// last week says was eaten.
  late final List<_Part> _parts = [
    for (final part in widget.existing?.parts ?? const <FoodPart>[])
      _Part(name: part.name, grams: part.grams, per100g: part.per100g),
  ];

  /// Whether to file the combination as a dish of its own on save.
  bool _saveAsDish = false;

  /// Whether the name is still the one this form wrote from the parts.
  ///
  /// Kept so adding a second food can update "Pollo" to "Pollo + Arroz",
  /// while a name the user typed themselves is never touched.
  bool _nameIsOurs = false;

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
    for (final part in _parts) {
      part.dispose();
    }
    super.dispose();
  }

  int _read(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  /// Adds one food from the database to the plate, at 100 g.
  ///
  /// A hundred is the weight the food is quoted for, so the figures that
  /// appear are the ones the database actually holds. Starting at a blank
  /// weight would show a part worth nothing and leave the user to guess.
  ///
  /// Offered while editing too, which the single-food version was not: that
  /// one overwrote the whole form, and a button that wipes what you are
  /// correcting is not a correction. Appending a part overwrites nothing.
  Future<void> _addFromDatabase() async {
    final food = await showFoodDatabase(context);
    if (food == null || !mounted) return;

    setState(() {
      _parts.add(_Part(name: food.name, grams: 100, per100g: food.per100g));
    });
    _recompute();
  }

  void _removePart(int index) {
    setState(() => _parts.removeAt(index).dispose());
    _recompute();
  }

  /// Recomputes what is on screen from the parts.
  ///
  /// It writes into the visible fields rather than into a hidden total: the
  /// user has to be able to SEE what they are about to save, and a form that
  /// adds up invisibly is a form that is trusted until the day it is wrong.
  /// The fields stay editable afterwards, so a figure can still be corrected
  /// by hand — a plate is not always the sum of what went on the scale.
  void _recompute() {
    if (_parts.isEmpty) {
      setState(() => _saveAsDish = false);
      return;
    }

    final parts = _domainParts();
    final total = parts.total;
    final grams = parts.grams;

    setState(() {
      _calories.text = _text(total.calories);
      _protein.text = _text(total.protein);
      _carbs.text = _text(total.carbs);
      _fat.text = _text(total.fat);

      // The portion is free text and stays free text; this only fills it in
      // with what was actually weighed, and it can be typed over.
      if (grams > 0) {
        _portion.text = AppLocalizations.of(context)
            .nutritionGrams(grams.round());
      }

      // A name of our own, until the user writes one. Theirs is never
      // overwritten — see [_nameIsOurs].
      if (_name.text.trim().isEmpty || _nameIsOurs) {
        _name.text = _parts.map((part) => part.name).join(' + ');
        _nameIsOurs = true;
      }

      // Nothing to keep as a dish unless it is a combination that was
      // weighed: one food is already in the database, and a combination with
      // no weight has no reference to be quoted per 100 g against.
      if (_parts.length < 2 || grams <= 0) _saveAsDish = false;
    });
  }

  /// The parts as the domain sees them, dropping any with no usable weight.
  ///
  /// A half-typed weight is not a part worth counting, and it must not take
  /// the running total down with it while someone is mid-keystroke.
  List<FoodPart> _domainParts() => [
    for (final (index, part) in _parts.indexed)
      if (part.weight case final grams?)
        FoodPart(
          id: '$index',
          name: part.name,
          grams: grams,
          per100g: part.per100g,
        ),
  ];

  /// Zero reads as blank, the same way the fields started: a food logged
  /// without its fat known should not come back claiming zero grams of it.
  String _text(int value) => value == 0 ? '' : '$value';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final parts = _domainParts();

    Navigator.of(context).pop((
      draft: FoodDraft(
        name: _name.text,
        portion: _portion.text.trim().isEmpty ? null : _portion.text.trim(),
        macros: Macros(
          calories: _read(_calories),
          protein: _read(_protein),
          carbs: _read(_carbs),
          fat: _read(_fat),
        ),
        meal: _meal,
        parts: [
          for (final part in parts)
            FoodPartDraft(
              name: part.name,
              grams: part.grams,
              per100g: part.per100g,
            ),
        ],
      ),
      saveAsDish: _saveAsDish,
    ));
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
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Composition(
                  parts: _parts,
                  onAdd: _addFromDatabase,
                  onRemove: _removePart,
                  onWeightChanged: _recompute,
                ),
                const SizedBox(height: Gap.md),
                TextFormField(
                  controller: _name,
                  // Typing over the name we wrote from the parts makes it
                  // theirs, and we stop rewriting it.
                  onChanged: (_) => _nameIsOurs = false,
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
                // Only for a real combination that was weighed: one food is
                // already in the database, and a plate with no weight has no
                // reference to be quoted per 100 g against.
                if (_parts.length >= 2 && _domainParts().grams > 0)
                  CheckboxListTile(
                    value: _saveAsDish,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l10n.nutritionSaveAsDish),
                    subtitle: Text(
                      l10n.nutritionSaveAsDishHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onChanged: (value) =>
                        setState(() => _saveAsDish = value ?? false),
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

/// One food on the plate, while the form is open.
///
/// Holds its own weight controller so typing in one part never rebuilds the
/// others out from under the cursor.
class _Part {
  _Part({required this.name, required double grams, required this.per100g})
    : grams = TextEditingController(
        text: grams == grams.roundToDouble() ? '${grams.round()}' : '$grams',
      );

  final String name;
  final TextEditingController grams;

  /// What 100 g of it was made of, copied when it was picked.
  final Macros per100g;

  /// The weight as typed, or null when there is no usable number in it.
  double? get weight => parseGrams(grams.text);

  void dispose() => grams.dispose();
}

/// What the plate is made of: the parts, their weights, and the running sum.
class _Composition extends StatelessWidget {
  const _Composition({
    required this.parts,
    required this.onAdd,
    required this.onRemove,
    required this.onWeightChanged,
  });

  final List<_Part> parts;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onWeightChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.nutritionComposition,
                style: theme.textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.restaurant_menu, size: 18),
              label: Text(l10n.nutritionFoodDatabase),
            ),
          ],
        ),
        if (parts.isEmpty)
          Text(
            l10n.nutritionComposedHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          for (final (index, part) in parts.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(part.name, style: theme.textTheme.bodyMedium),
                        Text(
                          _contribution(context, part),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  SizedBox(
                    width: 112,
                    child: TextFormField(
                      controller: part.grams,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: l10n.nutritionWeight,
                        suffixText: 'g',
                      ),
                      onChanged: (_) => onWeightChanged(),
                      validator: (value) => parseGrams(value ?? '') == null
                          ? l10n.nutritionValidationGrams(
                              maxPortionGrams.toInt(),
                            )
                          : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: l10n.nutritionRemoveFood,
                    onPressed: () => onRemove(index),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  /// What this part is worth at the weight typed, for the line under its name.
  String _contribution(BuildContext context, _Part part) {
    final l10n = AppLocalizations.of(context);
    final grams = part.weight;
    if (grams == null) return '—';

    final macros = scaleMacros(part.per100g, grams);

    return '${l10n.nutritionCalories} ${macros.calories} · '
        'P ${macros.protein} · C ${macros.carbs} · G ${macros.fat}';
  }
}
