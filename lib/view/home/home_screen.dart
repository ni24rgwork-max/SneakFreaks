import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/home/components/app_bar.dart';
import 'package:sneakers_app/view/home/components/brand_rail.dart';
import 'package:sneakers_app/view/home/components/editorial_banner.dart';
import 'package:sneakers_app/view/home/components/featured_carousel.dart';
import 'package:sneakers_app/view/home/components/feed_tabs.dart';
import 'package:sneakers_app/view/home/components/product_card.dart';
import 'package:sneakers_app/view/home/components/product_rail.dart';
import 'package:sneakers_app/view/home/components/section_header.dart';

/// The storefront feed.
///
/// A [CustomScrollView] of independent slivers, replacing the fixed-height
/// `Column` whose sections were each sized as a fraction of *full screen*
/// height — those fractions summed past the space the Scaffold body actually
/// gets, which is what caused the original 42px overflow. Sections now size to
/// their content and the feed scrolls as far as it needs to.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingNow = ref.watch(catalogueLoadingProvider);
    final placeholders = ref.watch(feedPlaceholdersProvider);

    // While loading, the rails render placeholder rows for Skeletonizer to
    // paint. The real providers stay empty so nothing downstream sees fakes.
    List<ShoeModel> orPlaceholder(List<ShoeModel> real) =>
        loadingNow ? placeholders : real;

    final newArrivals = orPlaceholder(ref.watch(newArrivalsProvider));
    final budget = orPlaceholder(ref.watch(underBudgetProvider));
    final trending = orPlaceholder(ref.watch(trendingProvider));
    final brand = ref.watch(brandFilterProvider);
    final loading = loadingNow;

    return SafeArea(
      child: Scaffold(
        appBar: customAppBar(context),
        // Skeletonizer builds the placeholder from the real widget tree, so the
        // loading state cannot drift away from the loaded one — the failure
        // mode of hand-built grey mocks.
        body: Skeletonizer(
          enabled: loading,
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(catalogueAsyncProvider.notifier).refresh(),
            child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: BrandRail()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            const SliverToBoxAdapter(child: FeedTabs()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(child: FeaturedCarousel()),

            if (newArrivals.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'New Arrivals',
                  subtitle: 'Fresh drops this week',
                  onSeeAll: () {},
                ),
              ),
              SliverToBoxAdapter(child: ProductRail(products: newArrivals)),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
            const SliverToBoxAdapter(
              child: EditorialBanner(
                tag: 'monsoon',
                eyebrow: 'Collection',
                title: 'MONSOON READY',
                blurb: 'Grip and water resistance for the season.',
              ),
            ),

            if (budget.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Under ₹10,000',
                  subtitle: 'Premium picks, sensible spend',
                  onSeeAll: () {},
                ),
              ),
              SliverToBoxAdapter(child: ProductRail(products: budget)),
            ],

            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Trending',
                subtitle: brand == null
                    ? '${trending.length} pairs in stock'
                    : '${trending.length} from $brand',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.64,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ProductCard(product: trending[i]),
                  childCount: trending.length,
                ),
              ),
            ),

            if (trending.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text(
                      'Nothing in stock for $brand yet',
                      style: context.text.bodyMedium
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
