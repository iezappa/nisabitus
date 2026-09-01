import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences.dart';
import '../data/asset_release_notes.dart';
import '../domain/app_version.dart';
import '../domain/release_notes.dart';

/// Where the changelog is read from. Overridden in tests with a fake bundle.
final assetBundleProvider = Provider<AssetBundle>((ref) => rootBundle);

/// The changelog as written in one language.
///
/// Keyed by language rather than read once, because the user can switch the
/// interface language without restarting the app.
final releaseNotesProvider = FutureProvider.family<ReleaseNotes, String>(
  (ref, languageCode) =>
      AssetReleaseNotes(ref.watch(assetBundleProvider)).load(languageCode),
);

/// The newest version whose notes the user has already been shown.
///
/// Empty until something is shown once, which is how a fresh install is told
/// apart from an upgrade.
final lastSeenVersionProvider = StateNotifierProvider<StringPreference, String>(
  (ref) => StringPreference(
    ref.watch(sharedPreferencesProvider),
    'releaseNotes.lastSeenVersion',
    fallback: '',
  ),
);

/// The stored version, or null when nothing has been shown yet.
///
/// Unreadable stored text reads as null rather than throwing: it is a hint
/// about what to announce, not data worth failing a launch over.
final lastSeenReleaseProvider = Provider<AppVersion?>(
  (ref) => AppVersion.tryParse(ref.watch(lastSeenVersionProvider)),
);

/// The releases this user has not been shown yet, newest first.
///
/// Empty while the changelog is still loading, so nothing announces itself
/// before it is known.
final unseenReleasesProvider = Provider.family<List<ReleaseNote>, String>((
  ref,
  languageCode,
) {
  final notes = ref.watch(releaseNotesProvider(languageCode)).valueOrNull;
  if (notes == null) return const [];

  return notes.since(ref.watch(lastSeenReleaseProvider));
});

/// Remembers what the user has been shown.
class ReleaseNotesActions {
  ReleaseNotesActions(this._ref);

  final Ref _ref;

  /// Records that everything up to [version] has been shown.
  void markSeen(AppVersion version) =>
      _ref.read(lastSeenVersionProvider.notifier).set('$version');
}

final releaseNotesActionsProvider = Provider<ReleaseNotesActions>(
  ReleaseNotesActions.new,
);
