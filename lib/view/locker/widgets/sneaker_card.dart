import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sneakers_app/models/card_meta.dart';
import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/providers/orders_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/product_palette.dart';
import 'package:sneakers_app/theme/typography.dart';
import 'package:sneakers_app/view/locker/widgets/card_foil.dart';

/// A collectible card for one product.
///
/// Laid out on trading-card proportions (63×88mm ≈ 0.716), with the same zone
/// grammar as a TCG card: header, art window, info band, footer.
///
/// **Every value printed here is real catalogue data** — brand, model, price,
/// MRP, discount, size run, category, drop date. No performance figures are
/// invented. The `specs` map is deliberately absent: those are placeholders
/// until supplier data exists, and a spec block is precisely where a reader
/// assumes manufacturer fact.
class SneakerCard extends ConsumerWidget {
  const SneakerCard({
    super.key,
    required this.product,
    required this.meta,
    this.owned = true,
    this.width = 220,
  });

  final ShoeModel product;
  final CardMeta meta;

  /// Unowned cards render as dimmed silhouettes — the empty slot in a binder
  /// is most of why collecting a set is compelling.
  final bool owned;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(productPaletteProvider(product.imgAddress));
    final resolved = palette.value ?? seedPalette(product.modelColor);

    return AspectRatio(
      aspectRatio: 63 / 88,
      child: SizedBox(
        width: width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Frame: the shoe's own colour, extracted from its photography and
            // run through a shared light → mid → deep ramp. A Jordan in
            // green-and-orange gets a card that belongs to it, and the common
            // ramp is what still makes a wall of them read as one set.
            //
            // Category is carried by the type icon and the footer label
            // instead — a legend, rather than the whole colour scheme.
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: resolved.frame,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: _CardInner(
                product: product,
                meta: meta,
                palette: resolved,
              ),
            ),

            if (meta.hasFoil && owned)
              Positioned.fill(
                child: IgnorePointer(
                  child: CardFoil(
                    intensity: meta.hasFullArt ? 0.55 : 0.3,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

            if (!owned)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ColoredBox(
                    color: context.colors.surface.withValues(alpha: 0.82),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          Icon(Icons.lock_outline,
                              size: 20, color: context.colors.onSurfaceVariant),
                          Text(
                            meta.setLabel,
                            style: context.text.labelSmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                              fontFeatures: AppTypography.tabular,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardInner extends ConsumerWidget {
  const _CardInner({
    required this.product,
    required this.meta,
    required this.palette,
  });

  final ShoeModel product;
  final CardMeta meta;
  final ProductPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const ink = Color(0xFF14110F);
    final available = product.sizes.where(product.isSizeAvailable).toList();
    final swatches =
        ref.watch(productColorsProvider(product.imgAddress)).value ??
            const <Color>[];

    // Rows below the size run, in priority order, capped to what the info
    // band's slack holds. Provenance leads: it is the only part of the card
    // that is about *this* copy rather than the product, and it is the reason
    // a collector would look twice.
    //
    // Everything after it is null until real supplier data lands. A style code
    // is the field a collector trusts most, which is exactly why an invented
    // one would be the worst thing on the card.
    final extras = <Widget>[
      if (ref.watch(provenanceProvider(product.id)) case final owned?) ...[
        _Row(
          label: 'Yours',
          value: owned.sizes.isEmpty
              ? '—'
              : owned.sizes.map((s) => 'UK $s').join(', '),
          trailing: owned.copies > 1 ? '×${owned.copies}' : null,
          ink: ink,
          accent: palette.accentInk,
        ),
        _Row(
          label: 'Got',
          value: DateFormat('d MMM yyyy').format(owned.acquired),
          ink: ink,
          accent: palette.accentInk,
        ),
      ],
      if (swatches.length > 1) _SwatchRow(swatches: swatches, ink: ink),
      if (product.styleCode case final code?)
        _Row(
          label: 'Style',
          value: code,
          trailing: product.releaseYear?.toString(),
          ink: ink,
          accent: palette.accentInk,
        ),
      if (product.countryOfOrigin case final origin?)
        _Row(
            label: 'Made in',
            value: origin,
            ink: ink,
            accent: palette.accentInk),
      for (final spec in product.publishedSpecs.entries)
        _Row(
          label: spec.key,
          value: spec.value,
          ink: ink,
          accent: palette.accentInk,
        ),
    ]
        // The band holds six rows and still breathes. MRP, the size run and
        // an upcoming drop date are the product's own and always win, so what
        // is left is the budget — an upcoming shoe shows fewer extras rather
        // than pushing the footer off the card.
        //
        // The zone split moved from 5:3 to 9:7 to make this room. The visible
        // slack under the size run was about one row, not the three it looked
        // like; the art window gives up roughly 6% of the card's height.
        .take(6 -
            ((product.mrp == null ? 0 : 1) +
                1 +
                (product.dropsOn == null ? 0 : 1)))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F2),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: brand · model · price (the card-defining number) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.build().labelSmall?.copyWith(
                            color: ink.withValues(alpha: 0.6),
                            fontSize: 7,
                            letterSpacing: 0.8,
                          ),
                    ),
                    Text(
                      product.model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppTypography.wordmark(size: 13).copyWith(color: ink),
                    ),
                  ],
                ),
              ),
              Text(
                product.price.formatted,
                style: AppTypography.build().titleSmall?.copyWith(
                      color: ink,
                      fontSize: 11,
                      fontFeatures: AppTypography.tabular,
                    ),
              ),
              const SizedBox(width: 3),
              Icon(meta.type.icon, size: 11, color: palette.accentInk),
            ],
          ),
          const SizedBox(height: 5),

