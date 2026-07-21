import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// A card treatment derived from a product's own photography.
///
/// The rule the design system runs on is that chrome stays neutral and the
/// *product* supplies the colour. Featured cards follow it literally: the
/// gradient comes from the shoe in the photo, not from a hardcoded brand hex.
@immutable
class ProductPalette {
  const ProductPalette({
    required this.top,
    required this.bottom,
    required this.onCard,
    required this.accent,
  });

  final Color top;
  final Color bottom;

  /// Label colour, chosen by measured contrast against [top] — never assumed.
  final Color onCard;

  /// The product's own hue at full strength, for small accents.
  final Color accent;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [top, bottom],
      );

  /// Frame treatment for a collectible card.
  ///
  /// The shoe's own hue run through a light → mid → deep ramp, so a Jordan in
  /// green-and-orange gets a card that belongs to it. Every card shares the same
  /// ramp, which is what keeps a wall of them reading as one set now that the
  /// colour is no longer a fixed per-category hex.
  LinearGradient get frame => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(accent, const Color(0xFFFFFFFF), 0.22)!,
          accent,
          Color.lerp(accent, const Color(0xFF000000), 0.42)!,
        ],
      );

  /// The product's hue, darkened enough to sit on the card's cream stock.
  ///
  /// [accent] is tuned for use *on the dark card*, where L=0.52 reads well.
  /// The same value on near-white measures around 3:1 — fine for a swatch,
  /// not for the discount figure, which is text people are meant to read.
  Color get accentInk =>
      HSLColor.fromColor(accent).withLightness(0.36).toColor();

  /// Builds a card treatment from an arbitrary seed colour.
  ///
  /// The seed's **hue is kept and its lightness/saturation are replaced.** That
  /// is the whole trick: a raw extracted colour is unusable directly — a white
  /// sneaker yields a near-white swatch that no label can sit on, and a
  /// fluorescent one yields something that reads cheap. Forcing every card into
  /// a deep, controlled tonal band means the colour still belongs to the shoe
  /// while every card lands in the same premium register and stays legible.
  factory ProductPalette.fromSeed(Color seed) {
    final hsl = HSLColor.fromColor(seed);

    // A greyscale shoe (all-white, all-black) yields near-zero saturation.
    // Left alone that produces a flat grey card, so it gets a floor — enough
    // chroma to read as a deliberate charcoal rather than a dead rectangle.
    final saturation =
        hsl.saturation < 0.08 ? 0.10 : hsl.saturation.clamp(0.30, 0.68);

    final top = hsl.withSaturation(saturation).withLightness(0.30).toColor();
    final bottom =
        hsl.withSaturation(saturation * 0.85).withLightness(0.15).toColor();
    final accent = hsl
        .withSaturation(saturation.clamp(0.45, 0.85))
        .withLightness(0.52)
        .toColor();

    return ProductPalette(
      top: top,
      bottom: bottom,
      onCard: _readableOn(top),
      accent: accent,
    );
  }

  /// Picks white or near-black by contrast ratio rather than assuming white.
  /// At L=0.30 white almost always wins, but "almost always" is not a
  /// guarantee worth shipping — a light-hued seed can still cross the line.
  static Color _readableOn(Color background) {
    const light = Color(0xFFFFFFFF);
    const dark = Color(0xFF14110F);
    return _contrast(light, background) >= _contrast(dark, background)
        ? light
        : dark;
  }

  static double _contrast(Color a, Color b) {
    final la = _relativeLuminance(a);
    final lb = _relativeLuminance(b);
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  static double _relativeLuminance(Color c) {
    double channel(double v) => v <= 0.04045
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }
}

/// The colours a shopper would call "the colours of this shoe", strongest
/// first.
///
/// Not the average pixel and not the most common one — product shots are
/// cut-outs that are mostly white midsole and transparent background, so both
/// of those return grey. This instead buckets by hue and scores each bucket by
/// how saturated its pixels are, which is what actually surfaces the red heel
/// on an Air Max or the green collar on a Jordan.
///
/// Returns up to [count] distinct hues. Buckets nearer than 40° are folded
/// together: two adjacent 15° buckets are the same colour to a human eye, and
/// three swatches that all read "orange" say nothing.
Future<List<Color>> productColors(String assetPath, {int count = 3}) async {
  final data = await rootBundle.load(assetPath);

  // 64px is plenty — the output is one hue, and decoding full-size product
  // photography on the UI isolate for that would be indefensible.
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: 64,
    targetHeight: 64,
  );
  final frame = await codec.getNextFrame();
  final bytes =
      await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  frame.image.dispose();
  codec.dispose();

  if (bytes == null) return const [Color(0xFF6B7280)];

  const buckets = 24; // 15° of hue each
  final weight = List<double>.filled(buckets, 0);
  final sumH = List<double>.filled(buckets, 0);

  final pixels = bytes.buffer.asUint8List();
  for (var i = 0; i < pixels.length; i += 4) {
    final a = pixels[i + 3];
    if (a < 200) continue; // transparent cut-out background

    final color = Color.fromARGB(
      255,
      pixels[i],
      pixels[i + 1],
      pixels[i + 2],
    );
    final hsl = HSLColor.fromColor(color);

    // Skip the midsole and the shadow: near-greys and near-blacks carry no hue
    // information and would otherwise dominate by sheer pixel count.
    if (hsl.saturation < 0.25) continue;
    if (hsl.lightness < 0.12 || hsl.lightness > 0.92) continue;

    final bucket = ((hsl.hue / 360) * buckets).floor().clamp(0, buckets - 1);
    // Weight by saturation so a small vivid accent beats a large washed area.
    final w = hsl.saturation * hsl.saturation;
    weight[bucket] += w;
    sumH[bucket] += hsl.hue * w;
  }

  final ranked = [
    for (var i = 0; i < buckets; i++)
      if (weight[i] > 0) (hue: sumH[i] / weight[i], weight: weight[i]),
  ]..sort((a, b) => b.weight.compareTo(a.weight));

  // Genuinely achromatic product (all-white or all-black shoe) — hand back a
  // neutral and let fromSeed's saturation floor turn it into charcoal.
  if (ranked.isEmpty) return const [Color(0xFF6B7280)];

  final picked = <double>[];
  for (final entry in ranked) {
    if (picked.length >= count) break;
    // Hue is circular, so 350° and 10° are 20° apart, not 340°.
    final tooClose = picked.any((h) {
      final d = (h - entry.hue).abs();
      return (d > 180 ? 360 - d : d) < 40;
    });
    if (!tooClose) picked.add(entry.hue);
  }

  return [
    for (final hue in picked) HSLColor.fromAHSL(1, hue, 0.6, 0.45).toColor(),
  ];
}

/// The single colour that defines the shoe — the strongest hue it carries.
Future<Color> dominantProductColor(String assetPath) async =>
    (await productColors(assetPath, count: 1)).first;
