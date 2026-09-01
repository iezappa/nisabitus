import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/nutrition.dart';
import '../../domain/nutrition_repository.dart';

/// Collects one food entry. Returns null when dismissed.
Future<FoodDraft?> showFoodForm(
  BuildContext context, {
  FoodEntry? existing,
  Future<void> Function()? onDelete,
}) => showDialog<FoodDraft>(
  context: context,
  builder: (context) => _FoodFormDialog(existing: existing, onDelete: onDelete),
);

class _FoodFormDialog extends StatefulWidget {
  const _FoodFormDialog({this.existing, this.onDelete});

  final FoodEntry? existing;
  final Future<void> Function()? onDelete;

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
