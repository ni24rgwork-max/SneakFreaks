import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/models/card_meta.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/providers/locker_provider.dart';
import 'package:sneakers_app/providers/orders_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/typography.dart';

/// The shelf — the pairs themselves, as photography.
///
/// The Locker holds *cards*; this holds *shoes*. A collector's page that only
/// ever shows card art is a page about the card game, not about the shoes, and
/// the shoes are the point. Nothing here is invented: brand, model and the
/// photo are the catalogue's, and the tile's colour comes out of the photo.
class ProfileShelf extends ConsumerWidget {
  const ProfileShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(lockerProvider);
    if (cards.isEmpty) return const SizedBox.shrink();

    final usualSize = ref.watch(usualSizeProvider);
    final split = <CardType, int>{};
    for (final card in cards) {
      split[card.meta.type] = (split[card.meta.type] ?? 0) + 1;
    }
    final topType =
        split.entries.reduce((a, b) => b.value > a.value ? b : a).key;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'THE SHELF',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              // Two facts a collector would actually claim, both counted from
              // real orders: the size they buy and what they mostly buy.
              if (usualSize != null) _Fact(label: 'UK $usualSize'),
              if (usualSize != null) const SizedBox(width: 6),
              _Fact(label: topType.label),
            ],
          ),
        ),
        SizedBox(
          height: 142,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _ShelfTile(card: cards[i]),
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: context.colors.onSurface,
          fontFeatures: AppTypography.tabular,
        ),
      ),
    );
  }
}

class _ShelfTile extends ConsumerWidget {
  const _ShelfTile({required this.card});

  final LockerCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(productPaletteProvider(card.product.imgAddress));
    final resolved = palette.value ?? seedPalette(card.product.modelColor);

    return GestureDetector(
      onTap: () => context.push(Routes.productPath(card.product.id)),
      child: SizedBox(
        width: 116,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: resolved.gradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.brand.hairline),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child:
                      Image.asset(card.product.imgAddress, fit: BoxFit.contain),
                ),
              ),
            ),
            Text(
              card.product.model,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
