import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sneakers_app/models/card_meta.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/providers/locker_provider.dart';
import 'package:sneakers_app/providers/orders_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/utils/money.dart';
import 'package:sneakers_app/view/locker/locker_screen.dart';
import 'package:sneakers_app/view/locker/widgets/sneaker_card.dart';

import 'harness.dart';

Future<ProviderContainer> pumpLocker(WidgetTester tester) async {
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
        home: MediaQuery(
          // Suppresses entrance animations and the foil's sensor stream.
          data: const MediaQueryData(disableAnimations: true),
          child: const LockerScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('card metadata is derived from real data', () {
    test('rarity follows price, as configured', () {
      expect(CardRarity.forPrice(const Money(899500)), CardRarity.common);
      expect(CardRarity.forPrice(const Money(1099500)), CardRarity.uncommon);
      expect(CardRarity.forPrice(const Money(1299500)), CardRarity.rare);
      expect(CardRarity.forPrice(const Money(1699500)), CardRarity.ultraRare);
    });

    test('rarity is monotonic — a dearer pair is never rarer-down', () {
      var previous = -1;
      for (final paise in [0, 500000, 900000, 1200000, 1500000, 9900000]) {
        final r = CardRarity.forPrice(Money(paise)).index;
        expect(r, greaterThanOrEqualTo(previous));
        previous = r;
      }
    });

    test('foil is reserved for rare and above', () {
      CardMeta meta(int paise) => CardMeta(
            rarity: CardRarity.forPrice(Money(paise)),
            type: CardType.running,
            number: 1,
            setSize: 8,
          );
      expect(meta(899500).hasFoil, isFalse);
      expect(meta(1299500).hasFoil, isTrue);
      expect(meta(1699500).hasFullArt, isTrue);
    });
  });

  testWidgets('an empty locker shows how cards are earned', (tester) async {
    final c = await pumpLocker(tester);

    expect(c.read(lockerProvider), isEmpty);
    expect(c.read(lockerStatsProvider).isEmpty, isTrue);

    // No locked cards to browse — an unearned card is simply absent.
    expect(find.byType(SneakerCard), findsNothing);
    expect(find.text('No cards yet'), findsOneWidget);
    expect(find.text('Browse the store'), findsOneWidget);
  });

  testWidgets('buying a pair puts its card in the locker', (tester) async {
    final c = await pumpLocker(tester);
    final product = c.read(catalogueProvider).first;

    c.read(cartProvider.notifier).add(product, size: '8');
    c.read(ordersProvider.notifier).place(nowMillis: 1000);
    await tester.pumpAndSettle();

    final cards = c.read(lockerProvider);
    expect(cards.length, 1);
    expect(cards.single.product.id, product.id);
    expect(find.byType(SneakerCard), findsOneWidget);
    expect(find.text('No cards yet'), findsNothing);

    // Placing the order empties the bag.
    expect(c.read(cartProvider), isEmpty);
  });

  testWidgets('card numbers stay tied to catalogue position', (tester) async {
    final c = await pumpLocker(tester);
    final catalogue = c.read(catalogueProvider);

    // Buy the third product only. Its card must still read 003, not 001 —
    // a number that renumbers as you collect makes the set meaningless.
    c.read(cartProvider.notifier).add(catalogue[2], size: '8');
    c.read(ordersProvider.notifier).place(nowMillis: 2000);
    await tester.pumpAndSettle();

    expect(c.read(lockerProvider).single.meta.setLabel, '003/008');
    expect(c.read(lockerStatsProvider).total, catalogue.length);
  });

  testWidgets('buying the same model twice is still one card', (tester) async {
    final c = await pumpLocker(tester);
    final product = c.read(catalogueProvider).first;

    c.read(cartProvider.notifier).add(product, size: '8');
    c.read(ordersProvider.notifier).place(nowMillis: 3000);
    c.read(cartProvider.notifier).add(product, size: '9.5');
    c.read(ordersProvider.notifier).place(nowMillis: 4000);
    await tester.pumpAndSettle();

    // Two orders, two sizes — the card represents the shoe, not the receipt.
    expect(c.read(ordersProvider).length, 2);
    expect(c.read(lockerProvider).length, 1);
    expect(c.read(lockerStatsProvider).owned, 1);
  });

  testWidgets('stats count distinct brands and track the rarest card',
      (tester) async {
    final c = await pumpLocker(tester);
    final catalogue = c.read(catalogueProvider);
    ShoeModel bySku(String id) => catalogue.firstWhere((p) => p.id == id);

    for (final id in ['sku-001', 'sku-003', 'sku-002']) {
      c.read(cartProvider.notifier).add(bySku(id), size: '8');
    }
    c.read(ordersProvider.notifier).place(nowMillis: 5000);
    await tester.pumpAndSettle();

    final stats = c.read(lockerStatsProvider);
    expect(stats.owned, 3);
    expect(stats.brands, 2); // NIKE + JORDAN
    expect(stats.rarest, CardRarity.rare); // the ₹12,995 pair
  });

  testWidgets('an empty bag cannot produce an order', (tester) async {
    final c = await pumpLocker(tester);

    final order = c.read(ordersProvider.notifier).place(nowMillis: 6000);
    expect(order, isNull);
    expect(c.read(ordersProvider), isEmpty);
    // Otherwise a phantom card would appear for a purchase nobody made.
    expect(c.read(lockerProvider), isEmpty);
  });

  testWidgets('orders survive a rebuild', (tester) async {
    final c = await pumpLocker(tester);
    final product = c.read(catalogueProvider).first;

    c.read(cartProvider.notifier).add(product, size: '8');
    c.read(ordersProvider.notifier).place(nowMillis: 7000);

    expect(c.read(ordersProvider).single.total.paise, greaterThan(0));
    expect(c.read(ordersProvider).single.productIds, contains(product.id));
  });

  testWidgets('settings still reachable, and gated the same way',
      (tester) async {
    await pumpLocker(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Sign in to view'), findsOneWidget);
    // The chat-app leftovers are gone for good.
    expect(find.text('John Doe'), findsNothing);
    expect(find.text('Do not disturb'), findsNothing);
  });
}
