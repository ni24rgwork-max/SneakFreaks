import 'package:flutter/material.dart';

/// Brand-specific design tokens that Material's [ColorScheme] has no slot for.
///
/// Registered as a [ThemeExtension] so every value is brightness-aware and
/// resolves through `Theme.of(context)` like any built-in token. Nothing in the
/// UI layer should reference a raw hex.
@immutable
class BrandTokens extends ThemeExtension<BrandTokens> {
  const BrandTokens({
    required this.sale,
    required this.onSale,
    required this.success,
    required this.accentText,
    required this.priceStrike,
    required this.interactiveBorder,
    required this.hairline,
    required this.cardRadius,
    required this.sheetRadius,
  });

  /// Price drops, urgency, "% OFF" badges. Deliberately the only loud colour
  /// in the chrome — product photography supplies the rest.
  final Color sale;
  final Color onSale;

  /// In stock, delivery confirmed, payment succeeded.
  final Color success;

  /// The accent colour at a lightness that is legible *as text*. In light mode
  /// a saturated accent used as a fill is rarely legible as a label, so this is
  /// a separate, darker token rather than the fill colour reused.
  final Color accentText;

  /// Struck-through MRP alongside a discounted price.
  final Color priceStrike;

  /// Borders that carry meaning (inputs, focus, selected chips). Held to the
  /// WCAG 3:1 non-text minimum.
  final Color interactiveBorder;

  /// Decorative separators. Intentionally below 3:1 — these are not meaningful
  /// boundaries and a visible grey line reads as noise.
  final Color hairline;

  final double cardRadius;
  final double sheetRadius;

  // Motion tokens. Kept here so no widget hardcodes a Duration.
  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionBase = Duration(milliseconds: 300);
  static const Duration motionSlow = Duration(milliseconds: 500);
  static const Curve motionEmphasized = Curves.easeOutCubic;

  /// Delay between staggered siblings. Small on purpose — anything longer and
  /// a list of six feels like it is loading rather than arriving.
  static const int staggerStepMs = 40;

  /// Container-transform duration for card → detail.
  static const Duration motionContainer = Duration(milliseconds: 420);

  @override
  BrandTokens copyWith({
    Color? sale,
    Color? onSale,
    Color? success,
    Color? accentText,
    Color? priceStrike,
    Color? interactiveBorder,
    Color? hairline,
    double? cardRadius,
    double? sheetRadius,
  }) {
    return BrandTokens(
      sale: sale ?? this.sale,
      onSale: onSale ?? this.onSale,
      success: success ?? this.success,
      accentText: accentText ?? this.accentText,
      priceStrike: priceStrike ?? this.priceStrike,
      interactiveBorder: interactiveBorder ?? this.interactiveBorder,
      hairline: hairline ?? this.hairline,
      cardRadius: cardRadius ?? this.cardRadius,
      sheetRadius: sheetRadius ?? this.sheetRadius,
    );
  }

  @override
  BrandTokens lerp(covariant BrandTokens? other, double t) {
    if (other == null) return this;
    return BrandTokens(
      sale: Color.lerp(sale, other.sale, t)!,
      onSale: Color.lerp(onSale, other.onSale, t)!,
      success: Color.lerp(success, other.success, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      priceStrike: Color.lerp(priceStrike, other.priceStrike, t)!,
      interactiveBorder:
          Color.lerp(interactiveBorder, other.interactiveBorder, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t),
      sheetRadius: lerpDouble(sheetRadius, other.sheetRadius, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
