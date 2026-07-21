import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/providers/orders_provider.dart';
import 'package:sneakers_app/providers/profile_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/locker/locker_screen.dart';
import 'package:sneakers_app/view/profile/profile_screen.dart';

import 'harness.dart';

/// Layout regressions at real handset widths.
///
/// The rest of the suite pumps a 1200pt-wide surface so nothing is off-screen
/// and every finder resolves. That hides overflow: the Locker's two-up grid
/// gave each card 168pt on a 390pt phone, and one product's card overflowed its
/// info band by 6.2px there while passing every other test in the suite.
///
/// Overflow is reported at paint time, so a widget scrolled out of view never
/// reports it. These cases pump a full, populated collection at the sizes people
/// actually hold.
void main() {
  const sizes = {
    'small phone': Size(360, 780), // Pixel-class Android
    'phone': Size(390, 844), // iPhone 15/16
    'large phone': Size(430, 932), // iPhone Pro Max
    'tablet': Size(834, 1194), // iPad
  };

  final screens = <String, Widget>{
    'locker': const LockerScreen(),
    // Each showcase produces a structurally different page, so each needs its
    // own pass — the card rail only exists in two of the three.
    for (final showcase in ProfileShowcase.values)
      'profile (${showcase.name})': const ProfileScreen(),
  };

  ProfileShowcase showcaseFor(String key) => ProfileShowcase.values.firstWhere(
        (s) => key.contains(s.name),
        orElse: () => ProfileShowcase.locker,
      );

  for (final screen in screens.entries) {
    for (final size in sizes.entries) {
      testWidgets('${screen.key} lays out on a ${size.key}', (tester) async {
        final overrides = await testOverrides();
        tester.view.physicalSize = size.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer(overrides: overrides);
        addTearDown(container.dispose);

        // Own everything, so every card in the set gets laid out.
        for (final product in container.read(catalogueProvider)) {
          container
              .read(cartProvider.notifier)
              .add(product, size: product.sizes.first);
        }
        container.read(ordersProvider.notifier).place(nowMillis: 1);
        await container
            .read(profileShowcaseProvider.notifier)
            .select(showcaseFor(screen.key));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.of(Brightness.light),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size.value,
                  disableAnimations: true,
                ),
                child: screen.value,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Scroll the whole page, so rows below the fold get painted too.
        final scrollable = find.byType(Scrollable).first;
        await tester.drag(scrollable, const Offset(0, -1200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
