import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/backup/presentation/widgets/auto_backup_banner.dart';
import '../../features/backup/presentation/widgets/backup_reminder_banner.dart';
import '../../features/update/presentation/update_banner.dart';
import '../../features/backup/presentation/widgets/storage_warning_banner.dart';
import '../../features/cheatsheets/presentation/cheatsheets_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/habits/presentation/habits_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/pomodoro/presentation/pomodoro_screen.dart';
import '../../features/settings/presentation/settings_providers.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/health/presentation/health_screen.dart';
import '../../features/todo/presentation/todo_screen.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/settings_button.dart';
import 'app_tab.dart';
import 'nav_rail.dart';

/// Where meditation used to live.
const _meditationWas = '/meditacion';

/// Where Study lived during the first Cheatsheets iteration.
const _cheatsheetsWas = '/cheatsheets';

GoRouter buildRouter({GlobalKey<NavigatorState>? navigatorKey}) => GoRouter(
  navigatorKey: navigatorKey,
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
              AppTab.dashboard => const DashboardScreen(),
              AppTab.habits => const HabitsScreen(),
              AppTab.health => const HealthScreen(),
              AppTab.journal => const JournalScreen(),
              AppTab.pomodoro => const PomodoroScreen(),
              AppTab.todo => const TodoScreen(),
              AppTab.cheatsheets => const CheatsheetsScreen(),
            },
          ),
        // Settings stays in the shell so the navbar remains visible, but it is
        // not part of [AppTab] and therefore can never be hidden.
        GoRoute(
          path: SettingsButton.route,
          builder: (context, _) => const SettingsScreen(),
        ),
      ],
    ),
    // Meditation was a tab of its own until it moved in with the rest of
    // Salud. The old path stays as a redirect rather than being dropped: a
    // bookmark or a pinned link is the user's, and letting it 404 would be
    // a change they never made.
    GoRoute(path: _meditationWas, redirect: (_, _) => AppTab.health.path),
    GoRoute(path: _cheatsheetsWas, redirect: (_, _) => AppTab.cheatsheets.path),
  ],
);

/// Holds the navigation that stays put while the tabs change.
///
/// A rail on wide windows, a bottom bar on narrow ones: the same destinations
/// either way, limited to the tabs the user kept visible. Settings is always
/// added after them because it is the place that can unhide tabs again.
class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final visible = ref.watch(visibleTabsProvider);
    final settingsSelected = location == SettingsButton.route;
    final index = visible.indexWhere((tab) => tab.path == location);

    // The active tab was just hidden, so move to one that still exists. Settings
    // is deliberately outside that hideable set and stays reachable.
    if (index < 0 && !settingsSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(visible.first.path);
      });
    }

    final selected = index < 0 ? 0 : index;
    void go(int target) => context.go(visible[target].path);
    void goSettings() => context.go(SettingsButton.route);

    if (MediaQuery.sizeOf(context).width < 720) {
      final compactPhoneDestinations = visible.length + 1 > 5;

      return Scaffold(
        body: _WithNotices(child: child),
        // Up to seven tabs share a phone's width, and a label broken mid-word
        // reads worse than a clipped one. Labels stay on one line, and past
        // Material's five destinations only the open tab is named; the rest
        // keep their icon and a tooltip.
        bottomNavigationBar: NavigationBar(
          selectedIndex: settingsSelected ? visible.length : selected,
          onDestinationSelected: (target) =>
              target == visible.length ? goSettings() : go(target),
          labelBehavior: compactPhoneDestinations
              ? NavigationDestinationLabelBehavior.alwaysHide
              : null,
          destinations: [
            for (final tab in visible)
              // Per destination: the bar's own Material resets any text style
              // set around it.
              DefaultTextStyle.merge(
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.label(l10n),
                ),
              ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: compactPhoneDestinations ? '' : l10n.tabSettings,
              tooltip: l10n.tabSettings,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavRail(
            selectedIndex: selected,
            onSelected: go,
            destinations: [
              for (final tab in visible)
                (tab.icon, tab.selectedIcon, tab.label(l10n)),
            ],
            footer: (Icons.settings_outlined, Icons.settings, l10n.tabSettings),
            footerSelected: settingsSelected,
            onFooterSelected: goSettings,
          ),
          Expanded(child: _WithNotices(child: child)),
        ],
      ),
    );
  }
}

/// The tab, with any data-safety notice docked under it.
///
/// At the bottom rather than the top: the tabs bring their own app bars and
/// status-bar insets, and a banner pushed above them would sit between the
/// clock and the title. Down here it covers nothing and blocks nothing.
class _WithNotices extends StatelessWidget {
  const _WithNotices({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(child: child),
      const StorageWarningBanner(),
      // Before the nudge to export by hand: a copy the app was meant to be
      // taking and is not is the more urgent of the two.
      const AutoBackupBanner(),
      const BackupReminderBanner(),
      const UpdateBanner(),
    ],
  );
}
