import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sneakers_app/models/card_meta.dart';
import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
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
    final type = meta.type;

    return AspectRatio(
      aspectRatio: 63 / 88,
      child: SizedBox(
        width: width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Frame: the type colour is what makes a wall of these read as one
            // set rather than a pile of unrelated tiles.
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(type.color, Colors.white, 0.22)!,
                    type.color,
                    Color.lerp(type.color, Colors.black, 0.42)!,
                  ],
                ),
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

class _CardInner extends StatelessWidget {
  const _CardInner({
    required this.product,
    required this.meta,
    required this.palette,
  });

  final ShoeModel product;
  final CardMeta meta;
  final ProductPalette palette;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF14110F);
    final available = product.sizes.where(product.isSizeAvailable).toList();

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
                      style: AppTypography.wordmark(size: 13)
                          .copyWith(color: ink),
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
              Icon(meta.type.icon, size: 11, color: meta.type.color),
            ],
          ),
          const SizedBox(height: 5),

          // ── Art window ──
          Expanded(
            flex: 5,
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
            flex: 3,
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
                    accent: meta.type.color,
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
                  accent: meta.type.color,
                ),
                if (product.dropsOn case final date?)
                  _Row(
                    label: 'Drops',
                    value: DateFormat('d MMM yyyy').format(date),
                    ink: ink,
                    accent: meta.type.color,
                  ),
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
                              ? meta.type.color
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
              style: base.labelSmall
                  ?.copyWith(color: accent, fontSize: 6.5),
            ),
        ],
      ),
    );
  }
}
