import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sneakers_app/data/preferences.dart';
import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/utils/money.dart';

const _airMax = ShoeModel(
  id: 'sku-001',
  name: 'NIKE',
  model: 'AIR-MAX',
  price: Money(1299500), // ₹12,995
  mrp: Money(1699500), // ₹16,995
  imgAddress: 'assets/images/nike1.png',
  modelColor: Color(0xffDE0106),
);

const _airForce = ShoeModel(
  id: 'sku-004',
  name: 'NIKE',
  model: 'Air-FORCE',
  price: Money(899500), // ₹8,995
  imgAddress: 'assets/images/nike3.png',
  modelColor: Color(0xffD7D8DC),
);

Future<ProviderContainer> makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      catalogueProvider.overrideWithValue([_airMax, _airForce]),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cart', () {
    test('starts empty', () async {
      final c = await makeContainer();
      expect(c.read(cartProvider), isEmpty);
      expect(c.read(cartCountProvider), 0);
      expect(c.read(cartSubtotalProvider).paise, 0);
    });

    test('adding the same product+size increments instead of being rejected',
        () async {
      // The old AppMethods.addToCart used `contains()` on the global list, so a
      // second pair could never be added. This is the regression guard.
      final c = await makeContainer();
      final cart = c.read(cartProvider.notifier);

      expect(cart.add(_airMax, size: '8'), isTrue, reason: 'new line');
      expect(cart.add(_airMax, size: '8'), isFalse, reason: 'merged');

      expect(c.read(cartProvider).length, 1);
      expect(c.read(cartProvider).single.quantity, 2);
      expect(c.read(cartCountProvider), 2);
    });

    test('same product in a different size is a separate line', () async {
      final c = await makeContainer();
      final cart = c.read(cartProvider.notifier);
      cart.add(_airMax, size: '8');
      cart.add(_airMax, size: '9.5');

      expect(c.read(cartProvider).length, 2);
      expect(c.read(cartCountProvider), 2);
    });

    test('count is the sum of quantities, not the number of lines', () async {
      final c = await makeContainer();
      final cart = c.read(cartProvider.notifier);
      cart.add(_airMax, size: '8', quantity: 3);
      cart.add(_airForce, size: '10', quantity: 2);

      expect(c.read(cartProvider).length, 2);
      expect(c.read(cartCountProvider), 5);
    });

    test('decrementing to zero removes the line', () async {
      final c = await makeContainer();
      final cart = c.read(cartProvider.notifier);
      cart.add(_airMax, size: '8');
      cart.decrement('sku-001#8');

      expect(c.read(cartProvider), isEmpty);
      expect(c.read(cartCountProvider), 0);
    });

    test('undo restores a removed line at its original index', () async {
      final c = await makeContainer();
      final cart = c.read(cartProvider.notifier);
      cart.add(_airMax, size: '8');
      cart.add(_airForce, size: '10');

      final removed = c.read(cartProvider).first;
      cart.remove(removed.key);
      expect(c.read(cartProvider).length, 1);

      cart.restore(removed, 0);
      expect(c.read(cartProvider).length, 2);
      expect(c.read(cartProvider).first.productId, 'sku-001');
    });
  });

  group('cart totals', () {
    test('subtotal multiplies price by quantity', () async {
      final c = await makeContainer();
      c.read(cartProvider.notifier).add(_airMax, size: '8', quantity: 2);

      expect(c.read(cartSubtotalProvider).paise, 2599000); // ₹25,990
      expect(c.read(cartSubtotalProvider).formatted, '₹25,990');
    });

    test('savings use MRP and are never overstated for products without one',
        () async {
      final c = await makeContainer();
      final cart = c.read(cartProvider.notifier);
      cart.add(_airMax, size: '8'); // ₹16,995 MRP -> ₹12,995, saves ₹4,000
      cart.add(_airForce, size: '10'); // no MRP -> saves nothing

      expect(c.read(cartSavingsProvider).paise, 400000);
      expect(c.read(cartSavingsProvider).formatted, '₹4,000');
    });

    test('delivery is free above the threshold and charged below it', () async {
      final c = await makeContainer();
      final cart = c.read(cartProvider.notifier);

      // Empty bag: no phantom delivery fee.
      expect(c.read(deliveryFeeProvider).paise, 0);

      cart.add(_airMax, size: '8'); // ₹12,995, well over ₹1,999
      expect(c.read(deliveryFeeProvider).paise, 0);
      expect(c.read(cartTotalProvider), c.read(cartSubtotalProvider));
    });

    test('totals stay exact across repeated addition (no float drift)',
        () async {
      final c = await makeContainer();
      final cart = c.read(cartProvider.notifier);
      for (var i = 0; i < 100; i++) {
        cart.add(_airMax, size: '8');
      }
      // 100 x ₹12,995 = ₹12,99,500 exactly.
      expect(c.read(cartSubtotalProvider).paise, 129950000);
      expect(c.read(cartSubtotalProvider).formatted, '₹12,99,500');
    });
  });

  group('persistence', () {
    test('cart survives a container rebuild', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      ProviderContainer build() => ProviderContainer(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              catalogueProvider.overrideWithValue([_airMax, _airForce]),
            ],
          );

      final first = build();
      first.read(cartProvider.notifier).add(_airMax, size: '7.5', quantity: 2);
      first.dispose();

      final second = build();
      addTearDown(second.dispose);

      expect(second.read(cartProvider).length, 1);
      expect(second.read(cartProvider).single.size, '7.5');
      expect(second.read(cartCountProvider), 2);
    });

    test('a corrupt payload does not crash the app on launch', () async {
      SharedPreferences.setMockInitialValues({'cart_lines_v1': 'not json {['});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          catalogueProvider.overrideWithValue([_airMax]),
        ],
      );
      addTearDown(c.dispose);

      expect(c.read(cartProvider), isEmpty);
    });

    test('lines referencing products no longer in the catalogue are dropped',
        () async {
      SharedPreferences.setMockInitialValues({
        'cart_lines_v1':
            '[{"productId":"sku-deleted","size":"8","quantity":1}]',
      });
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          catalogueProvider.overrideWithValue([_airMax]),
        ],
      );
      addTearDown(c.dispose);

      // The raw line is still stored, but it resolves to nothing and
      // contributes no money to the totals.
      expect(c.read(resolvedCartProvider), isEmpty);
      expect(c.read(cartSubtotalProvider).paise, 0);
    });
  });

  group('money formatting', () {
    test('uses Indian lakh/crore grouping', () async {
      expect(const Money(99900).formatted, '₹999');
      expect(const Money(1299900).formatted, '₹12,999');
      expect(const Money(15000000).formatted, '₹1,50,000');
      expect(const Money(1250000000).formatted, '₹1,25,00,000');
    });

    test('compact form uses L and Cr', () async {
      expect(const Money(15000000).compact, '₹1.5L');
      expect(const Money(1250000000).compact, '₹1.25Cr');
    });
  });
}
