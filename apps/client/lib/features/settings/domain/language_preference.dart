import 'dart:ui';

/// Which language the interface is shown in.
enum LanguageChoice {
  system('system', null),
  spanish('es', Locale('es')),
  english('en', Locale('en'));

  const LanguageChoice(this.id, this.locale);

  /// Stored value. Stable across releases.
  final String id;

  /// Null means "whatever the device is set to".
  final Locale? locale;

  static const fallback = LanguageChoice.system;

  static LanguageChoice parse(String? value) {
    for (final choice in LanguageChoice.values) {
      if (choice.id == value) return choice;
    }
    return fallback;
  }
}
