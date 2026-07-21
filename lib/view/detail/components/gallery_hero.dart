import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/product_palette.dart';

/// Collapsing product gallery.
///
/// Replaces the fixed-height image block with a decorative grey circle. Two
/// things changed: the background is the product's own extracted gradient, so
/// the page matches the feed cards it was opened from; and the image parallaxes
/// as the sheet scrolls over it, which is what makes the page feel like one
/// object rather than two stacked panels.
class GalleryHero extends ConsumerStatefulWidget {
  const GalleryHero({super.key, required this.product});

  final ShoeModel product;

  @override
  ConsumerState<GalleryHero> createState() => _GalleryHeroState();
}

class _GalleryHeroState extends ConsumerState<GalleryHero> {
  late final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final palette = ref.watch(productPaletteProvider(product.imgAddress));
    final resolved = palette.value ?? seedPalette(product.modelColor);
    final images = product.gallery;

    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      stretch: true,
      backgroundColor: resolved.top,
      foregroundColor: resolved.onCard,
      leading: _CircleButton(
        icon: Icons.arrow_back,
        palette: resolved,
        onTap: () => context.pop(),
        tooltip: 'Back',
      ),
      actions: [
        _CircleButton(
          icon: Icons.favorite_border,
          palette: resolved,
          onTap: () {},
          tooltip: 'Save',
        ),
        const SizedBox(width: 8),
      ],
      // Title appears only once collapsed. The old page painted it permanently
      // over the product photo.
      title: _CollapsedTitle(product: product, palette: resolved),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: DecoratedBox(
          decoration: BoxDecoration(gradient: resolved.gradient),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 96, 24, 44),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  itemBuilder: (context, i) => Hero(
                    // Only the first image participates — the feed carousel is
                    // the matching source.
                    tag: i == 0 ? product.id : 'gallery-${product.id}-$i',
                    child: Image.asset(images[i], fit: BoxFit.contain),
                  ),
                ),
              ),
              // A single-image product gets no dots rather than one lonely
              // dot pretending there is more to see.
              if (images.length > 1)
                Positioned(
                  bottom: 18,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SmoothPageIndicator(
                      controller: _controller,
                      count: images.length,
                      effect: ExpandingDotsEffect(
                        dotHeight: 6,
                        dotWidth: 6,
                        expansionFactor: 3,
                        spacing: 5,
                        dotColor: resolved.onCard.withValues(alpha: 0.35),
                        activeDotColor: resolved.onCard,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the product name only when the bar is collapsed, so it never sits on
/// top of the photograph.
class _CollapsedTitle extends StatelessWidget {
  const _CollapsedTitle({required this.product, required this.palette});

  final ShoeModel product;
  final ProductPalette palette;

  @override
  Widget build(BuildContext context) {
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final deltaExtent = (settings?.maxExtent ?? 400) - (settings?.minExtent ?? 88);
    final t = deltaExtent <= 0
        ? 1.0
        : (1.0 -
                ((settings?.currentExtent ?? 400) - (settings?.minExtent ?? 88)) /
                    deltaExtent)
            .clamp(0.0, 1.0);

    return Opacity(
      opacity: t,
      child: Text(
        product.model,
        style: context.text.titleMedium?.copyWith(color: palette.onCard),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.palette,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final ProductPalette palette;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        // A scrim so the control stays legible over both the gradient and the
        // product photo, whatever is behind it at that scroll position.
        color: palette.top.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          color: palette.onCard,
          tooltip: tooltip,
        ),
      ),
    );
  }
}
