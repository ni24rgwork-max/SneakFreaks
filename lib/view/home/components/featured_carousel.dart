import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/brand_tokens.dart';
import 'package:sneakers_app/theme/product_palette.dart';
import 'package:sneakers_app/theme/typography.dart';
import 'package:sneakers_app/view/detail/detail_screen.dart';

/// The hero rail.
///
/// Two changes from the previous version worth noting: it's a snapping
/// [PageView] rather than a free-scrolling `ListView` (a hero that stops
/// half-way between two cards reads as unfinished), and card colour comes from
/// the product photography instead of a hardcoded hex per product.
class FeaturedCarousel extends ConsumerStatefulWidget {
  const FeaturedCarousel({super.key});

  @override
  ConsumerState<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends ConsumerState<FeaturedCarousel> {
  late final PageController _controller =
      PageController(viewportFraction: 0.82);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featured = ref.watch(featuredProvider);
    if (featured.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 420,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: featured.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
              child: _FeaturedCard(product: featured[i]),
            ),
          ),
        ),
        const SizedBox(height: 18),
        // The old carousel gave no indication of how many items existed or
        // where you were in them.
        SmoothPageIndicator(
          controller: _controller,
          count: featured.length,
          effect: ExpandingDotsEffect(
            dotHeight: 6,
            dotWidth: 6,
            expansionFactor: 4,
            spacing: 5,
            dotColor: context.brand.hairline,
            activeDotColor: context.colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends ConsumerWidget {
  const _FeaturedCard({required this.product});

  final ShoeModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start from the product's own colour so the first frame is already in the
    // right family, then settle on the extracted one. Nothing ever renders grey.
    final palette = ref.watch(productPaletteProvider(product.imgAddress));
    final resolved = palette.value ?? seedPalette(product.modelColor);
    final discount = product.discountPercent;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DetailScreen(model: product, isComeFromMoreSection: false),
        ),
      ),
      child: AnimatedContainer(
        duration: BrandTokens.motionSlow,
        curve: BrandTokens.motionEmphasized,
        decoration: BoxDecoration(
          gradient: resolved.gradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: resolved.bottom.withValues(alpha: 0.34),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // A soft highlight lifts the flat fill into something with depth.
            Positioned(
              top: -70,
              right: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: context.text.labelLarge?.copyWith(
                            color: resolved.onCard.withValues(alpha: 0.82),
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.favorite_border,
                        color: resolved.onCard.withValues(alpha: 0.9),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.model,
                    style: AppTypography.wordmark(size: 30)
                        .copyWith(color: resolved.onCard),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        product.price.formatted,
                        style: context.text.titleLarge?.copyWith(
                          color: resolved.onCard,
                          fontFeatures: AppTypography.tabular,
                        ),
                      ),
                      if (discount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: resolved.onCard.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$discount% OFF',
                            style: context.text.labelSmall
                                ?.copyWith(color: resolved.onCard),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Hero(
                      tag: product.id,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Image.asset(
                          product.imgAddress,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: resolved.onCard,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          Text(
                            'View',
                            style: context.text.labelMedium
                                ?.copyWith(color: resolved.top),
                          ),
                          Icon(Icons.arrow_forward,
                              size: 15, color: resolved.top),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
