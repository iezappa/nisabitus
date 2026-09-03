import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Which first-level tabs the user has hidden.
///
/// The hidden ones are stored, not the visible ones, and that is the whole
/// point: hiding is a decision the user made, showing is the absence of one.
/// A set of visible tabs cannot tell "I hid this" apart from "this did not
/// exist when I last chose", so every module added afterwards would arrive
/// switched off for everyone who had ever opened the screen — invisible, and
/// blamed on the user's own settings.
final hiddenTabsPreferenceProvider =
    StateNotifierProvider<StringSetPreference, Set<String>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);

      return StringSetPreference(
        prefs,
        _hiddenTabsKey,
        fallback: _hiddenFromLegacy(prefs),
      );
    });

const _hiddenTabsKey = 'settings.hiddenTabs';
const _legacyVisibleTabsKey = 'settings.visibleTabs';

/// The tabs that existed when the stored set was still a set of visible ones.
///
/// Frozen on purpose. The old value cannot say anything about a tab that did
/// not exist when it was written, so reading it against today's [AppTab]
/// would hide every module added since — which is the exact bug this whole
/// arrangement exists to avoid.
const _tabsAtMigration = {
  'dashboard',
  'habits',
  'journal',
  'health',
  'pomodoro',
  'todo',
};

/// Turns an old visible-tab set into the hidden one it implied.
///
/// Nothing stored means nothing hidden: a fresh install shows everything.
Set<String> _hiddenFromLegacy(SharedPreferences prefs) {
  final legacy = prefs.getStringList(_legacyVisibleTabsKey);
  if (legacy == null) return const {};

  return _tabsAtMigration.difference(legacy.toSet());
}

final visibleTabsProvider = Provider<List<AppTab>>((ref) {
  final hidden = ref.watch(hiddenTabsPreferenceProvider);
  final visible = AppTab.values
      .where((tab) => !hidden.contains(tab.name))
      .toList();

  // Never leave the user without a destination.
  return visible.isEmpty ? [AppTab.dashboard] : visible;
});

/// Shows or hides a tab, refusing to hide the last one standing.
class TabVisibilityActions {
  TabVisibilityActions(this._ref);

  final Ref _ref;

  void setVisible(AppTab tab, {required bool visible}) {
    final current = {..._ref.read(hiddenTabsPreferenceProvider)};
    if (visible) {
      current.remove(tab.name);
    } else {
      if (_ref.read(visibleTabsProvider).length <= 1) return;
      current.add(tab.name);
    }
    _ref.read(hiddenTabsPreferenceProvider.notifier).set(current);
  }
}

final tabVisibilityActionsProvider = Provider<TabVisibilityActions>(
  TabVisibilityActions.new,
);
