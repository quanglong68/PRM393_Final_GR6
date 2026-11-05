abstract final class AppSpacing {
  /// Hairline gap between a label and its value on the same row.
  static const hairline = 2.0;
  static const xxs = 4.0;

  /// Badge / chip inner padding — narrower than `xs`.
  static const micro = 6.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 999.0;
}

/// Elevation tokens (rubric §4.3). Cards are flat (0); only transient
/// surfaces such as the in-app push banner float.
abstract final class AppElevation {
  static const flat = 0.0;
  static const overlay = 6.0;
}

/// Font sizes below the theme's `TextTheme` scale — captions, helper text and
/// dense metadata. Anything at or above 14 sp must come from `TextTheme`.
abstract final class AppFontSize {
  static const caption = 11.0;
  static const label = 12.0;
  static const dense = 13.0;

  /// Hero numerals (GPA figure, avatar initial) — display-only, never body.
  static const displaySmall = 18.0;
  static const displayMedium = 22.0;
  static const displayLarge = 24.0;

  /// Standalone error/blocking screen headings, outside a themed subtree.
  static const heading = 20.0;
}
