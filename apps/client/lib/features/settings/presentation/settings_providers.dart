import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences.dart';
import '../../../core/router/app_tab.dart';
import '../domain/accent_color.dart';
import '../domain/language_preference.dart';
import '../domain/theme_preference.dart';

/// The accent the interface is tinted with.
final accentPreferenceProvider =
    StateNotifierProvider<StringPreference, String>(
      (ref) => StringPreference(
        ref.watch(sharedPreferencesProvider),
        'settings.accent',
        fallback: AccentColor.fallback.id,
      ),
    );

final accentColorProvider = Provider<AccentColor>(
  (ref) => AccentColor.parse(ref.watch(accentPreferenceProvider)),
);

/// Whether the app follows the system scheme or is pinned to one.
final themePreferenceProvider = StateNotifierProvider<StringPreference, String>(
  (ref) => StringPreference(
    ref.watch(sharedPreferencesProvider),
    'settings.theme',
    fallback: ThemeChoice.fallback.id,
  ),
);

final themeChoiceProvider = Provider<ThemeChoice>(
  (ref) => ThemeChoice.parse(ref.watch(themePreferenceProvider)),
);

/// Which language the interface is shown in.
final languagePreferenceProvider =
    StateNotifierProvider<StringPreference, String>(
      (ref) => StringPreference(
        ref.watch(sharedPreferencesProvider),
        'settings.language',
        fallback: LanguageChoice.fallback.id,
      ),
    );

final languageChoiceProvider = Provider<LanguageChoice>(
  (ref) => LanguageChoice.parse(ref.watch(languagePreferenceProvider)),
);

/// The name shown in the greeting. Empty until onboarding runs.
final profileNameProvider = StateNotifierProvider<StringPreference, String>(
  (ref) => StringPreference(
    ref.watch(sharedPreferencesProvider),
    'settings.profileName',
    fallback: '',
  ),
);

/// Whether the first-run wizard has been completed.
final onboardingDoneProvider = StateNotifierProvider<BoolPreference, bool>(
  (ref) => BoolPreference(
    ref.watch(sharedPreferencesProvider),
    'settings.onboardingDone',
    fallback: false,
  ),
);

/// Which first-level tabs are shown.
///
/// The spec lets every tab be hidden except that at least one must remain,
/// so the stored set is repaired on read rather than trusted.
final visibleTabsPreferenceProvider =
    StateNotifierProvider<StringSetPreference, Set<String>>(
      (ref) => StringSetPreference(
        ref.watch(sharedPreferencesProvider),
        'settings.visibleTabs',
        fallback: {for (final tab in AppTab.values) tab.name},
      ),
    );

final visibleTabsProvider = Provider<List<AppTab>>((ref) {
  final stored = ref.watch(visibleTabsPreferenceProvider);
  final visible = AppTab.values
      .where((tab) => stored.contains(tab.name))
      .toList();

  // Never leave the user without a destination.
  return visible.isEmpty ? [AppTab.dashboard] : visible;
});

/// Shows or hides a tab, refusing to hide the last one standing.
class TabVisibilityActions {
  TabVisibilityActions(this._ref);

  final Ref _ref;

  void setVisible(AppTab tab, {required bool visible}) {
    final current = {..._ref.read(visibleTabsPreferenceProvider)};
    if (visible) {
      current.add(tab.name);
    } else {
      if (_ref.read(visibleTabsProvider).length <= 1) return;
      current.remove(tab.name);
    }
    _ref.read(visibleTabsPreferenceProvider.notifier).set(current);
  }
}

final tabVisibilityActionsProvider = Provider<TabVisibilityActions>(
  TabVisibilityActions.new,
);
