import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';
import 'package:sneakers_app/providers/auth_provider.dart';
import 'package:sneakers_app/routing/router.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';

Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  final overrides = await testOverrides();

  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: overrides,
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.of(Brightness.light),
        routerConfig: container.read(routerProvider),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

String currentLocation(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

void main() {
  testWidgets('starts on the home feed', (tester) async {
    final c = await pumpApp(tester);
    expect(currentLocation(c), Routes.home);
    expect(find.text('SneakFreaks'), findsOneWidget);
  });

  testWidgets('a product URL resolves the product from its id', (tester) async {
    final c = await pumpApp(tester);

    // This is the deep-link path: a bare string, no object handed in.
    c.read(routerProvider).go(Routes.productPath('sku-001'));
    await tester.pumpAndSettle();

    expect(currentLocation(c), '/product/sku-001');
    expect(find.text('AIR-MAX'), findsWidgets);
  });

  testWidgets('an unknown product id shows a message, not a crash',
      (tester) async {
    final c = await pumpApp(tester);

    c.read(routerProvider).go(Routes.productPath('sku-does-not-exist'));
    await tester.pumpAndSettle();

    expect(find.text('This product is no longer available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unknown route shows the not-found page', (tester) async {
    final c = await pumpApp(tester);

    c.read(routerProvider).go('/nonsense/path');
    await tester.pumpAndSettle();

    expect(find.textContaining("couldn't find"), findsOneWidget);
  });

  testWidgets('checkout is gated behind auth and preserves intent',
      (tester) async {
    final c = await pumpApp(tester);
    expect(c.read(authProvider), isFalse);

    c.read(routerProvider).go(Routes.checkout);
    await tester.pumpAndSettle();

    // Redirected to sign-in, carrying where the user was headed.
    expect(currentLocation(c), contains(Routes.signIn));
    expect(currentLocation(c), contains('from='));
    expect(find.text('Sign in required'), findsOneWidget);

    // Signing in hands the user back to checkout, not to home.
    await tester.tap(find.text('Continue (simulate sign-in)'));
    await tester.pumpAndSettle();

    expect(c.read(authProvider), isTrue);
    expect(currentLocation(c), Routes.checkout);
  });

  testWidgets('custom-scheme deep links resolve to the right route',
      (tester) async {
    final c = await pumpApp(tester);

    // Uri parses this as host=product, path=/sku-004 — without normalization
    // it falls through to the not-found page. This is what iOS/Android hand
    // the app when a sneakfreaks:// link is opened.
    c.read(routerProvider).go('sneakfreaks://product/sku-004');
    await tester.pumpAndSettle();

    expect(currentLocation(c), '/product/sku-004');
    expect(find.text('Air-FORCE'), findsWidgets);
    expect(find.textContaining("couldn't find"), findsNothing);
  });

  testWidgets('deep link to a collection resolves', (tester) async {
    final c = await pumpApp(tester);

    c.read(routerProvider).go('sneakfreaks://collection/monsoon');
    await tester.pumpAndSettle();

    expect(currentLocation(c), '/collection/monsoon');
  });

  testWidgets('bare scheme opens the store', (tester) async {
    final c = await pumpApp(tester);

    c.read(routerProvider).go('sneakfreaks://');
    await tester.pumpAndSettle();

    expect(currentLocation(c), Routes.home);
  });

  testWidgets('collection route renders its tagged products', (tester) async {
    final c = await pumpApp(tester);

    c.read(routerProvider).go(Routes.collectionPath('monsoon'));
    await tester.pumpAndSettle();

    expect(currentLocation(c), '/collection/monsoon');
    expect(find.text('Monsoon'), findsOneWidget);
  });

  testWidgets('the PDP covers the shell — no bottom nav', (tester) async {
    final c = await pumpApp(tester);
    expect(find.byType(NavigationBar), findsOneWidget);

    c.read(routerProvider).go(Routes.productPath('sku-001'));
    await tester.pumpAndSettle();

    // Full-screen above the shell: the nav bar must not compete with the
    // sticky Add to Bag, and it should not be possible to tab away mid-product.
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('ADD TO BAG'), findsOneWidget);
  });

  testWidgets('branch routes keep their own stack', (tester) async {
    final c = await pumpApp(tester);

    // Collection stays inside the Home branch, so the nav bar is still there.
    c.read(routerProvider).go(Routes.collectionPath('monsoon'));
    await tester.pumpAndSettle();
    expect(currentLocation(c), '/collection/monsoon');
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Bag'));
    await tester.pumpAndSettle();
    expect(currentLocation(c), Routes.bag);

    // Home's stack survived the tab switch — the old PageView could not do this.
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(currentLocation(c), '/collection/monsoon');
  });

  testWidgets('the locker sits under the profile, inside its branch',
      (tester) async {
    final c = await pumpApp(tester);

    c.read(routerProvider).go(Routes.lockerPath);
    await tester.pumpAndSettle();

    expect(currentLocation(c), '/profile/locker');
    // Inside the shell branch, so the nav bar stays put — the Locker is a
    // section of the profile, not a destination of its own.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('The Locker'), findsOneWidget);

    // And it can be left again without an edge-swipe.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(currentLocation(c), Routes.profile);
  });
}
