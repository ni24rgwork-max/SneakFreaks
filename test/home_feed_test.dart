import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sneakers_app/data/preferences.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/home/home_screen.dart';

/// Pumps the feed on a surface tall enough that every sliver builds, so a
/// section that silently fails to render is caught here rather than by
/// scrolling a simulator and hoping.
Future<void> pumpFeed(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  tester.view.physicalSize = const Size(1200, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
    expect(find.text('MONSOON READY'), findsOneWidget);
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

    expect(container.read(trendingProvider).length, 8);

    container.read(brandFilterProvider.notifier).select('JORDAN');
    await tester.pump();

    final trending = container.read(trendingProvider);
    expect(trending.length, 4);
    expect(trending.every((p) => p.name == 'JORDAN'), isTrue);
    // Rails derive from the same filtered list, so they narrow together.
    expect(
      container.read(newArrivalsProvider).every((p) => p.name == 'JORDAN'),
      isTrue,
    );
  });

  testWidgets('sections hold distinct slices, not the same list', (tester) async {
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
