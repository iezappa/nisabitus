import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../release_notes_providers.dart';
import 'release_notes_dialog.dart';

/// The settings row that opens the changelog.
///
/// Carries a mark while a release has not been read, so someone who dismissed
/// the announcement at launch can still find it.
class ReleaseNotesTile extends ConsumerWidget {
  const ReleaseNotesTile({super.key});

  /// The dot shown while there is something unread.
  static const unreadMark = Key('releaseNotesUnread');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final unread = ref.watch(unseenReleasesProvider(language)).isNotEmpty;

    return ListTile(
      // Flush with the page gutter: settings is a flat column, and a tile
      // that indents itself breaks the one left edge everything shares.
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.campaign_outlined),
      title: Text(l10n.settingsReleaseNotes),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unread)
            Padding(
              padding: const EdgeInsets.only(right: Gap.sm),
              child: Container(
                key: unreadMark,
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => showReleaseNotes(context),
    );
  }
}
