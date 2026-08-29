import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() => runApp(const ProviderScope(child: NisabitApp()));

class NisabitApp extends StatefulWidget {
  const NisabitApp({super.key});

  @override
  State<NisabitApp> createState() => _NisabitAppState();
}

class _NisabitAppState extends State<NisabitApp> {
  // Built once: rebuilding the router on every frame would drop the
  // navigation state.
  late final _router = buildRouter();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    routerConfig: _router,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    debugShowCheckedModeBanner: false,
  );
}
