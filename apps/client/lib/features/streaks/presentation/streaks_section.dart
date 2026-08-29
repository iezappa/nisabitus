import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/name_prompt_dialog.dart';
import '../../../l10n/app_localizations.dart';
import 'streak_providers.dart';
import 'widgets/streak_card.dart';

/// The streaks band that sits above the habit list, per the spec's layout
/// where one tab holds both modules.
class StreaksSection extends ConsumerWidget {
  const StreaksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final streaks = ref.watch(streaksProvider);
    final actions = ref.read(streakActionsProvider);

    Future<void> createStreak() async {
      final name = await promptForName(context, title: l10n.streakNew);
      if (name != null) await actions.create(name);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Text(l10n.streaksTitle, style: theme.textTheme.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.streakNew,
                onPressed: createStreak,
              ),
            ],
          ),
        ),
        streaks.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('$error', style: TextStyle(color: theme.colorScheme.error)),
          ),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.local_fire_department_outlined,
                  title: l10n.streaksEmpty,
                  hint: l10n.streaksEmptyHint,
                )
              : SizedBox(
                  height: 196,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final streak = items[index];
                      return SizedBox(
                        width: 220,
                        child: StreakCard(
                          streak: streak,
                          onIncrement: () => actions.increment(streak.id),
                          onReset: () => actions.reset(streak.id),
                          onDelete: () async {
                            if (await confirmDelete(context, streak.name)) {
                              await actions.delete(streak.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
