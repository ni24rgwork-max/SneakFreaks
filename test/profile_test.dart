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
    expect(find.textContaining('There are 8 in the set'), findsOneWidget);
  });

  testWidgets('buying a pair fills the locker section', (tester) async {
    final c = await pumpProfile(tester);
    final product = c.read(catalogueProvider).first;

    c.read(cartProvider.notifier).add(product, size: '8');
    c.read(ordersProvider.notifier).place(nowMillis: 1000);
    await tester.pumpAndSettle();

    // Exactly one card on the profile — the pick, not the collection. The
    // section below reports what the binder holds instead of repeating it.
    expect(find.byType(SneakerCard), findsOneWidget);
    expect(find.textContaining('1 of 8 collected'), findsOneWidget);
    expect(find.text('1/8'), findsOneWidget);
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
    // Numbers lead instead of the card, and no card art remains.
    expect(find.text('of the set'), findsOneWidget);
    expect(find.byType(SneakerCard), findsNothing);

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

  group('the profile shows one card, chosen by the user', () {
    testWidgets('with no pick, the rarest card stands in', (tester) async {
      final c = await pumpProfile(tester);
      final catalogue = c.read(catalogueProvider);

      // sku-001 (₹12,995, Rare) and sku-004 (₹8,995, Common).
      for (final id in ['sku-004', 'sku-001']) {
        c
            .read(cartProvider.notifier)
            .add(catalogue.firstWhere((p) => p.id == id), size: '8');
      }
      c.read(ordersProvider.notifier).place(nowMillis: 1000);
      await tester.pumpAndSettle();

      expect(c.read(featuredCardIdProvider), isNull);
      expect(c.read(featuredCardProvider)?.product.id, 'sku-001');
      expect(find.byType(SneakerCard), findsOneWidget);
      expect(find.text('YOUR RAREST'), findsOneWidget);
      expect(find.text('Pick'), findsOneWidget);
    });

    testWidgets('a pick wins over the rarest, and persists', (tester) async {
      final c = await pumpProfile(tester);
      final catalogue = c.read(catalogueProvider);
      for (final id in ['sku-004', 'sku-001']) {
        c
            .read(cartProvider.notifier)
            .add(catalogue.firstWhere((p) => p.id == id), size: '8');
      }
      c.read(ordersProvider.notifier).place(nowMillis: 2000);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(find.text('Your card'), findsOneWidget);

      // Every owned card is offered; tapping one closes the sheet.
      expect(find.byType(SneakerCard), findsNWidgets(3)); // 1 shown + 2 offered
      await tester.tap(find.byType(SneakerCard).last);
      await tester.pumpAndSettle();

      expect(c.read(featuredCardIdProvider), 'sku-004');
      expect(c.read(featuredCardProvider)?.product.id, 'sku-004');
      expect(find.text('YOUR CARD'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.byType(SneakerCard), findsOneWidget);

      final prefs = c.read(sharedPreferencesProvider);
      final fresh = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(fresh.dispose);
      expect(fresh.read(featuredCardIdProvider), 'sku-004');
    });

    testWidgets('a pick that is no longer owned cannot linger', (tester) async {
      final c = await pumpProfile(tester);
      final catalogue = c.read(catalogueProvider);

      await c.read(featuredCardIdProvider.notifier).select('sku-007');
      c.read(cartProvider.notifier).add(catalogue.first, size: '8');
      c.read(ordersProvider.notifier).place(nowMillis: 3000);
      await tester.pumpAndSettle();

      // The id is still stored, but the card shown is one actually held.
      expect(c.read(featuredCardIdProvider), 'sku-007');
      expect(c.read(featuredCardProvider)?.product.id, catalogue.first.id);
    });

    testWidgets('the pick can be handed back to the rarest', (tester) async {
      final c = await pumpProfile(tester);
      final catalogue = c.read(catalogueProvider);
      for (final id in ['sku-004', 'sku-001']) {
        c
            .read(cartProvider.notifier)
            .add(catalogue.firstWhere((p) => p.id == id), size: '8');
      }
      c.read(ordersProvider.notifier).place(nowMillis: 4000);
      await c.read(featuredCardIdProvider.notifier).select('sku-004');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use my rarest instead'));
      await tester.pumpAndSettle();

      expect(c.read(featuredCardIdProvider), isNull);
      expect(c.read(featuredCardProvider)?.product.id, 'sku-001');
    });
  });

  group('the shelf', () {
    testWidgets('shows the pairs themselves, not more card art',
        (tester) async {
      final c = await pumpProfile(tester);
      final catalogue = c.read(catalogueProvider);
      for (final id in ['sku-001', 'sku-002']) {
        c.read(cartProvider.notifier).add(
              catalogue.firstWhere((p) => p.id == id),
              size: '9',
            );
      }
      c.read(ordersProvider.notifier).place(nowMillis: 5000);
      await tester.pumpAndSettle();

      expect(find.text('THE SHELF'), findsOneWidget);
      // One card (the pick) plus a photo per owned pair.
      expect(find.byType(SneakerCard), findsOneWidget);
      for (final id in ['sku-001', 'sku-002']) {
        final product = catalogue.firstWhere((p) => p.id == id);
        expect(find.text(product.model), findsWidgets);
      }
    });

    testWidgets('usual size is counted from real order lines', (tester) async {
      final c = await pumpProfile(tester);
      final catalogue = c.read(catalogueProvider);

      // Two pairs at UK 9, one at UK 8.
      c.read(cartProvider.notifier).add(catalogue[0], size: '9');
      c.read(cartProvider.notifier).add(catalogue[1], size: '9');
      c.read(cartProvider.notifier).add(catalogue[2], size: '8');
      c.read(ordersProvider.notifier).place(nowMillis: 6000);
      await tester.pumpAndSettle();

      expect(c.read(usualSizeProvider), '9');
      expect(find.text('UK 9'), findsOneWidget);
    });

    testWidgets('no orders means no claim about size', (tester) async {
      final c = await pumpProfile(tester);
      expect(c.read(usualSizeProvider), isNull);
      expect(find.text('THE SHELF'), findsNothing);
    });
  });

  test('the locker has its own address under the profile', () {
    expect(Routes.lockerPath, '/profile/locker');
  });
}
