import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/brand_tokens.dart';
import 'package:sneakers_app/theme/motion.dart';
import 'package:sneakers_app/view/detail/detail_screen.dart';

import 'package:sneakers_app/providers/catalogue_provider.dart';

import 'harness.dart';

Future<void> pumpWithMotion(
  WidgetTester tester,
  Widget child, {
  required bool disableAnimations,
}) async {
  final overrides = await testOverrides();
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.of(Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('entrance animation is skipped under reduced motion',
      (tester) async {
    await pumpWithMotion(
      tester,
      Builder(builder: (c) => const Text('hello').enter(c)),
      disableAnimations: true,
    );

    // Returned untouched, not wrapped in a zero-duration animation — a
    // zero-duration Animate still schedules frames and leaves pending timers.
    expect(find.byType(Animate), findsNothing);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('entrance animation runs when motion is allowed', (tester) async {
    await pumpWithMotion(
      tester,
      Builder(builder: (c) => const Text('hello').enter(c)),
      disableAnimations: false,
    );

    expect(find.byType(Animate), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('pulse is skipped under reduced motion', (tester) async {
    await pumpWithMotion(
      tester,
      Builder(builder: (c) => const Icon(Icons.abc).pulse(c, trigger: 1)),
      disableAnimations: true,
    );
    expect(find.byType(Animate), findsNothing);
  });

  testWidgets('the PDP renders fully with animations disabled', (tester) async {
    // Reduced motion must not cost content — a section that only appears via
    // its entrance animation would vanish for these users.
    final probe = ProviderContainer(overrides: await testOverrides());
    final product = probe
        .read(catalogueProvider)
        .firstWhere((p) => p.discountPercent != null && !p.isUpcoming);
    probe.dispose();

    await pumpWithMotion(
      tester,
      DetailScreen(productId: product.id),
      disableAnimations: true,
    );

    expect(find.text(product.price.formatted), findsWidgets);
    expect(find.text('${product.discountPercent}% OFF'), findsOneWidget);
    expect(find.text('Select size'), findsOneWidget);
    expect(find.text('ADD TO BAG'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
  });

  test('motion tokens are ordered fast < base < slow', () {
    expect(BrandTokens.motionFast, lessThan(BrandTokens.motionBase));
    expect(BrandTokens.motionBase, lessThan(BrandTokens.motionSlow));
    // A stagger long enough to read as loading defeats the point.
    expect(BrandTokens.staggerStepMs, lessThanOrEqualTo(60));
  });
}
