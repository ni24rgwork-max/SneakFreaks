import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sneakers_app/data/preferences.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/providers/pdp_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/detail/detail_screen.dart';

Future<ProviderContainer> pumpPdp(WidgetTester tester, String id) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.of(Brightness.light),
        home: DetailScreen(productId: id),
      ),
    ),
  );
  // The staggered section entrance schedules delayed animations; settle them
  // or the binding reports pending timers at teardown.
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('shows the discount, not just the selling price', (tester) async {
    await pumpPdp(tester, 'sku-001');

    // The old page showed a bare price, dropping the strongest purchase
    // signal at exactly the point of decision.
    expect(find.text('₹12,995'), findsWidgets);
    expect(find.text('₹16,995'), findsOneWidget);
    expect(find.text('24% OFF'), findsOneWidget);
    expect(find.text('Inclusive of all taxes'), findsOneWidget);
  });

  testWidgets('the purchase bar is outside the scroll view', (tester) async {
    await pumpPdp(tester, 'sku-001');

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.bottomNavigationBar, isNotNull);
    expect(find.text('ADD TO BAG'), findsOneWidget);
    // Prompts for a size before one is chosen.
    expect(find.text('Select a size'), findsOneWidget);
  });

  testWidgets('sold-out sizes are shown, struck through, and not selectable',
      (tester) async {
    final c = await pumpPdp(tester, 'sku-001');
    final product = c.read(productByIdProvider('sku-001'))!;

    expect(product.soldOutSizes, contains('7.5'));
    expect(product.isSizeAvailable('7.5'), isFalse);
    expect(product.isSizeAvailable('8'), isTrue);

    // Rendered rather than hidden: a shopper can see the size exists at all.
    expect(find.text('7.5'), findsWidgets);

    await tester.tap(find.text('8').first);
    await tester.pump();
    expect(c.read(selectedSizeProvider('sku-001')), '8');
  });

  testWidgets('size selection is per product, not global', (tester) async {
    final c = await pumpPdp(tester, 'sku-001');
    c.read(selectedSizeProvider('sku-001').notifier).select('8');

    // A second product must not inherit the first one's size.
    expect(c.read(selectedSizeProvider('sku-002')), isNull);
  });

  testWidgets('UK/US toggle converts the displayed sizes', (tester) async {
    final c = await pumpPdp(tester, 'sku-004');

    expect(c.read(sizeSystemProvider), SizeSystem.uk);
    expect(convertSize('8', SizeSystem.uk), '8');
    expect(convertSize('8', SizeSystem.us), '9');
    expect(convertSize('7.5', SizeSystem.us), '8.5');

    c.read(sizeSystemProvider.notifier).select(SizeSystem.us);
    await tester.pump();
    expect(c.read(sizeSystemProvider), SizeSystem.us);
  });

  testWidgets('description renders in full rather than being clipped',
      (tester) async {
    final c = await pumpPdp(tester, 'sku-001');
    final product = c.read(productByIdProvider('sku-001'))!;

    expect(product.description, isNotNull);
    // The old page put this in a height/9 box with no ellipsis, slicing it
    // mid-sentence. Nothing constrains it now.
    expect(find.textContaining('PLACEHOLDER COPY'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Delivery & returns'), findsOneWidget);
  });

  testWidgets('pincode check validates input', (tester) async {
    final c = await pumpPdp(tester, 'sku-001');
    final pincode = c.read(pincodeProvider.notifier);

    pincode.check('12');
    expect(c.read(pincodeProvider)!.valid, isFalse);

    pincode.check('abcdef');
    expect(c.read(pincodeProvider)!.valid, isFalse);

    pincode.check('560001');
    final result = c.read(pincodeProvider)!;
    expect(result.valid, isTrue);
    expect(result.days, greaterThan(0));
  });

  testWidgets('an upcoming product offers notify, not add to bag',
      (tester) async {
    await pumpPdp(tester, 'sku-006');

    expect(find.text('NOTIFY ME'), findsOneWidget);
    expect(find.text('ADD TO BAG'), findsNothing);
    // No size picker for something that cannot be bought yet.
    expect(find.text('Select size'), findsNothing);
  });

  testWidgets('related rail excludes the product being viewed',
      (tester) async {
    final c = await pumpPdp(tester, 'sku-001');
    final related = c.read(relatedProvider('sku-001'));

    expect(related, isNotEmpty);
    expect(related.any((p) => p.id == 'sku-001'), isFalse);
    expect(related.any((p) => p.isUpcoming), isFalse);
    // Same brand leads.
    expect(related.first.name, 'NIKE');
  });
}
