import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/nutrition.dart';

/// Collects the daily macro targets. Returns null when dismissed.
Future<NutritionGoal?> showGoalForm(
  BuildContext context, {
  required NutritionGoal existing,
}) => showDialog<NutritionGoal>(
  context: context,
  builder: (context) => _GoalFormDialog(existing: existing),
);

class _GoalFormDialog extends StatefulWidget {
  const _GoalFormDialog({required this.existing});

  final NutritionGoal existing;

  @override
  State<_GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<_GoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _calories = TextEditingController(
    text: '${widget.existing.calories}',
  );
  late final _protein = TextEditingController(
    text: '${widget.existing.protein}',
  );
  late final _carbs = TextEditingController(text: '${widget.existing.carbs}');
  late final _fat = TextEditingController(text: '${widget.existing.fat}');

  @override
  void dispose() {
    for (final c in [_calories, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      NutritionGoal(
        calories: int.parse(_calories.text),
        protein: int.parse(_protein.text),
        carbs: int.parse(_carbs.text),
        fat: int.parse(_fat.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.nutritionEditGoals),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Target(
                controller: _calories,
                label: l10n.nutritionCalories,
                suffix: 'kcal',
              ),
              const SizedBox(height: Gap.md),
              _Target(
                controller: _protein,
                label: l10n.nutritionProtein,
                suffix: 'g',
              ),
              const SizedBox(height: Gap.md),
              _Target(
                controller: _carbs,
                label: l10n.nutritionCarbs,
                suffix: 'g',
              ),
              const SizedBox(height: Gap.md),
              _Target(controller: _fat, label: l10n.nutritionFat, suffix: 'g'),
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

class _Target extends StatelessWidget {
  const _Target({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (value) {
        final parsed = int.tryParse((value ?? '').trim());
        return parsed == null || parsed < 0 || parsed > 20000
            ? l10n.nutritionValidationNumber(20000)
            : null;
      },
    );
  }
}
