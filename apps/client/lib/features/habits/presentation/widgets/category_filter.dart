import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../habit_providers.dart';

/// Narrows the progress side to one category.
///
/// Chips rather than a dropdown: the list is short, the point is to compare
/// one category against the rest at a glance, and a closed menu hides what
/// the user is choosing between. "Todas" is a chip too, so clearing the
/// filter is the same gesture as setting it.
///
/// Renders nothing at all until there are at least two categories. One
/// category is not a choice, and a filter with a single option is a control
/// that can only be wrong.
class CategoryFilter extends ConsumerWidget {
  const CategoryFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(habitCategoriesProvider).valueOrNull;
    if (categories == null || categories.length < 2) {
      return const SizedBox.shrink();
    }

    final selected = ref.watch(habitCategoryFilterProvider);

    void choose(String? category) =>
        ref.read(habitCategoryFilterProvider.notifier).state = category;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
      child: Wrap(
        spacing: Gap.sm,
        runSpacing: Gap.xs,
        children: [
          ChoiceChip(
            label: Text(l10n.habitsAllCategories),
            selected: selected == null,
            onSelected: (_) => choose(null),
          ),
          for (final category in categories)
            ChoiceChip(
              label: Text(category),
              selected: selected == category,
              // Tapping the one already chosen clears it, so the filter can
              // be undone where it was set.
              onSelected: (_) => choose(selected == category ? null : category),
            ),
        ],
      ),
    );
  }
}
