import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/data/dummy_data.dart';
import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/theme/product_palette.dart';
import 'package:sneakers_app/utils/money.dart';

/// The catalogue as it actually behaves once remote: asynchronous, with a
/// loading state the UI has to render.
///
/// Backed by the in-memory fixture for now. Swapping in an HTTP call means
/// replacing the body of [load] — nothing downstream changes, because every
/// consumer already reads through the providers below.
class CatalogueController extends AsyncNotifier<List<ShoeModel>> {
  @override
  Future<List<ShoeModel>> build() => load();

  Future<List<ShoeModel>> load() async {
    // A deliberate delay so the skeleton states are exercised in development
    // rather than only appearing for the first time against a real network.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return availableShoes;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(load);
  }
}

final catalogueAsyncProvider =
    AsyncNotifierProvider<CatalogueController, List<ShoeModel>>(
        CatalogueController.new);

/// Synchronous view of the catalogue, for logic that does not care about the
/// loading state. Every derived provider below reads this, so making the source
/// asynchronous did not ripple through them.
final catalogueProvider = Provider<List<ShoeModel>>(
    (ref) => ref.watch(catalogueAsyncProvider).value ?? const []);

/// Whether the feed should render skeletons.
final catalogueLoadingProvider =
    Provider<bool>((ref) => ref.watch(catalogueAsyncProvider).isLoading);

/// Stand-in rows for the loading state.
///
/// Skeletonizer paints the real widget tree grey, so it needs *something* to
/// lay out. These never reach business logic — `catalogueProvider` stays empty
/// while loading, so the cart can never resolve a line against a fake product.
final feedPlaceholdersProvider = Provider<List<ShoeModel>>((ref) {
  return List.generate(
    4,
    (i) => ShoeModel(
      id: 'placeholder-\$i',
      name: 'BRAND',
      model: 'Loading product',
      price: const Money(999900),
      imgAddress: availableShoes.first.imgAddress,
      modelColor: const Color(0xFF6B7280),
    ),
    growable: false,
  );
});

/// Product lookup by id, used by the cart to resolve its lines.
final productByIdProvider = Provider.family<ShoeModel?, String>((ref, id) {
  final catalogue = ref.watch(catalogueProvider);
  for (final p in catalogue) {
    if (p.id == id) return p;
  }
  return null;
});

/// Brands that actually have stock, in catalogue order.
///
/// Derived rather than hardcoded on purpose. The previous home screen shipped a
/// static list of seven brand names against a catalogue containing exactly one
/// brand — a storefront that advertises what it cannot sell. This list grows
/// when inventory does and never overstates it.
final brandsProvider = Provider<List<String>>((ref) {
  final seen = <String>{};
  for (final p in ref.watch(catalogueProvider)) {
    seen.add(p.name);
  }
  return seen.toList(growable: false);
});

/// Selected brand filter. `null` means "All".
class BrandFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? brand) => state = brand;
  void toggle(String brand) => state = state == brand ? null : brand;
}

final brandFilterProvider =
    NotifierProvider<BrandFilter, String?>(BrandFilter.new);

/// The catalogue with the active brand filter applied. Every rail below reads
/// from this, so selecting a brand narrows the whole feed at once.
final filteredCatalogueProvider = Provider<List<ShoeModel>>((ref) {
  final all = ref.watch(catalogueProvider);
  final brand = ref.watch(brandFilterProvider);
  if (brand == null) return all;
  return [
    for (final p in all)
      if (p.name == brand) p,
  ];
});

// --- Hero tabs -----------------------------------------------------------

/// The three views of the hero carousel.
///
/// The original home screen had these as rotated vertical text that only ever
/// restyled itself — tapping never changed a product. Here each tab resolves to
/// a genuinely different slice.
enum FeaturedTab {
  newIn('New'),
  featured('Featured'),
  upcoming('Upcoming');

  const FeaturedTab(this.label);
  final String label;
}

class FeaturedTabController extends Notifier<FeaturedTab> {
  @override
  FeaturedTab build() => FeaturedTab.featured;

  void select(FeaturedTab tab) => state = tab;
}

final featuredTabProvider =
    NotifierProvider<FeaturedTabController, FeaturedTab>(
        FeaturedTabController.new);

