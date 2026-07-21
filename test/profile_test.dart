import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sneakers_app/data/preferences.dart';
import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/providers/orders_provider.dart';
import 'package:sneakers_app/providers/profile_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/locker/widgets/sneaker_card.dart';
import 'package:sneakers_app/view/profile/profile_screen.dart';

import 'harness.dart';

Future<ProviderContainer> pumpProfile(WidgetTester tester) async {
  final overrides = await testOverrides();
  tester.view.physicalSize = const Size(1200, 5000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.of(Brightness.light),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: ProfileScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('collector tier', () {
    test('rises with pairs held, never with money spent', () {
      expect(CollectorTier.forPairs(0), CollectorTier.newcomer);
      expect(CollectorTier.forPairs(1), CollectorTier.rookie);
      expect(CollectorTier.forPairs(4), CollectorTier.runner);
      expect(CollectorTier.forPairs(5), CollectorTier.collector);
      expect(CollectorTier.forPairs(999), CollectorTier.archivist);
    });

    test('reports the gap to the next tier, and nothing at the top', () {
      expect(CollectorTier.rookie.pairsToNext(1), 1); // → runner at 2
      expect(CollectorTier.runner.pairsToNext(2), 3); // → collector at 5
      expect(CollectorTier.archivist.pairsToNext(50), isNull);
    });
  });

  testWidgets('the locker is a section of the profile, not the whole page',
      (tester) async {
    await pumpProfile(tester);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('The Locker'), findsOneWidget);
    // The rest of the page exists alongside it.
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Bag'), findsOneWidget);
  });

  testWidgets('with nothing bought, both showcase and locker prompt',
      (tester) async {
    final c = await pumpProfile(tester);

    expect(c.read(profileShowcaseProvider), ProfileShowcase.locker);
    expect(find.byType(SneakerCard), findsNothing);
    expect(find.text('Nothing to showcase yet'), findsOneWidget);
    expect(find.text('No cards yet'), findsOneWidget);
  });

  testWidgets('buying a pair fills the locker section', (tester) async {
    final c = await pumpProfile(tester);
    final product = c.read(catalogueProvider).first;

    c.read(cartProvider.notifier).add(product, size: '8');
    c.read(ordersProvider.notifier).place(nowMillis: 1000);
    await tester.pumpAndSettle();

    // Shown once. In Locker mode the cards lead the page, so the section below
    // is the binder's summary rather than the same card art a second time.
    expect(find.byType(SneakerCard), findsOneWidget);
    expect(find.text('No cards yet'), findsNothing);
    expect(find.text('1 of 8 collected'), findsOneWidget);
    expect(find.text('Set completion'), findsOneWidget);
  });

  testWidgets('the showcase is the user\'s choice and it persists',
      (tester) async {
    final c = await pumpProfile(tester);
    final catalogue = c.read(catalogueProvider);
    c.read(cartProvider.notifier).add(catalogue.first, size: '8');
    c.read(ordersProvider.notifier).place(nowMillis: 2000);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('Showcase'), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(c.read(profileShowcaseProvider), ProfileShowcase.stats);
    // Stats lead, and the card art moves down into the Locker rail.
    expect(find.text('pairs'), findsOneWidget);
    expect(find.byType(SneakerCard), findsOneWidget);
    expect(find.text('Set completion'), findsNothing);

    // Written through to preferences, so the choice survives a restart.
    // Reuses the same store rather than calling testOverrides() again, which
    // resets the mock and would make any implementation look persistent.
    final prefs = c.read(sharedPreferencesProvider);
    final fresh = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(fresh.dispose);
    expect(fresh.read(profileShowcaseProvider), ProfileShowcase.stats);
  });

  testWidgets('minimal hides the showcase entirely', (tester) async {
    final c = await pumpProfile(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Minimal'));
    await tester.pumpAndSettle();

    expect(c.read(profileShowcaseProvider), ProfileShowcase.minimal);
    expect(find.text('Nothing to showcase yet'), findsNothing);
    // The locker section is a section, not the showcase — it stays.
    expect(find.text('The Locker'), findsOneWidget);
  });

  test('the locker has its own address under the profile', () {
    expect(Routes.lockerPath, '/profile/locker');
  });
}
