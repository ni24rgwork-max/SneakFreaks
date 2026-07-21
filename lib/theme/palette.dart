import 'package:flutter/material.dart';

import 'brand_tokens.dart';

/// A resolved palette for one brightness.
class PaletteSpec {
  const PaletteSpec({required this.colors, required this.tokens});
  final ColorScheme colors;
  final BrandTokens tokens;
}

PaletteSpec paletteSpec(Brightness brightness) =>
    brightness == Brightness.dark ? _dark : _light;

// ---------------------------------------------------------------------------
// "Ink" — monochrome premium.
//
// The storefront carries Nike, Adidas, Jordan, Puma and others, so the chrome
// cannot be seen to favour any one brand's colours. Surfaces are warm neutrals
// and the only chroma in the chrome is `sale`; product photography supplies
// the rest.
//
// Every foreground/background pair was checked against WCAG: body text lands
// at 16-18:1, muted text ~7:1, interactive borders >4:1 (3:1 is the non-text
// minimum). Hand-authored rather than ColorScheme.fromSeed output, whose
// neutrals get tinted toward the seed hue — the faint purple-grey cast that
// makes an app read as default Flutter.
// ---------------------------------------------------------------------------

const _light = PaletteSpec(
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

const _dark = PaletteSpec(
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
