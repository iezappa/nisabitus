import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app/launch_gate.dart';
import 'core/preferences/preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/settings_providers.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Resolved before the first frame so the rest of the app can read
  // preferences synchronously instead of threading a future through the UI.
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const NisabitApp(),
    ),
  );
}

class NisabitApp extends ConsumerStatefulWidget {
  const NisabitApp({super.key});

  @override
  ConsumerState<NisabitApp> createState() => _NisabitAppState();
}

class _NisabitAppState extends ConsumerState<NisabitApp> {
  // Built once: rebuilding the router on every frame would drop the
  // navigation state.
  late final _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(accentColorProvider);
    final theme = ref.watch(themeChoiceProvider);
    final language = ref.watch(languageChoiceProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: _router,
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      themeMode: theme.mode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Null hands the choice back to the device.
      locale: language.locale,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => LaunchGate(child: child ?? const SizedBox()),
    );
  }
}
