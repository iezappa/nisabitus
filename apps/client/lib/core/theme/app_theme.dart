import 'package:flutter/material.dart';

/// The visual identity of the app: serene and firm, never competing for
/// attention.
///
/// The palette is deliberately narrow — one deep green over warm paper — so
/// colour carries meaning instead of decoration. Material's generated scheme
/// is used for harmony, then the roles that define the look are pinned to
/// exact values rather than left to the algorithm.
abstract final class AppTheme {
  /// The deep forest green that carries every accent in the app.
  static const _green = Color(0xFF3E5641);
  static const _greenSoft = Color(0xFF6B8F71);

  /// Warm paper, not the blue-grey Material defaults to.
  static const _paper = Color(0xFFFAF9F5);
  static const _card = Color(0xFFFFFFFF);
  static const _line = Color(0xFFE8E6DF);
  static const _ink = Color(0xFF1A1D1A);
  static const _inkMuted = Color(0xFF7A7F7A);

  /// Dark counterparts: the same relationship, inverted.
  static const _paperDark = Color(0xFF141714);
  static const _cardDark = Color(0xFF1D211D);
  static const _lineDark = Color(0xFF2E332E);
  static const _inkDark = Color(0xFFECEFEA);
  static const _inkMutedDark = Color(0xFF9AA09A);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final paper = isLight ? _paper : _paperDark;
    final card = isLight ? _card : _cardDark;
    final line = isLight ? _line : _lineDark;
    final ink = isLight ? _ink : _inkDark;
    final inkMuted = isLight ? _inkMuted : _inkMutedDark;
    final accent = isLight ? _green : _greenSoft;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: _green,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: isLight ? Colors.white : _paperDark,
          surface: paper,
          onSurface: ink,
          surfaceContainerLowest: card,
          surfaceContainer: card,
          surfaceContainerHighest: isLight
              ? const Color(0xFFF1EFE8)
              : const Color(0xFF262B26),
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
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: line),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: 0.14),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelSmall?.copyWith(color: inkMuted),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: card,
        indicatorColor: accent.withValues(alpha: 0.14),
        selectedLabelTextStyle: base.textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: base.textTheme.labelSmall?.copyWith(
          color: inkMuted,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: inkMuted,
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: line,
        labelStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: base.textTheme.labelLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: isLight ? Colors.white : _paperDark,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
        backgroundColor: accent,
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
          letterSpacing: -1,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
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
          letterSpacing: 1.1,
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
