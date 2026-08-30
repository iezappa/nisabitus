import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/sleep_log.dart';
import 'sleep_labels.dart';
import 'sleep_providers.dart';
import 'widgets/sleep_log_form.dart';

/// The sleep half of the health section: the night itself.
///
/// The day comes from the week strip the health screen owns, so this view
/// starts at the record. Looking back at the window is the job of
/// [SleepProgressView], behind the module's progress toggle.
class SleepView extends ConsumerWidget {
  const SleepView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final night = ref.watch(sleepForSelectedDayProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: Gap.xxl),
      children: [
        AsyncSection(
          value: night,
          builder: (log) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(label: l10n.sleepLastNight),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                child: _NightCard(log: log),
              ),
              const SizedBox(height: Gap.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                child: SleepLogForm(
                  existingHours: log?.hours,
                  onSave: (hours) => ref.read(sleepActionsProvider).save(hours),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The night the strip is pointing at, with its derived quality.
class _NightCard extends StatelessWidget {
  const _NightCard({required this.log});

  final SleepLog? log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final night = log;

    if (night == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Gap.sm),
          child: _NoRecord(),
        ),
      );
    }

    final color = qualityColor(context, night.quality);

    return Card(
      // Named so tests can tell this figure apart from the average tile,
      // which renders the same string.
      key: const ValueKey('sleep.night-card'),
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.sleepHours(formatHours(night.hours)),
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    l10n.qualityName(night.quality),
                    style: theme.textTheme.bodyMedium?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoRecord extends StatelessWidget {
  const _NoRecord();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return EmptyState(
      icon: Icons.bedtime_outlined,
      title: l10n.sleepNoRecord,
      hint: l10n.sleepNoRecordHint,
    );
  }
}
