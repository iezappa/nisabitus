import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/meal.dart';
import '../domain/nutrition.dart';
import 'nutrition_labels.dart';
import 'nutrition_providers.dart';
import 'widgets/food_form_dialog.dart';
import 'widgets/goal_form_dialog.dart';

/// The nutrition half of the health section: targets on top, the day's food
/// underneath.
class NutritionView extends ConsumerWidget {
  const NutritionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final day = ref.watch(nutritionDayProvider);
    final actions = ref.read(nutritionActionsProvider);

    return day.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          '$error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (data) => ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          SectionHeader(
            label: l10n.nutritionGoals,
            trailing: IconButton(
              icon: const Icon(Icons.tune, size: 20),
              tooltip: l10n.nutritionEditGoals,
              onPressed: () async {
                final goal = await showGoalForm(context, existing: data.goal);
                if (goal != null) await actions.saveGoal(goal);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: _GoalCard(day: data),
          ),
          SectionHeader(
            label: l10n.nutritionToday,
            trailing: IconButton(
              icon: const Icon(Icons.add, size: 20),
              tooltip: l10n.nutritionAdd,
              onPressed: () async {
                final draft = await showFoodForm(
                  context,
                  // The clock is read here rather than inside the dialog:
                  // a dialog that reads the clock is a dialog that cannot be
                  // photographed the same way twice.
                  initialMeal: Meal.forHour(DateTime.now().hour),
                );
                if (draft != null) await actions.add(draft);
              },
            ),
          ),
          if (data.isEmpty)
            EmptyState(
              icon: Icons.restaurant_outlined,
              title: l10n.nutritionEmpty,
              hint: l10n.nutritionEmptyHint,
            )
          else ...[
            // One heading per meal, in the order the day happens. A meal
            // nothing was eaten at is absent rather than empty: four headings
            // over three empty lists describe a form to fill in, not a day
            // that was lived.
            for (final group in data.byMeal.entries) ...[
              _MealHeading(meal: group.key, entries: group.value),
              for (final entry in group.value)
                _EntryCard(entry: entry, actions: actions),
            ],
            // Everything logged before the app asked which meal it was. It
            // still counts towards the totals above; it just cannot say when
            // it was eaten, and pretending otherwise would invent the answer.
            if (data.unassigned.isNotEmpty) ...[
              _MealHeading(meal: null, entries: data.unassigned),
              for (final entry in data.unassigned)
                _EntryCard(entry: entry, actions: actions),
            ],
          ],
        ],
      ),
    );
  }
}

/// The name of a meal, with what it added up to on the right.
class _MealHeading extends StatelessWidget {
  const _MealHeading({required this.meal, required this.entries});

  final Meal? meal;
  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final calories = entries.fold(
      0,
      (sum, entry) => sum + entry.macros.calories,
    );

    return SectionHeader(
      label: l10n.mealHeading(meal),
      trailing: Text(
        l10n.nutritionKcal(calories),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// One thing eaten, and the way back into the form that wrote it.
class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.actions});

  final FoodEntry entry;
  final NutritionActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
      child: Card(
        child: ListTile(
          title: Text(entry.name),
          subtitle: Text(
            [
              ?entry.portion,
              l10n.nutritionKcal(entry.macros.calories),
              'P ${entry.macros.protein}',
              'C ${entry.macros.carbs}',
              'G ${entry.macros.fat}',
            ].join(' · '),
          ),
          onTap: () async {
            final draft = await showFoodForm(
              context,
              existing: entry,
              onDelete: () => actions.delete(entry.id),
            );
            if (draft != null) await actions.update(entry.id, draft);
          },
        ),
      ),
    );
  }
}

/// The day's totals against the targets, one bar per macro.
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.day});

  final DailyNutrition day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final left = day.caloriesRemaining;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${day.total.calories}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: Gap.xs),
                Text(
                  '/ ${l10n.nutritionKcal(day.goal.calories)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            Text(
              // Going over is stated plainly rather than hidden: the number
              // is the point, and a negative remainder is information.
              left >= 0
                  ? l10n.nutritionRemaining(left)
                  : l10n.nutritionOver(-left),
              style: theme.textTheme.bodySmall?.copyWith(
                color: left >= 0
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: Gap.lg),
            _MacroBar(
              label: l10n.nutritionProtein,
              value: day.total.protein,
              target: day.goal.protein,
              ratio: day.proteinRatio,
            ),
            const SizedBox(height: Gap.md),
            _MacroBar(
              label: l10n.nutritionCarbs,
              value: day.total.carbs,
              target: day.goal.carbs,
              ratio: day.carbsRatio,
            ),
            const SizedBox(height: Gap.md),
            _MacroBar(
              label: l10n.nutritionFat,
              value: day.total.fat,
              target: day.goal.fat,
              ratio: day.fatRatio,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.value,
    required this.target,
    required this.ratio,
  });

  final String label;
  final int value;
  final int target;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall,
              ),
            ),
            Text(
              '${l10n.nutritionGrams(value)} / ${l10n.nutritionGrams(target)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: Gap.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
