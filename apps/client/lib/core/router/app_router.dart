import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/habits/presentation/habits_screen.dart';
import '../../features/sleep/presentation/sleep_screen.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/coming_soon_screen.dart';

/// A first-level tab of the app.
enum AppTab {
  dashboard('/panel', Icons.dashboard_outlined, Icons.dashboard),
  habits('/habitos', Icons.checklist_outlined, Icons.checklist),
  journal('/journal', Icons.menu_book_outlined, Icons.menu_book),
  sleep('/sueno', Icons.bedtime_outlined, Icons.bedtime),
  pomodoro('/pomodoro', Icons.timer_outlined, Icons.timer),
  todo('/todo', Icons.task_alt_outlined, Icons.task_alt);

  const AppTab(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l10n) => switch (this) {
    AppTab.dashboard => l10n.tabDashboard,
    AppTab.habits => l10n.tabHabits,
    AppTab.journal => l10n.tabJournal,
    AppTab.sleep => l10n.tabSleep,
    AppTab.pomodoro => l10n.tabPomodoro,
    AppTab.todo => l10n.tabTodo,
  };
}

GoRouter buildRouter() => GoRouter(
  initialLocation: AppTab.habits.path,
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          _AppShell(location: state.uri.path, child: child),
      routes: [
        for (final tab in AppTab.values)
          GoRoute(
            path: tab.path,
            builder: (context, _) => switch (tab) {
              AppTab.habits => const HabitsScreen(),
              AppTab.sleep => const SleepScreen(),
              _ => ComingSoonScreen(
                title: tab.label(AppLocalizations.of(context)),
              ),
            },
          ),
      ],
    ),
  ],
);

/// Holds the navigation that stays put while the tabs change.
///
/// A rail on wide windows, a bottom bar on narrow ones: the same six
/// destinations either way.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.location, required this.child});

  final String location;
  final Widget child;

  int get _index {
    final index = AppTab.values.indexWhere((tab) => tab.path == location);
    return index < 0 ? 0 : index;
  }

  void _go(BuildContext context, int index) =>
      context.go(AppTab.values[index].path);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    if (!isWide) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => _go(context, index),
          destinations: [
            for (final tab in AppTab.values)
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
            selectedIndex: _index,
            onDestinationSelected: (index) => _go(context, index),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            destinations: [
              for (final tab in AppTab.values)
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
