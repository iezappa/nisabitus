import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/hydration.dart';
import 'hydration_providers.dart';
import 'widgets/amount_form_dialog.dart';

/// The hydration part of the health section: the target on top, the glasses
/// underneath.
class HydrationView extends ConsumerWidget {
  const HydrationView({super.key});

  /// The sizes offered as one tap each.
  ///
  /// A glass, a mug and a bottle — the three things people actually drink
  /// out of. Anything else goes through [showAmountForm], because a row of
  /// twelve buttons is slower to read than a keyboard.
  static const quickAmounts = [200, 350, 500];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final day = ref.watch(hydrationDayProvider);
    final actions = ref.read(hydrationActionsProvider);

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
            label: l10n.hydrationTarget,
            trailing: IconButton(
              icon: const Icon(Icons.tune, size: 20),
              tooltip: l10n.hydrationEditTarget,
              onPressed: () async {
                final millilitres = await showAmountForm(
                  context,
                  title: l10n.hydrationEditTarget,
                  max: 20000,
                  initial: data.goal.millilitres,
                );
                if (millilitres != null) {
                  await actions.saveGoal(
                    HydrationGoal(millilitres: millilitres),
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: _TargetCard(day: data),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
            child: _QuickAdd(onAdd: actions.add),
          ),
          SectionHeader(label: l10n.hydrationToday),
          if (data.isEmpty)
            EmptyState(
              icon: Icons.water_drop_outlined,
              title: l10n.hydrationEmpty,
              hint: l10n.hydrationEmptyHint,
            )
          else
            for (final entry in data.entries)
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.water_drop_outlined),
                    title: Text(l10n.hydrationMillilitres(entry.millilitres)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.actionDelete,
                      onPressed: () => actions.delete(entry.id),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// One tap per size, and a way out for everything else.
class _QuickAdd extends StatelessWidget {
  const _QuickAdd({required this.onAdd});

  final Future<void> Function(int millilitres) onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: Gap.sm,
      runSpacing: Gap.sm,
      children: [
        for (final amount in HydrationView.quickAmounts)
          FilledButton.tonalIcon(
            onPressed: () => onAdd(amount),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.hydrationMillilitres(amount)),
          ),
        OutlinedButton(
          onPressed: () async {
            final millilitres = await showAmountForm(
              context,
              title: l10n.hydrationCustom,
              max: WaterEntry.maxMillilitres,
            );
            if (millilitres != null) await onAdd(millilitres);
          },
          child: Text(l10n.hydrationCustom),
        ),
      ],
    );
  }
}

/// The day's total against the target.
class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.day});

  final DailyHydration day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final left = day.remaining;

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
                  '${day.total}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: Gap.xs),
                Text(
                  '/ ${l10n.hydrationMillilitres(day.goal.millilitres)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            Text(
              // Reaching the target is said out loud. Drinking more than it
              // is not scolded: this is a log, not a nurse.
              left > 0 ? l10n.hydrationRemaining(left) : l10n.hydrationReached,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Gap.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(Gap.xs),
              child: LinearProgressIndicator(
                value: day.ratio,
                minHeight: Gap.sm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
