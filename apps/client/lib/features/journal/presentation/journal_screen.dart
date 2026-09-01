import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/time/selected_day_provider.dart';
import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/week_date_selector.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/journal_content.dart';
import '../domain/journal_repository.dart';
import 'journal_progress_view.dart';
import 'journal_providers.dart';
import 'widgets/journal_form.dart';

/// The Journal tab: one structured entry per day, plus what came before.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedDayProvider);

    return ModuleScaffold(
      title: l10n.journalTitle,
      // The strip picks the day being written; it stays put while reviewing
      // so tapping a past entry still lands somewhere visible.
      header: WeekDateSelector(
        selected: selected,
        today: ref.watch(todayProvider),
        onSelected: (day) => ref.read(selectedDayProvider.notifier).state = day,
      ),
      list: const _Entry(),
      progress: const JournalProgressView(),
    );
  }
}

/// The entry for the day the strip is pointing at.
class _Entry extends ConsumerWidget {
  const _Entry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedDayProvider);
    final actions = ref.read(journalActionsProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: Gap.xxl),
      children: [
        SectionHeader(label: l10n.journalEntry),
        AsyncSection(
          value: ref.watch(journalForSelectedDayProvider),
          builder: (value) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: JournalForm(
              // Keyed by day so moving the strip rebuilds the fields from
              // scratch instead of carrying the previous day's text over.
              key: ValueKey(selected),
              initial: value?.content ?? const JournalContent(),
              hasEntry: value != null,
              onSave: actions.save,
              onDelete: () async {
                if (await confirmDelete(context, l10n.journalEntry)) {
                  await actions.delete();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// The past entries of the same window the progress figures use.
///
/// Public because the progress view hangs it under its chart: the numbers
/// and the entries they came from belong on the same side of the toggle.
class JournalHistory extends ConsumerWidget {
  const JournalHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.journalHistory),
        AsyncSection(
          value: ref.watch(journalHistoryProvider),
          builder: (page) => page.total == 0
              ? EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: l10n.journalHistoryEmpty,
                  hint: l10n.journalHistoryEmptyHint,
                )
              : _HistoryList(page: page),
        ),
      ],
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.page});

  final JournalPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final formatter = DateFormat('EEEE d MMMM', 'es');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: Column(
            children: [
              for (final entry in page.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.sm),
                  child: Card(
                    child: ListTile(
                      title: Text(
                        formatter.format(entry.date),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        entry.content.journalPreview.isEmpty
                            ? l10n.journalNoPreview
                            : entry.content.journalPreview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () =>
                          ref.read(selectedDayProvider.notifier).state =
                              entry.date,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (page.pageCount > 1) _Pager(page: page),
      ],
    );
  }
}

class _Pager extends ConsumerWidget {
  const _Pager({required this.page});

  final JournalPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(journalHistoryPageProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: page.page == 0
              ? null
              : () => notifier.update((value) => value - 1),
        ),
        Text(
          l10n.journalPage(page.page + 1, page.pageCount),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: page.page >= page.pageCount - 1
              ? null
              : () => notifier.update((value) => value + 1),
        ),
      ],
    );
  }
}
