import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// The way into settings, present on every screen.
///
/// It sits in the app bar rather than the navigation bar on purpose: a tab
/// can be hidden, and hiding the one screen that unhides tabs would lock the
/// user out of their own configuration.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  static const route = '/ajustes';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: l10n.settingsTitle,
      onPressed: () => context.push(route),
    );
  }
}
