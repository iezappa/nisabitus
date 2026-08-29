import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device-local key/value store, resolved once at startup.
///
/// Overridden in [main] with the instance obtained before the first frame,
/// so the rest of the app can read preferences synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden before use',
  ),
);

/// A single remembered boolean, such as whether a panel is expanded.
///
/// Writes are fire-and-forget: losing one on a crash costs nothing, and the
/// UI should never wait on a disk write to open a card.
class BoolPreference extends StateNotifier<bool> {
  BoolPreference(this._prefs, this._key, {required bool fallback})
    : super(_prefs.getBool(_key) ?? fallback);

  final SharedPreferences _prefs;
  final String _key;

  void set(bool value) {
    state = value;
    _prefs.setBool(_key, value);
  }

  void toggle() => set(!state);
}
