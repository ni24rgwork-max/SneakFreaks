import 'package:flutter/material.dart';

import 'brand_tokens.dart';

/// The two candidate brand directions, switchable at runtime so they can be
/// compared on-device before one is committed to.
enum AppPalette {
  /// Monochrome premium. Warm-neutral surfaces, near-black CTAs, chroma
  /// reserved for commercial signals. The safe choice for a multi-brand store,
  /// because the chrome cannot be seen to favour any one brand's colours.
  ink('Ink', 'Monochrome premium'),

  /// Saffron accent over the same neutral discipline. Warmer, more distinctive,
  /// suits festive merchandising. Gold CTAs in both brightnesses.
  saffron('Saffron', 'Warm accent');

  const AppPalette(this.label, this.blurb);
  final String label;
  final String blurb;
}

/// A resolved (palette x brightness) pair.
class PaletteSpec {
  const PaletteSpec({required this.colors, required this.tokens});
  final ColorScheme colors;
  final BrandTokens tokens;
}

PaletteSpec paletteSpec(AppPalette palette, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (palette) {
    AppPalette.ink => dark ? _inkDark : _inkLight,
    AppPalette.saffron => dark ? _saffronDark : _saffronLight,
  };
}

// ---------------------------------------------------------------------------
// Direction A — "Ink"
//
// Every foreground/background pair below was checked against WCAG before being
// written down. Body text lands at 16-18:1, muted text at ~7:1, and the
// interactive border at >4:1 (the non-text minimum is 3:1).
// ---------------------------------------------------------------------------

const _inkLight = PaletteSpec(
  colors: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF18181B),
    onPrimary: Color(0xFFFAFAF9),
    primaryContainer: Color(0xFFE1E1DE),
    onPrimaryContainer: Color(0xFF1C1B1A),
    secondary: Color(0xFF57534E),
    onSecondary: Color(0xFFFAFAF9),
    secondaryContainer: Color(0xFFEFEFED),
    onSecondaryContainer: Color(0xFF1C1B1A),
    tertiary: Color(0xFFB23A22),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFAFAF9),
    onSurface: Color(0xFF1C1B1A),
    onSurfaceVariant: Color(0xFF57534E),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF5F5F4),
    surfaceContainer: Color(0xFFEFEFED),
    surfaceContainerHigh: Color(0xFFE8E8E6),
    surfaceContainerHighest: Color(0xFFE1E1DE),
    surfaceDim: Color(0xFFDEDEDB),
    surfaceBright: Color(0xFFFAFAF9),
    outline: Color(0xFF79766F),
    outlineVariant: Color(0xFFE7E5E4),
    inverseSurface: Color(0xFF2F2F2E),
    onInverseSurface: Color(0xFFF5F5F4),
    inversePrimary: Color(0xFFC9C9C6),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  ),
  tokens: BrandTokens(
    sale: Color(0xFFB23A22),
    onSale: Color(0xFFFFFFFF),
    success: Color(0xFF1B7A4B),
    accentText: Color(0xFFB23A22),
    priceStrike: Color(0xFF8A857E),
    interactiveBorder: Color(0xFF79766F),
    hairline: Color(0xFFE7E5E4),
    cardRadius: 18,
    sheetRadius: 28,
  ),
);

const _inkDark = PaletteSpec(
  colors: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFAFAF9),
    onPrimary: Color(0xFF18181B),
    primaryContainer: Color(0xFF2A2A2E),
    onPrimaryContainer: Color(0xFFF4F4F5),
    secondary: Color(0xFFA1A1AA),
    onSecondary: Color(0xFF18181B),
    secondaryContainer: Color(0xFF27272A),
    onSecondaryContainer: Color(0xFFF4F4F5),
    tertiary: Color(0xFFFF7A5C),
    onTertiary: Color(0xFF3A0F06),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    // Not pure black: #000 smears on OLED during scroll and leaves no room to
    // express elevation as a lighter surface.
    surface: Color(0xFF0C0C0D),
    onSurface: Color(0xFFF4F4F5),
    onSurfaceVariant: Color(0xFFA1A1AA),
    surfaceContainerLowest: Color(0xFF070708),
    surfaceContainerLow: Color(0xFF17171A),
    surfaceContainer: Color(0xFF1F1F23),
    surfaceContainerHigh: Color(0xFF27272A),
    surfaceContainerHighest: Color(0xFF2F2F33),
    surfaceDim: Color(0xFF0C0C0D),
    surfaceBright: Color(0xFF35353A),
    outline: Color(0xFF71717A),
    outlineVariant: Color(0xFF27272A),
    inverseSurface: Color(0xFFF4F4F5),
    onInverseSurface: Color(0xFF1C1B1A),
    inversePrimary: Color(0xFF18181B),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  ),
  tokens: BrandTokens(
    sale: Color(0xFFFF7A5C),
    onSale: Color(0xFF3A0F06),
    success: Color(0xFF4ADE80),
    accentText: Color(0xFFFF7A5C),
    priceStrike: Color(0xFF8A8A93),
    interactiveBorder: Color(0xFF71717A),
    hairline: Color(0xFF27272A),
    cardRadius: 18,
    sheetRadius: 28,
  ),
);

