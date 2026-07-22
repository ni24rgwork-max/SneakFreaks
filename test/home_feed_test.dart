import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/home/home_screen.dart';

/// Pumps the feed on a surface tall enough that every sliver builds, so a
/// section that silently fails to render is caught here rather than by
/// scrolling a simulator and hoping.
Future<void> pumpFeed(WidgetTester tester) async {
  final overrides = await testOverrides();

  tester.view.physicalSize = const Size(1200, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.of(Brightness.light),
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('feed renders every section', (tester) async {
    await pumpFeed(tester);

    expect(find.text('SneakFreaks'), findsOneWidget);
    expect(find.text('New Arrivals'), findsOneWidget);
    expect(find.text('COURT CLASSICS'), findsOneWidget);
    expect(find.text('Under ₹10,000'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
  });

  testWidgets('brand rail lists only brands that have stock', (tester) async {
    await pumpFeed(tester);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('NIKE'), findsWidgets);
    expect(find.text('JORDAN'), findsWidgets);
    // The old home screen advertised these against zero inventory.
    expect(find.text('Gucci'), findsNothing);
    expect(find.text('Tom Ford'), findsNothing);
    expect(find.text('Koio'), findsNothing);
  });

  testWidgets('selecting a brand narrows the whole feed', (tester) async {
    await pumpFeed(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );

    // Asserted structurally rather than against fixture counts, so growing
    // the catalogue is not a test failure.
    final all = container.read(catalogueProvider);
    expect(all.length, greaterThan(50));
    final unfiltered = container.read(trendingProvider).length;
    expect(unfiltered, greaterThan(0));

    container.read(brandFilterProvider.notifier).select('JORDAN');
    await tester.pump();

    final trending = container.read(trendingProvider);
    expect(trending, isNotEmpty);
    expect(trending.length, lessThan(unfiltered));
    expect(trending.every((p) => p.name == 'JORDAN'), isTrue);
    // Rails derive from the same filtered list, so they narrow together.
    expect(
      container.read(newArrivalsProvider).every((p) => p.name == 'JORDAN'),
      isTrue,
    );
  });

  testWidgets('hero tabs each resolve to a different slice', (tester) async {
    await pumpFeed(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    final tabs = container.read(featuredTabProvider.notifier);

    expect(find.text('New'), findsWidgets);
    expect(find.text('Featured'), findsWidgets);
    expect(find.text('Upcoming'), findsWidgets);

    tabs.select(FeaturedTab.newIn);
    await tester.pump();
    final newIn = container.read(featuredProvider);
    expect(newIn, isNotEmpty);
    expect(newIn.every((p) => p.isNew && !p.isUpcoming), isTrue);

    tabs.select(FeaturedTab.upcoming);
    await tester.pump();
    final upcoming = container.read(featuredProvider);
    expect(upcoming, isNotEmpty);
    expect(upcoming.every((p) => p.isUpcoming), isTrue);

    tabs.select(FeaturedTab.featured);
    await tester.pump();
    final featured = container.read(featuredProvider);
    expect(featured.every((p) => !p.isUpcoming), isTrue);

    // The original rotated selector left every slice identical.
    expect(newIn.map((p) => p.id).toSet(),
        isNot(equals(upcoming.map((p) => p.id).toSet())));
  });

  testWidgets('unreleased drops never reach a buyable surface', (tester) async {
    await pumpFeed(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );

    for (final list in [
      container.read(trendingProvider),
      container.read(newArrivalsProvider),
      container.read(underBudgetProvider),
      container.read(collectionProvider('court')),
    ]) {
      expect(list.any((p) => p.isUpcoming), isFalse);
    }
  });

  testWidgets('tab and brand filters compose', (tester) async {
    await pumpFeed(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );

    // Pick a brand that actually has an unreleased drop, rather than
    // hardcoding one and breaking whenever the catalogue is regenerated.
    final brand =
        container.read(catalogueProvider).firstWhere((p) => p.isUpcoming).name;

    container.read(featuredTabProvider.notifier).select(FeaturedTab.upcoming);
    container.read(brandFilterProvider.notifier).select(brand);
    await tester.pump();

    final result = container.read(featuredProvider);
    expect(result, isNotEmpty);
    expect(result.every((p) => p.name == brand && p.isUpcoming), isTrue);
  });

  testWidgets('sections hold distinct slices, not the same list',
      (tester) async {
    await pumpFeed(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );

    // The original home screen rendered `availableShoes` unfiltered in both
    // the carousel and the grid, so every section showed identical products.
    final newArrivals = container.read(newArrivalsProvider);
    final budget = container.read(underBudgetProvider);
    final all = container.read(trendingProvider);

    expect(newArrivals.length, lessThan(all.length));
    expect(budget.length, lessThan(all.length));
    expect(budget.every((p) => p.price.paise <= underBudget.paise), isTrue);
    expect(newArrivals.every((p) => p.isNew), isTrue);
  });
}