          // ── Art window ──
          Expanded(
            flex: 9,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: palette.gradient,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: ink.withValues(alpha: 0.28)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(product.imgAddress, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 5),

          // ── Info band: only fields the store actually publishes ──
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.mrp case final mrp?)
                  _Row(
                    label: 'MRP',
                    value: mrp.formatted,
                    trailing: product.discountPercent == null
                        ? null
                        : '${product.discountPercent}% off',
                    ink: ink,
                    accent: palette.accentInk,
                  ),
                _Row(
                  label: 'Sizes',
                  value: available.isEmpty
                      ? 'Sold out'
                      : 'UK ${available.first}–${available.last}',
                  trailing: product.soldOutSizes.isEmpty
                      ? null
                      : '${product.soldOutSizes.length} gone',
                  ink: ink,
                  accent: palette.accentInk,
                ),
                if (product.dropsOn case final date?)
                  _Row(
                    label: 'Drops',
                    value: DateFormat('d MMM yyyy').format(date),
                    ink: ink,
                    accent: palette.accentInk,
                  ),
                ...extras,
                const Spacer(),
                Container(height: 0.7, color: ink.withValues(alpha: 0.18)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      meta.setLabel,
                      style: AppTypography.build().labelSmall?.copyWith(
                            color: ink.withValues(alpha: 0.55),
                            fontSize: 6.5,
                            fontFeatures: AppTypography.tabular,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meta.type.label.toUpperCase(),
                        style: AppTypography.build().labelSmall?.copyWith(
                              color: ink.withValues(alpha: 0.55),
                              fontSize: 6.5,
                              letterSpacing: 0.6,
                            ),
                      ),
                    ),
                    for (var i = 0; i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.only(left: 1.5),
                        child: Icon(
                          i < meta.rarity.pips
                              ? Icons.circle
                              : Icons.circle_outlined,
                          size: 5,
                          color: i < meta.rarity.pips
                              ? palette.accentInk
                              : ink.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The shoe's own colours, as swatches.
///
/// Read out of the photograph rather than named, because a colourway name is
/// something a brand publishes and we do not have — three dots claim only what
/// the picture already shows.
class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.swatches, required this.ink});

  final List<Color> swatches;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              'Colour',
              style: AppTypography.build().labelSmall?.copyWith(
                    color: ink.withValues(alpha: 0.5),
                    fontSize: 6.5,
                  ),
            ),
          ),
          for (final color in swatches)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: ink.withValues(alpha: 0.25), width: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.ink,
    required this.accent,
    this.trailing,
  });

  final String label;
  final String value;
  final String? trailing;
  final Color ink;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.build();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              label,
              style: base.labelSmall?.copyWith(
                color: ink.withValues(alpha: 0.5),
                fontSize: 6.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: base.bodySmall?.copyWith(
                color: ink,
                fontSize: 8,
                fontFeatures: AppTypography.tabular,
              ),
            ),
          ),
          if (trailing case final t?)
            Text(
              t,
              style: base.labelSmall?.copyWith(color: accent, fontSize: 6.5),
            ),
        ],
      ),
    );
  }
}
