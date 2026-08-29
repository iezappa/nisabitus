import 'package:flutter/material.dart';

/// Whether the app follows the system or is pinned to one scheme.
enum ThemeChoice {
  system('system', ThemeMode.system),
  light('light', ThemeMode.light),
  dark('dark', ThemeMode.dark);

  const ThemeChoice(this.id, this.mode);

  /// Stored value. Stable across releases.
  final String id;

  final ThemeMode mode;

  static const fallback = ThemeChoice.system;

  static ThemeChoice parse(String? value) {
    for (final choice in ThemeChoice.values) {
      if (choice.id == value) return choice;
    }
    return fallback;
  }
}
