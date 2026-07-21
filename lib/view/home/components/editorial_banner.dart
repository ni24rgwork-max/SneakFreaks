import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/product_palette.dart';
import 'package:sneakers_app/theme/typography.dart';

/// Editorial collection tile.
///
/// A merchandising slot rather than a product listing — this is where seasonal
/// and festive campaigns (Diwali, EOSS, monsoon) live. It is also the natural
/// home for the conversational-search entry point described in docs/AI.md: a
/// themed prompt is a far more inviting doorway than an empty search field.
class EditorialBanner extends ConsumerWidget {
  const EditorialBanner({
    super.key,
    required this.tag,
    required this.eyebrow,
    required this.title,
    required this.blurb,
  });

  final String tag;
  final String eyebrow;
  final String title;
  final String blurb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(collectionProvider(tag));
    // Nothing tagged for this collection under the active brand filter — say
    // nothing rather than render an empty promotional box.
    if (items.isEmpty) return const SizedBox.shrink();

    final hero = items.first;
    final palette = ref.watch(productPaletteProvider(hero.imgAddress));
    final resolved = palette.value ?? seedPalette(hero.modelColor);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          gradient: resolved.gradient,
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -34,
              bottom: -18,
              child: Opacity(
                opacity: 0.95,
                child: Transform.rotate(
                  angle: -0.24,
                  child: Image.asset(
                    hero.imgAddress,
                    width: 230,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FractionallySizedBox(
                widthFactor: 0.56,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: context.text.labelSmall?.copyWith(
                        color: resolved.onCard.withValues(alpha: 0.78),
                        letterSpacing: 1.6,
                      ),
                    ),
                    Text(
                      title,
                      style: AppTypography.wordmark(size: 26)
                          .copyWith(color: resolved.onCard),
                    ),
                    Text(
                      blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: resolved.onCard.withValues(alpha: 0.82),
                        height: 1.35,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: resolved.onCard.withValues(alpha: 0.55),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Explore ${items.length}',
                        style: context.text.labelMedium
                            ?.copyWith(color: resolved.onCard),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
