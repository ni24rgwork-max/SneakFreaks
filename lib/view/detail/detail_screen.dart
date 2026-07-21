import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/motion.dart';
import 'package:sneakers_app/view/detail/components/buy_bar.dart';
import 'package:sneakers_app/view/detail/components/detail_sections.dart';
import 'package:sneakers_app/view/detail/components/gallery_hero.dart';
import 'package:sneakers_app/view/detail/components/pincode_check.dart';
import 'package:sneakers_app/view/detail/components/price_block.dart';
import 'package:sneakers_app/view/detail/components/size_selector.dart';
import 'package:sneakers_app/view/detail/components/trust_row.dart';
import 'package:sneakers_app/view/home/components/product_rail.dart';
import 'package:sneakers_app/view/home/components/section_header.dart';

/// Product detail.
///
/// Takes a **product id**, not a `ShoeModel` — a route has to be
/// reconstructable from a URL string, so `/product/sku-001` arriving from a
/// share link, push notification or payment return resolves the product here.
///
/// Structure is a `CustomScrollView`: a collapsing gallery hero, then content
/// slivers, with the purchase bar pinned outside the scroll view. The previous
/// version was a `Column` inside `Container(height: height * 1.1)`, so content
/// physically could not grow — the description was sliced mid-sentence by a
/// `height / 9` box.
class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId));

    // A deep link can name a delisted or mistyped product. Say so.
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 44, color: context.colors.onSurfaceVariant),
                Text('This product is no longer available',
                    textAlign: TextAlign.center,
                    style: context.text.titleMedium),
                FilledButton(
                  onPressed: () => context.go(Routes.home),
                  child: const Text('Browse the store'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final related = ref.watch(relatedProvider(productId));

    // Sections enter in sequence so the eye lands on price, then size, then
    // supporting detail — instead of the whole page arriving at once.
    // `enter` handles the reduced-motion check centrally.
    Widget stagger(Widget child, int index) => child.enter(context, index: index);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GalleryHero(product: product),
          SliverToBoxAdapter(child: stagger(PriceBlock(product: product), 0)),
          SliverToBoxAdapter(
            child: stagger(
              TrustRow(
                  inStock:
                      product.soldOutSizes.length < product.sizes.length),
              1,
            ),
          ),
          if (!product.isUpcoming)
            SliverToBoxAdapter(
              child: stagger(SizeSelector(product: product), 2),
            ),
          SliverToBoxAdapter(child: stagger(const PincodeCheck(), 3)),
          SliverToBoxAdapter(
            child: stagger(DetailSections(product: product), 4),
          ),
          if (related.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'You may also like'),
            ),
            SliverToBoxAdapter(child: ProductRail(products: related)),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
      // Outside the scroll view, so it never leaves the screen.
      bottomNavigationBar: BuyBar(product: product),
    );
  }
}
