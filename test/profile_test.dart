import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sneakers_app/providers/auth_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/profile/profile_screen.dart';

import 'harness.dart';

Future<ProviderContainer> pumpProfile(WidgetTester tester) async {
  final overrides = await testOverrides();
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.of(Brightness.light),
        home: const Profile(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('signed out shows a sign-in prompt, not a fake identity',
      (tester) async {
    final c = await pumpProfile(tester);
    expect(c.read(authProvider), isFalse);

    expect(find.text('You are not signed in'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    // The old screen hardcoded a name and a stock avatar of a stranger.
    expect(find.text('John Doe'), findsNothing);
    // And a presence picker carried over from a chat-app tutorial.
    expect(find.text('Away'), findsNothing);
    expect(find.text('Do not disturb'), findsNothing);
  });

  testWidgets('account-only rows are disabled while signed out',
      (tester) async {
    await pumpProfile(tester);

    // Shown, so the user knows the feature exists — but explicitly gated
    // rather than silently doing nothing when tapped.
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Sign in to view'), findsOneWidget);

    final orders = tester.widget<ListTile>(
      find.ancestor(of: find.text('Orders'), matching: find.byType(ListTile)),
    );
    expect(orders.enabled, isFalse);
    expect(orders.onTap, isNull);
  });

  testWidgets('signing in enables the account rows and offers sign out',
      (tester) async {
    final c = await pumpProfile(tester);

    c.read(authProvider.notifier).signIn();
    await tester.pumpAndSettle();

    expect(find.text('You are not signed in'), findsNothing);
    expect(find.text('Sign out'), findsOneWidget);

    final orders = tester.widget<ListTile>(
      find.ancestor(of: find.text('Orders'), matching: find.byType(ListTile)),
    );
    expect(orders.enabled, isTrue);
  });

  testWidgets('preferences work without an account', (tester) async {
    await pumpProfile(tester);
    // Appearance must not be gated behind auth — it is a device setting.
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
  });
}
