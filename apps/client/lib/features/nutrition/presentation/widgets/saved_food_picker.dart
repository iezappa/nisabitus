import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/nutrition.dart';
import '../nutrition_providers.dart';

/// Picks something already eaten before. Returns null when dismissed.
///
/// The list is the whole point of the catalogue: eating the same breakfast
/// twice should be picking it the second time, not typing it again. Nothing
/// here is maintained by hand — every entry saved files itself.
Future<Food?> showSavedFoodPicker(BuildContext context) => showDialog<Food>(
  context: context,
  builder: (context) => const _SavedFoodPicker(),
);

class _SavedFoodPicker extends ConsumerWidget {
  const _SavedFoodPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final foods = ref.watch(nutritionFoodsProvider);

    return AlertDialog(
      title: Text(l10n.nutritionSaved),
      content: SizedBox(
        width: 420,
        child: foods.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(
            '$error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          data: (data) => data.isEmpty
              ? _Empty(l10n: l10n)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: data.length,
                  itemBuilder: (context, index) =>
                      _FoodRow(food: data[index], l10n: l10n),
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xl),
      child: Column(
        children: [
          Text(l10n.nutritionSavedEmpty, style: theme.textTheme.titleSmall),
          const SizedBox(height: Gap.xs),
          Text(
            l10n.nutritionSavedHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodRow extends ConsumerWidget {
  const _FoodRow({required this.food, required this.l10n});

  final Food food;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = [
      if (food.portion != null) food.portion!,
      l10n.nutritionKcal(food.macros.calories),
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(food.name),
      subtitle: Text(subtitle),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        // Only the catalogue row goes. What was already eaten is a record of
        // a day, and tidying a list must not rewrite it.
        tooltip: l10n.nutritionForget,
        onPressed: () => ref.read(nutritionActionsProvider).forgetFood(food.id),
      ),
      onTap: () => Navigator.of(context).pop(food),
    );
  }
}
