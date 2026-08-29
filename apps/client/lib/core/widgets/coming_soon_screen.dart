import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'empty_state.dart';
import 'settings_button.dart';

/// Placeholder for a tab whose module is not implemented yet.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(leading: const SettingsButton(), title: Text(title)),
      body: Center(
        child: EmptyState(
          icon: Icons.construction_outlined,
          title: l10n.comingSoon,
          hint: l10n.comingSoonHint,
        ),
      ),
    );
  }
}
