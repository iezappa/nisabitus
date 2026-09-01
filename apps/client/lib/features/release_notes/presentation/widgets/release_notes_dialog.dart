import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/release_notes.dart';
import '../release_notes_providers.dart';

/// Shows what changed, and remembers that it was shown.
///
/// Run with [unseenOnly] it is the announcement after an update: just the
/// releases newer than the last one the user saw. Opened from settings it is
/// the whole history.
///
/// Either way the newest version is stamped as seen when the dialog closes,
/// dismissal included. Someone who waved it away has been told; showing it
/// again on the next launch would be nagging rather than informing.
Future<void> showReleaseNotes(
  BuildContext context, {
  bool unseenOnly = false,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final language = Localizations.localeOf(context).languageCode;

  await showDialog<void>(
    context: context,
    builder: (context) => _ReleaseNotesDialog(unseenOnly: unseenOnly),
  );

  final notes = container.read(releaseNotesProvider(language)).valueOrNull;
  if (notes != null) {
    container.read(releaseNotesActionsProvider).markSeen(notes.current);
  }
}

class _ReleaseNotesDialog extends ConsumerWidget {
  const _ReleaseNotesDialog({required this.unseenOnly});

  final bool unseenOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final notes = ref.watch(releaseNotesProvider(language));

    return AlertDialog(
      title: Text(
        unseenOnly ? l10n.releaseNotesWhatsNew : l10n.releaseNotesHistory,
      ),
      content: SizedBox(
        width: 420,
        child: notes.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
          // The changelog ships with the app, so this only happens to a build
          // that shipped a broken file. Say so plainly instead of crashing.
          error: (error, _) => Text(
            '$error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          data: (changelog) => _Releases(
            releases: unseenOnly
                ? ref.watch(unseenReleasesProvider(language))
                : changelog.all,
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.releaseNotesClose),
        ),
      ],
    );
  }
}

/// One block per release, newest first.
class _Releases extends StatelessWidget {
  const _Releases({required this.releases});

  final List<ReleaseNote> releases;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final formatter = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final release in releases) ...[
            if (release != releases.first) const SizedBox(height: Gap.xl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.releaseNotesVersion('${release.version}'),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  formatter.format(release.date),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            for (final highlight in release.highlights)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: Gap.sm,
                        right: Gap.sm,
                      ),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(highlight, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
