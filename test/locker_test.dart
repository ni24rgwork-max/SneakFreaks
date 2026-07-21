import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sneakers_app/models/card_meta.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/providers/locker_provider.dart';
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

  testWidgets('binder numbers every card stably', (tester) async {
    final c = await pumpLocker(tester);
    final slots = c.read(binderProvider);

    expect(slots.length, c.read(catalogueProvider).length);
    expect(slots.first.meta.setLabel, '001/008');
    expect(slots.last.meta.setLabel, '008/008');

    // Re-reading must not renumber — a set whose numbers shuffle is not a set.
    expect(c.read(binderProvider).first.meta.setLabel, '001/008');
  });

  testWidgets('every card starts unowned and the set renders', (tester) async {
    final c = await pumpLocker(tester);

    expect(c.read(ownedPairsProvider), isEmpty);
    expect(c.read(lockerStatsProvider).owned, 0);
    expect(c.read(lockerStatsProvider).completion, 0);
    expect(find.byType(SneakerCard), findsWidgets);
  });

  testWidgets('adding a pair updates stats and persists', (tester) async {
    final c = await pumpLocker(tester);
    final collection = c.read(ownedPairsProvider.notifier);

    collection.add('sku-001');
    await tester.pumpAndSettle();

    final stats = c.read(lockerStatsProvider);
    expect(stats.owned, 1);
    expect(stats.brands, 1);
    expect(stats.rarest, CardRarity.rare); // ₹12,995
    expect(c.read(binderProvider).first.owned, isTrue);

    // Adding twice must not double-count.
    collection.add('sku-001');
    expect(c.read(lockerStatsProvider).owned, 1);

    collection.remove('sku-001');
    expect(c.read(lockerStatsProvider).owned, 0);
  });

  testWidgets('brand count is distinct, not a pair count', (tester) async {
    final c = await pumpLocker(tester);
    final collection = c.read(ownedPairsProvider.notifier);

    collection.add('sku-001'); // NIKE
    collection.add('sku-003'); // NIKE
    collection.add('sku-002'); // JORDAN
    await tester.pumpAndSettle();

    final stats = c.read(lockerStatsProvider);
    expect(stats.owned, 3);
    expect(stats.brands, 2);
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