/// Stock that can actually be bought right now. Announced-but-unreleased
/// products are excluded from every buyable surface — showing an add-to-bag
/// path for something with no release date is a support ticket waiting to
/// happen.
final buyableProvider = Provider<List<ShoeModel>>((ref) {
  return [
    for (final p in ref.watch(filteredCatalogueProvider))
      if (!p.isUpcoming) p,
  ];
});

// --- Feed sections -------------------------------------------------------
// Each rail is a distinct slice. Previously every section rendered the same
// unfiltered list, so "More" and the carousel showed identical products.

final featuredProvider = Provider<List<ShoeModel>>((ref) {
  final tab = ref.watch(featuredTabProvider);

  switch (tab) {
    case FeaturedTab.upcoming:
      return [
        for (final p in ref.watch(filteredCatalogueProvider))
          if (p.isUpcoming) p,
      ];
    case FeaturedTab.newIn:
      return [
        for (final p in ref.watch(buyableProvider))
          if (p.isNew) p,
      ];
    case FeaturedTab.featured:
      final buyable = ref.watch(buyableProvider);
      // Lead with discounted stock — the % off is the primary decision driver
      // in Indian e-commerce, so it belongs in the hero.
      final discounted = [
        for (final p in buyable)
          if (p.discountPercent != null) p,
      ];
      return discounted.isEmpty ? buyable : discounted;
  }
});

final newArrivalsProvider = Provider<List<ShoeModel>>((ref) {
  final items = ref.watch(buyableProvider);
  return [
    for (final p in items)
      if (p.isNew) p,
  ];
});

/// Price-band rail. A near-universal fixture of Indian storefronts.
const underBudget = Money(1000000); // ₹10,000

final underBudgetProvider = Provider<List<ShoeModel>>((ref) {
  final items = ref.watch(buyableProvider);
  return [
    for (final p in items)
      if (p.price.paise <= underBudget.paise) p,
  ];
});

final collectionProvider = Provider.family<List<ShoeModel>, String>((ref, tag) {
  final items = ref.watch(buyableProvider);
  return [
    for (final p in items)
      if (p.tags.contains(tag)) p,
  ];
});

/// Everything, for the trending grid at the foot of the feed.
final trendingProvider = Provider<List<ShoeModel>>((ref) {
  return ref.watch(buyableProvider);
});

/// Siblings for the "You may also like" rail: same brand first, then anything
/// else buyable, never the product being viewed.
final relatedProvider =
    Provider.family<List<ShoeModel>, String>((ref, productId) {
  final all = ref.watch(catalogueProvider);
  final current = ref.watch(productByIdProvider(productId));
  if (current == null) return const [];

  final sameBrand = <ShoeModel>[];
  final others = <ShoeModel>[];
  for (final p in all) {
    if (p.id == productId || p.isUpcoming) continue;
    (p.name == current.name ? sameBrand : others).add(p);
  }
  return [...sameBrand, ...others].take(6).toList(growable: false);
});

// --- Product palette -----------------------------------------------------

/// Card treatment derived from a product's photography, cached per asset.
///
/// Decoding happens once per image for the app's lifetime — `keepAlive` matters
/// here because the carousel rebuilds on every page change and re-decoding on
/// each would be visible.
///
/// TODO(backend): move extraction to ingestion time and serve the two hex
/// values on the product record. Doing image work on the client is a fixture-era
/// convenience, not the shipping design — see docs/AI.md.
final productColorsProvider =
    FutureProvider.family<List<Color>, String>((ref, assetPath) async {
  ref.keepAlive();
  return productColors(assetPath);
});

final productPaletteProvider =
    FutureProvider.family<ProductPalette, String>((ref, assetPath) async {
  // Derived from the same decode rather than a second one.
  final colors = await ref.watch(productColorsProvider(assetPath).future);
  return ProductPalette.fromSeed(colors.first);
});

/// Synchronous stand-in used for the first frame.
///
/// `modelColor` is already roughly the shoe's colour, so running it through the
/// same tonal treatment gives a card that is close to the final one. The
/// extracted version then refines it — the transition is a shade shift rather
/// than a grey-to-colour pop.
ProductPalette seedPalette(Color modelColor) =>
    ProductPalette.fromSeed(modelColor);
