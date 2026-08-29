import 'package:flutter/material.dart';

/// The accent the whole interface is tinted with.
///
/// A closed set rather than a free colour picker: every option is checked to
/// stay legible on both grounds, which an arbitrary hex value would not be.
///
/// The tones are saturated enough to read as a deliberate colour against a
/// neutral surface. The first pass used muted earth tones that suited warm
/// paper and looked merely dull once the background stopped being tinted.
enum AccentColor {
  forest('forest', Color(0xFF1F6B4C), Color(0xFF4FBF8B)),
  gold('gold', Color(0xFF8A6A16), Color(0xFFD4A93F)),
  clay('clay', Color(0xFFA8442A), Color(0xFFE08668)),
  indigo('indigo', Color(0xFF3B49C4), Color(0xFF8E9BF5)),
  plum('plum', Color(0xFF7C3A72), Color(0xFFC589BC)),
  slate('slate', Color(0xFF2F6070), Color(0xFF74AEC2));

  const AccentColor(this.id, this.light, this.dark);

  /// Stored value. Stable across releases: renaming one would reset the
  /// choice of everyone who picked it.
  final String id;

  /// The tone used on warm paper.
  final Color light;

  /// The lighter tone the dark scheme needs to keep contrast.
  final Color dark;

  static const fallback = AccentColor.forest;

  static AccentColor parse(String? value) {
    for (final accent in AccentColor.values) {
      if (accent.id == value) return accent;
    }
    return fallback;
  }

  Color resolve(Brightness brightness) =>
      brightness == Brightness.light ? light : dark;
}
