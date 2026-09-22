import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../audio/domain/audio_track.dart';
import '../../audio/presentation/widgets/audio_track_section.dart';
import 'meditation_providers.dart';
import 'widgets/meditation_form_dialog.dart';

/// The meditation part of the health section: what was sat on the chosen day.
///
/// It records a sitting, it does not run one. A timer would make the app
/// something to look at while meditating, which is the opposite of the point
/// — and it would leave anyone who sat without it unable to write it down.
///
/// Adding goes in the section header rather than on a floating button, as it
/// does in every other view under this tab: the button would float over
/// whichever sub-tab happened to be open and offer to write down a sitting
/// while the user was reading about sleep.
///
/// The audio library sits under the day rather than over it. The record is
/// what the tab is for; the bell or the guided track is what the user
/// reaches for once, at the start, and then stops looking at.
class MeditationView extends ConsumerWidget {
  const MeditationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(meditationActionsProvider);

    return AsyncSection(
      value: ref.watch(meditationDayProvider),
      builder: (day) => ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          SectionHeader(
            label: l10n.meditationToday,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!day.isEmpty)
                  Text(
                    l10n.meditationDayTotal(day.minutes),
                    style: theme.textTheme.bodySmall,
                  ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: l10n.meditationAdd,
                  onPressed: () async {
                    final draft = await showMeditationForm(context);
                    if (draft != null) await actions.add(draft);
                  },
                ),
              ],
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
          const SizedBox(height: Gap.lg),
          AudioTrackSection(
            usage: TrackUsage.meditation,
            title: l10n.meditationSound,
          ),
        ],
      ),
    );
  }
}
