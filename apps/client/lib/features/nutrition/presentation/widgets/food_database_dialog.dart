import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/nutrition.dart';
import '../nutrition_providers.dart';

/// Opens the food database and returns whichever food was chosen, or null.
///
/// The app ships with what is actually eaten here, so this list is worth
/// something on the first day rather than after a month of typing. Anything
/// the catalogue is missing goes in from the same dialog: finding out mid-form
/// that your breakfast is not listed should not mean starting over somewhere
/// else, which is the same reasoning as the exercise picker's "New exercise".
Future<Food?> showFoodDatabase(BuildContext context) => showDialog<Food>(
  context: context,
  builder: (context) => const _FoodDatabaseDialog(),
);

class _FoodDatabaseDialog extends ConsumerStatefulWidget {
  const _FoodDatabaseDialog();

  @override
  ConsumerState<_FoodDatabaseDialog> createState() =>
      _FoodDatabaseDialogState();
}

class _FoodDatabaseDialogState extends ConsumerState<_FoodDatabaseDialog> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Folded to lower case on both sides, the same fold the unique index uses,
  /// so searching for "noquis" behaves the way searching for "Ñoquis" does.
  List<Food> _matching(List<Food> foods) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return foods;

    return foods.where((f) => f.name.toLowerCase().contains(query)).toList();
  }

  Future<void> _create() async {
    final food = await showFoodDefinitionForm(context);
    if (food == null || !mounted) return;

    await ref.read(nutritionActionsProvider).saveFood(food);
  }

  Future<void> _edit(Food food) async {
    final edited = await showFoodDefinitionForm(
      context,
      existing: food,
      onDelete: () => ref.read(nutritionActionsProvider).deleteFood(food.id),
    );
    if (edited == null || !mounted) return;

    await ref.read(nutritionActionsProvider).saveFood(edited);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final foods = ref.watch(nutritionFoodsProvider);

    return AlertDialog(
      title: Text(l10n.nutritionFoodDatabase),
      content: SizedBox(
        width: 460,
        // Fixed, because the list is long enough to want a scrollbar and a
        // dialog that resizes as the search narrows it jumps under the finger.
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.nutritionFoodSearch,
                prefixIcon: const Icon(Icons.search),
              ),
              // Eighty foods in a plain list is a list nobody reads. The
              // search is the way in, so it filters as it is typed.
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Gap.sm),
            Expanded(
              child: foods.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(
                  '$error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                data: (data) {
                  final matches = _matching(data);
                  if (matches.isEmpty) {
                    return Center(child: Text(l10n.nutritionFoodNone));
                  }

                  return ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) => _FoodRow(
                      food: matches[index],
                      l10n: l10n,
                      onEdit: () => _edit(matches[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton.icon(
          onPressed: _create,
          icon: const Icon(Icons.add),
          label: Text(l10n.nutritionFoodNew),
        ),
      ],
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.food,
    required this.l10n,
    required this.onEdit,
  });

  final Food food;
  final AppLocalizations l10n;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Flexible(child: Text(food.name, overflow: TextOverflow.ellipsis)),
          // Only what the user wrote down is marked. Tagging the eighty
          // shipped foods instead would put a badge on almost every row,
          // which says nothing.
          if (!food.isBuiltIn) ...[
            const SizedBox(width: Gap.sm),
            Text(
              l10n.nutritionFoodMine,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(l10n.nutritionPer100g(food.per100g.calories)),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 20),
        tooltip: l10n.nutritionFoodEdit,
        onPressed: onEdit,
      ),
      onTap: () => Navigator.of(context).pop(food),
    );
  }
}

/// Describes one food for the database. Returns null when dismissed.
///
/// Everything is asked for per 100 g, and the labels say so, because a figure
/// quoted against an unstated weight is the exact mistake the food database
/// exists to stop making.
Future<Food?> showFoodDefinitionForm(
  BuildContext context, {
  Food? existing,
  Future<void> Function()? onDelete,
}) => showDialog<Food>(
  context: context,
  builder: (context) =>
      _FoodDefinitionDialog(existing: existing, onDelete: onDelete),
);

class _FoodDefinitionDialog extends StatefulWidget {
  const _FoodDefinitionDialog({this.existing, this.onDelete});

  final Food? existing;
  final Future<void> Function()? onDelete;

  @override
  State<_FoodDefinitionDialog> createState() => _FoodDefinitionDialogState();
}

class _FoodDefinitionDialogState extends State<_FoodDefinitionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _calories = _number(widget.existing?.per100g.calories);
  late final _protein = _number(widget.existing?.per100g.protein);
  late final _carbs = _number(widget.existing?.per100g.carbs);
  late final _fat = _number(widget.existing?.per100g.fat);

  TextEditingController _number(int? value) =>
      TextEditingController(text: value == null || value == 0 ? '' : '$value');

  @override
  void dispose() {
    for (final c in [_name, _calories, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  int _read(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      Food(
        // Zero is a food the database does not have yet; anything else is a
        // correction to the row that id belongs to.
        id: widget.existing?.id ?? 0,
        name: _name.text,
        per100g: Macros(
          calories: _read(_calories),
          protein: _read(_protein),
          carbs: _read(_carbs),
          fat: _read(_fat),
        ),
        isBuiltIn: widget.existing?.isBuiltIn ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: DialogTitle(
        text: widget.existing == null
            ? l10n.nutritionFoodNew
            : l10n.nutritionFoodEdit,
        deleteLabel: widget.existing?.name,
        // Deleting a food takes nothing with it, and the confirmation says so
        // rather than leaving the user to wonder whether last month's lunches
        // go with it. The opposite case — a movement, which does carry every
        // day it was scheduled on — is worded the other way for the same
        // reason: the user is told what actually happens.
        deleteBody: l10n.nutritionFoodDeleteBody,
        onDelete: widget.onDelete,
      ),
      content: SizedBox(
        width: 420,
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
                  decoration: InputDecoration(labelText: l10n.fieldName),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.validationNameRequired
                      : null,
                ),
                const SizedBox(height: Gap.sm),
                Text(
                  l10n.nutritionPer100gLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: Gap.sm),
                _MacroField(
                  controller: _calories,
                  label: l10n.nutritionCalories,
                  suffix: 'kcal',
                  max: 2000,
                ),
                const SizedBox(height: Gap.md),
                Row(
                  children: [
                    Expanded(
                      child: _MacroField(
                        controller: _protein,
                        label: l10n.nutritionProtein,
                        suffix: 'g',
                        max: 100,
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: _MacroField(
                        controller: _carbs,
                        label: l10n.nutritionCarbs,
                        suffix: 'g',
                        max: 100,
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: _MacroField(
                        controller: _fat,
                        label: l10n.nutritionFat,
                        suffix: 'g',
                        max: 100,
                      ),
                    ),
                  ],
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

/// A whole number field that treats blank as zero.
///
/// The ceilings are tighter than the entry form's on purpose: these are
/// figures for 100 g of something, and 100 g cannot hold more than 100 g of
/// protein. A field that accepts 2000 g of fat per 100 g of food accepts a
/// typo that then multiplies through every portion ever weighed against it.
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
