import 'dart:ui' show FontFeature, FontVariation;

import 'package:flutter/material.dart';

/// Typography for the storefront.
///
/// Two variable families, both verified to carry U+20B9 (₹) and a `tnum`
/// feature before being bundled:
///   * Archivo — display/headline. Has a `wdth` axis (62-125), so product
///     wordmarks can be set condensed without a separate font file.
///   * Inter — UI and body. Has an `opsz` axis, set per style so small text
///     gets the optically-corrected cut.
///
/// Weights are applied via [FontVariation] on the `wght` axis, *not* by
/// `fontWeight` alone. A variable font will not reliably respond to
/// `fontWeight` on its own — every style would render at the default weight.
/// `fontWeight` is still set so that fallback fonts and the a11y layer behave.
abstract final class AppTypography {
  static const _display = 'Archivo';
  static const _ui = 'Inter';

  static TextStyle _archivo({
    required double size,
    required double wght,
    double wdth = 100,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _display,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: _weightOf(wght),
      fontVariations: [
        FontVariation('wght', wght),
        FontVariation('wdth', wdth),
      ],
    );
  }

  static TextStyle _inter({
    required double size,
    required double wght,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _ui,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: _weightOf(wght),
      fontVariations: [
        FontVariation('wght', wght),
        // Inter's optical-size axis spans 14-32; feeding it the actual size
        // sharpens small text and loosens large text appropriately.
        FontVariation('opsz', size.clamp(14, 32)),
      ],
    );
  }

  static FontWeight _weightOf(double wght) => switch (wght) {
        <= 150 => FontWeight.w100,
        <= 250 => FontWeight.w200,
        <= 350 => FontWeight.w300,
        <= 450 => FontWeight.w400,
        <= 550 => FontWeight.w500,
        <= 650 => FontWeight.w600,
        <= 750 => FontWeight.w700,
        <= 850 => FontWeight.w800,
        _ => FontWeight.w900,
      };

  /// Prices, totals and quantities. Tabular figures stop numerals from
  /// jittering horizontally as values change in a list — `1` is narrower than
  /// `8` in the proportional default.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static const TextTheme textTheme = TextTheme();

  static TextTheme build() {
    return TextTheme(
      // Editorial moments — screen titles, hero product names.
      displayLarge: _archivo(size: 44, wght: 800, wdth: 88, height: 1.02, letterSpacing: -1.0),
      displayMedium: _archivo(size: 36, wght: 800, wdth: 88, height: 1.04, letterSpacing: -0.8),
      displaySmall: _archivo(size: 30, wght: 700, height: 1.08, letterSpacing: -0.5),

      headlineLarge: _archivo(size: 28, wght: 700, height: 1.12, letterSpacing: -0.4),
      headlineMedium: _archivo(size: 24, wght: 700, height: 1.16, letterSpacing: -0.3),
      headlineSmall: _archivo(size: 20, wght: 600, height: 1.2, letterSpacing: -0.2),

      // Structural UI.
      titleLarge: _inter(size: 20, wght: 600, height: 1.25, letterSpacing: -0.2),
      titleMedium: _inter(size: 16, wght: 600, height: 1.3),
      titleSmall: _inter(size: 14, wght: 600, height: 1.35),

      bodyLarge: _inter(size: 16, wght: 400, height: 1.5),
      bodyMedium: _inter(size: 14, wght: 400, height: 1.5),
      bodySmall: _inter(size: 12, wght: 400, height: 1.45),

      labelLarge: _inter(size: 14, wght: 600, letterSpacing: 0.1),
      labelMedium: _inter(size: 12, wght: 600, letterSpacing: 0.2),
      labelSmall: _inter(size: 11, wght: 600, letterSpacing: 0.4),
    );
  }

  /// A condensed, uppercase treatment for brand/product wordmarks — the
  /// `AIR-MAX` style lockup on product cards.
  static TextStyle wordmark({required double size}) =>
      _archivo(size: size, wght: 800, wdth: 70, height: 1.0, letterSpacing: 0.2);
}
