import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/time/selected_day_provider.dart';
import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/week_date_selector.dart';
import '../../../l10n/app_localizations.dart';
import 'meditation_progress_view.dart';
import 'meditation_providers.dart';
import 'widgets/meditation_form_dialog.dart';

/// The Meditación tab: what was sat on one day, and what the practice looks
/// like over a window.
///
/// It records a sitting, it does not run one. A timer would make the app
/// something to look at while meditating, which is the opposite of the point
/// — and it would leave anyone who sat without it unable to write it down.
class MeditationScreen extends ConsumerWidget {
  const MeditationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedDayProvider);
    final actions = ref.read(meditationActionsProvider);

    return ModuleScaffold(
      title: l10n.meditationTitle,
      header: WeekDateSelector(
        selected: selected,
        today: ref.watch(todayProvider),
        onSelected: (day) => ref.read(selectedDayProvider.notifier).state = day,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.meditationAdd,
        onPressed: () async {
          final draft = await showMeditationForm(context);
          if (draft != null) await actions.add(draft);
        },
        child: const Icon(Icons.add),
      ),
      list: const _Day(),
      progress: const MeditationProgressView(),
    );
  }
}

/// What was sat on the day the strip is pointing at.
class _Day extends ConsumerWidget {
  const _Day();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(meditationActionsProvider);

    return AsyncSection(
      value: ref.watch(meditationDayProvider),
      builder: (day) => ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          SectionHeader(
            label: l10n.meditationToday,
            trailing: day.isEmpty
                ? null
                : Text(
                    l10n.meditationDayTotal(day.minutes),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
          ),
          if (day.isEmpty)
            EmptyState(
              icon: Icons.self_improvement_outlined,
              title: l10n.meditationEmpty,
              hint: l10n.meditationEmptyHint,
            )
          else
            for (final session in day.sessions)
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.self_improvement_outlined),
                    title: Text(l10n.meditationMinutes(session.minutes)),
                    subtitle: session.note == null ? null : Text(session.note!),
                    onTap: () async {
                      final draft = await showMeditationForm(
                        context,
                        existing: session,
                        onDelete: () => actions.delete(session.id),
                      );
                      if (draft != null) {
                        await actions.update(session.id, draft);
                      }
                    },
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
