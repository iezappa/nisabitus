import 'package:flutter/material.dart';

/// The accent the whole interface is tinted with.
///
/// A closed set rather than a free colour picker: every option is checked to
/// stay legible on warm paper and in the dark scheme, which an arbitrary hex
/// value would not be.
enum AccentColor {
  forest('forest', Color(0xFF3E5641), Color(0xFF6B8F71)),
  gold('gold', Color(0xFF9A7734), Color(0xFFC9A65C)),
  clay('clay', Color(0xFF9C5A3C), Color(0xFFC98A6B)),
  indigo('indigo', Color(0xFF3F4E7A), Color(0xFF8492C4)),
  plum('plum', Color(0xFF6E4460), Color(0xFFB287A6)),
  slate('slate', Color(0xFF41595F), Color(0xFF86A6AD));

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
