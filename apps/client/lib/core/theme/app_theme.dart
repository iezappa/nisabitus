import 'package:flutter/material.dart';

import '../../features/settings/domain/accent_color.dart';

/// The visual identity of the app: serene and firm, never competing for
/// attention.
///
/// The palette is deliberately narrow — one deep green over warm paper — so
/// colour carries meaning instead of decoration. Material's generated scheme
/// is used for harmony, then the roles that define the look are pinned to
/// exact values rather than left to the algorithm.
abstract final class AppTheme {
  /// A near-white ground with white cards floating a shade above it.
  ///
  /// Neutral on purpose: colour belongs to the accent, and a tinted
  /// background competes with it. The card is the only pure white, which is
  /// what makes it read as raised without a shadow.
  static const _paper = Color(0xFFFBFBFC);
  static const _card = Color(0xFFFFFFFF);
  static const _line = Color(0xFFE6E7EA);
  static const _ink = Color(0xFF16171A);
  // Dark enough to clear 4.5:1 on a white card.
  static const _inkMuted = Color(0xFF5F6169);

  /// The same relationship inverted: a near-black ground with cards a shade
  /// above it.
  ///
  /// Off black rather than pure black, so the cards have somewhere to sit —
  /// on true black a raised surface has no ground to rise from.
  static const _paperDark = Color(0xFF0E0E11);
  static const _cardDark = Color(0xFF17171B);
  static const _lineDark = Color(0xFF26262C);
  static const _inkDark = Color(0xFFECECEF);
  static const _inkMutedDark = Color(0xFF9A9BA3);

  static ThemeData light(AccentColor accent) =>
      _build(Brightness.light, accent);
  static ThemeData dark(AccentColor accent) => _build(Brightness.dark, accent);

  static ThemeData _build(Brightness brightness, AccentColor accent) {
    final isLight = brightness == Brightness.light;
    final paper = isLight ? _paper : _paperDark;
    final card = isLight ? _card : _cardDark;
    final line = isLight ? _line : _lineDark;
    final ink = isLight ? _ink : _inkDark;
    final inkMuted = isLight ? _inkMuted : _inkMutedDark;
    final tint = accent.resolve(brightness);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent.light,
          brightness: brightness,
        ).copyWith(
          primary: tint,
          onPrimary: isLight ? Colors.white : _paperDark,
          surface: paper,
          onSurface: ink,
          surfaceContainerLowest: card,
          surfaceContainer: card,
          surfaceContainerHighest: isLight
              ? const Color(0xFFF1F2F4)
              : const Color(0xFF212128),
          onSurfaceVariant: inkMuted,
          outlineVariant: line,
          outline: line,
        );

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: paper,
      textTheme: _textTheme(base.textTheme, ink, inkMuted),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: line),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tint.withValues(alpha: 0.14),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelSmall?.copyWith(color: inkMuted),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: card,
        indicatorColor: tint.withValues(alpha: 0.14),
        selectedLabelTextStyle: base.textTheme.labelSmall?.copyWith(
          color: tint,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: base.textTheme.labelSmall?.copyWith(
          color: inkMuted,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: tint,
        unselectedLabelColor: inkMuted,
        indicatorColor: tint,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: line,
        labelStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: base.textTheme.labelLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tint,
          foregroundColor: isLight ? Colors.white : _paperDark,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: inkMuted),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tint,
        foregroundColor: isLight ? Colors.white : _paperDark,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: line),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color ink, Color muted) =>
      base.copyWith(
        displaySmall: base.displaySmall?.copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.2,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.6,
        ),
        titleLarge: base.titleLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: base.titleMedium?.copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: base.titleSmall?.copyWith(color: ink),
        bodyMedium: base.bodyMedium?.copyWith(color: ink),
        bodySmall: base.bodySmall?.copyWith(color: muted),
        // The signature micro-label: small, uppercase, widely tracked.
        labelSmall: base.labelSmall?.copyWith(
          color: muted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      );
}

/// The one place spacing values are defined, so the layout keeps a rhythm
/// instead of every widget inventing its own numbers.
abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}
