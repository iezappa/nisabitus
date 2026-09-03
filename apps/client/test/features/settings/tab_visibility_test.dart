import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/router/app_tab.dart';
import 'package:nisabitus/features/settings/presentation/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> containerWith(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    return container;
  }

  test('shows a tab that did not exist when the user last chose', () async {
    // The bug this arrangement exists to prevent: a stored set of visible
    // tabs cannot tell "I hid this" apart from "this did not exist yet", so
    // reading it against today's tabs would ship every new module switched
    // off for everyone who had ever opened the settings screen.
    final container = await containerWith({
      'settings.visibleTabs': const [
        'dashboard',
        'habits',
        'journal',
        'health',
        'pomodoro',
        'todo',
      ],
    });

    expect(container.read(visibleTabsProvider), contains(AppTab.meditation));
  });

  test('keeps hiding what the user actually hid', () async {
    final container = await containerWith({
      'settings.visibleTabs': const [
        'dashboard',
        'habits',
        'journal',
        'health',
        'todo',
      ],
    });

    final visible = container.read(visibleTabsProvider);
    expect(visible, isNot(contains(AppTab.pomodoro)));
    expect(visible, contains(AppTab.meditation));
  });

  test('prefers the hidden set once it has been written', () async {
    final container = await containerWith({
      'settings.hiddenTabs': const ['todo'],
      // Stale, and deliberately disagreeing: whatever the old key says, the
      // new one is the answer once it exists.
      'settings.visibleTabs': const ['dashboard'],
    });

    final visible = container.read(visibleTabsProvider);
    expect(visible, isNot(contains(AppTab.todo)));
    expect(visible, contains(AppTab.habits));
  });

  test('shows a tab again by taking it out of the hidden set', () async {
    final container = await containerWith({
      'settings.hiddenTabs': const ['todo'],
    });

    container
        .read(tabVisibilityActionsProvider)
        .setVisible(AppTab.todo, visible: true);

    expect(container.read(visibleTabsProvider), contains(AppTab.todo));
  });
}