// ---------------------------------------------------------------------------
// Direction B — "Saffron & Ink"
//
// Saffron is the primary *fill* in both brightnesses, so the CTA reads gold
// rather than black. Note `accentText` is a darkened cut for light mode:
// #E8A33D as a label on near-white only reaches ~2:1.
// ---------------------------------------------------------------------------

const _saffronLight = PaletteSpec(
  colors: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFE8A33D),
    onPrimary: Color(0xFF1A1614),
    primaryContainer: Color(0xFFF7E4C2),
    onPrimaryContainer: Color(0xFF4A3208),
    secondary: Color(0xFF1A1614),
    onSecondary: Color(0xFFFBF9F6),
    secondaryContainer: Color(0xFFF0EBE3),
    onSecondaryContainer: Color(0xFF1A1614),
    tertiary: Color(0xFFB23A22),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFBF9F6),
    onSurface: Color(0xFF1A1614),
    onSurfaceVariant: Color(0xFF5C5348),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF6F2EC),
    surfaceContainer: Color(0xFFF0EBE3),
    surfaceContainerHigh: Color(0xFFE9E3D9),
    surfaceContainerHighest: Color(0xFFE2DBCF),
    surfaceDim: Color(0xFFDFD8CC),
    surfaceBright: Color(0xFFFBF9F6),
    outline: Color(0xFF776E60),
    outlineVariant: Color(0xFFE5DFD4),
    inverseSurface: Color(0xFF302A25),
    onInverseSurface: Color(0xFFF6F2EC),
    inversePrimary: Color(0xFFE8A33D),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  ),
  tokens: BrandTokens(
    sale: Color(0xFFB23A22),
    onSale: Color(0xFFFFFFFF),
    success: Color(0xFF1B7A4B),
    accentText: Color(0xFF8A5A12),
    priceStrike: Color(0xFF8C8375),
    interactiveBorder: Color(0xFF776E60),
    hairline: Color(0xFFE5DFD4),
    cardRadius: 18,
    sheetRadius: 28,
  ),
);

const _saffronDark = PaletteSpec(
  colors: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE8A33D),
    onPrimary: Color(0xFF1A1614),
    primaryContainer: Color(0xFF4A3208),
    onPrimaryContainer: Color(0xFFF7E4C2),
    secondary: Color(0xFFF5F1EA),
    onSecondary: Color(0xFF1A1614),
    secondaryContainer: Color(0xFF2B2620),
    onSecondaryContainer: Color(0xFFF5F1EA),
    tertiary: Color(0xFFFF7A5C),
    onTertiary: Color(0xFF3A0F06),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    surface: Color(0xFF100E0C),
    onSurface: Color(0xFFF5F1EA),
    onSurfaceVariant: Color(0xFFA89E90),
    surfaceContainerLowest: Color(0xFF0A0908),
    surfaceContainerLow: Color(0xFF1A1714),
    surfaceContainer: Color(0xFF221E1A),
    surfaceContainerHigh: Color(0xFF2B2620),
    surfaceContainerHighest: Color(0xFF342E27),
    surfaceDim: Color(0xFF100E0C),
    surfaceBright: Color(0xFF3A342C),
    outline: Color(0xFF7A7167),
    outlineVariant: Color(0xFF2B2620),
    inverseSurface: Color(0xFFF5F1EA),
    onInverseSurface: Color(0xFF1A1614),
    inversePrimary: Color(0xFF8A5A12),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  ),
  tokens: BrandTokens(
    sale: Color(0xFFFF7A5C),
    onSale: Color(0xFF3A0F06),
    success: Color(0xFF4ADE80),
    accentText: Color(0xFFE8A33D),
    priceStrike: Color(0xFF938A7D),
    interactiveBorder: Color(0xFF7A7167),
    hairline: Color(0xFF2B2620),
    cardRadius: 18,
    sheetRadius: 28,
  ),
);
