import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/habits/presentation/habits_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/pomodoro/presentation/pomodoro_screen.dart';
import '../../features/settings/presentation/settings_providers.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sleep/presentation/sleep_screen.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/coming_soon_screen.dart';
import '../widgets/settings_button.dart';
import 'app_tab.dart';

GoRouter buildRouter() => GoRouter(
  initialLocation: AppTab.habits.path,
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        // Every tab keeps a route even when hidden, so a deep link into a
        // hidden section still resolves instead of 404-ing.
        for (final tab in AppTab.values)
          GoRoute(
            path: tab.path,
            builder: (context, _) => switch (tab) {
              AppTab.habits => const HabitsScreen(),
              AppTab.sleep => const SleepScreen(),
              AppTab.journal => const JournalScreen(),
              AppTab.pomodoro => const PomodoroScreen(),
              _ => ComingSoonScreen(
                title: tab.label(AppLocalizations.of(context)),
              ),
            },
          ),
      ],
    ),
    // Outside the shell on purpose: it is pushed over whatever tab is open,
    // gets a real back arrow, and never depends on a navigation destination
    // that the user may have hidden.
    GoRoute(
      path: SettingsButton.route,
      builder: (context, _) => const SettingsScreen(),
    ),
  ],
);

/// Holds the navigation that stays put while the tabs change.
///
/// A rail on wide windows, a bottom bar on narrow ones: the same
/// destinations either way, limited to the tabs the user kept visible.
class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final visible = ref.watch(visibleTabsProvider);
    final index = visible.indexWhere((tab) => tab.path == location);

    // The active tab was just hidden, so move to one that still exists.
    if (index < 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(visible.first.path);
      });
    }

    final selected = index < 0 ? 0 : index;
    void go(int target) => context.go(visible[target].path);

    if (MediaQuery.sizeOf(context).width < 720) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: go,
          destinations: [
            for (final tab in visible)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label(l10n),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selected,
            onDestinationSelected: go,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Image.asset('assets/branding/logo.png', height: 28),
            ),
            destinations: [
              for (final tab in visible)
                NavigationRailDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: Text(tab.label(l10n)),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
