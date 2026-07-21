import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/providers/auth_provider.dart';
import 'package:sneakers_app/theme/brand_tokens.dart';
import 'package:sneakers_app/theme/motion.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/view/auth/sign_in_screen.dart';
import 'package:sneakers_app/view/bag/bag_screen.dart';
import 'package:sneakers_app/view/checkout/checkout_screen.dart';
import 'package:sneakers_app/view/collection/collection_screen.dart';
import 'package:sneakers_app/view/detail/detail_screen.dart';
import 'package:sneakers_app/view/home/home_screen.dart';
import 'package:sneakers_app/view/profile/profile_screen.dart';
import 'package:sneakers_app/view/search/search_screen.dart';
import 'package:sneakers_app/view/shell/shell_scaffold.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Application router.
///
/// Replaces `Navigator.push(MaterialPageRoute(...))` with declarative routes.
/// The forcing function is payments: a UPI transaction leaves the app entirely
/// — control passes to GPay/PhonePe and the gateway returns the user via a
/// deep link. Without addressable routes there is no way to land them back on
/// order-confirmation, and the failure mode is the worst one available: money
/// debited, app showing an empty cart.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    debugLogDiagnostics: false,

    redirect: (context, state) {
      // Custom-scheme deep links arrive as a whole URI, and Uri parses
      // `sneakfreaks://product/sku-004` as host=product, path=/sku-004 — so
      // nothing matches and the user lands on the not-found page. Fold the
      // host back into the path before routing.
      final normalized = _normalizeDeepLink(state.uri);
      if (normalized != null) return normalized;

      // Auth gate. There is no real session yet, but the guard exists now so
      // checkout cannot be built without one.
      final signedIn = ref.read(authProvider);
      final goingToGuarded = state.matchedLocation == Routes.checkout;

      if (goingToGuarded && !signedIn) {
        // Preserve intent so sign-in can hand the user back where they were.
        return '${Routes.signIn}?from=${Uri.encodeComponent(state.matchedLocation)}';
      }
      return null;
    },

    errorBuilder: (context, state) => _NotFound(location: state.uri.toString()),

    routes: [
      // Each branch keeps its own navigation stack, so opening a product from
      // Home, switching to Bag and coming back returns you to the product
      // rather than resetting to the top of the feed. The previous PageView
      // could not express that.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                name: Routes.nameHome,
                builder: (context, state) => const HomeScreen(),
                // Product, collection and search hang off Home only.
                //
                // go_router requires route names to be globally unique, so the
                // same named route cannot be attached to several branches. It
                // also matches how the app is actually used: every path into a
                // product starts from the feed. A deep link to /product/:id
                // therefore lands on the Home branch, which is where a shopper
                // would expect Back to take them. If the Bag ever needs to open
                // a PDP, give that branch its own prefixed copy
                // (/bag/product/:id) rather than sharing this one.
                routes: _browseRoutes,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.bag,
                name: Routes.nameBag,
                builder: (context, state) => const MyBagScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                name: Routes.nameProfile,
                builder: (context, state) => const Profile(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen, above the shell — the nav bar should not be reachable
      // mid-checkout.
      GoRoute(
        path: Routes.checkout,
        name: Routes.nameCheckout,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: Routes.signIn,
        name: Routes.nameSignIn,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => SignInScreen(
          returnTo: state.uri.queryParameters['from'],
        ),
      ),
    ],
  );
});

/// Material shared-axis transition for pushed pages.
///
/// The card-to-page container transform in the `animations` package
/// (`OpenContainer`) drives its own navigation, which would mean either
/// double-pushing or giving up addressable routes — and routes are load-bearing
/// for deep links and payment returns. Applying the transition at the route
/// instead keeps go_router in charge of navigation and still replaces the
/// default platform slide with something deliberate.
CustomTransitionPage<void> _sharedAxis(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration:
        context.reduceMotion ? Duration.zero : BrandTokens.motionContainer,
    reverseTransitionDuration:
        context.reduceMotion ? Duration.zero : BrandTokens.motionBase,
    transitionsBuilder: (context, animation, secondary, child) {
      if (context.reduceMotion) return child;
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondary,
        transitionType: SharedAxisTransitionType.scaled,
        fillColor: Theme.of(context).colorScheme.surface,
        child: child,
      );
    },
  );
}

/// The app's custom URL scheme. Works without owning a domain, unlike
/// Universal Links / App Links — see docs/ARCHITECTURE.md.
const _scheme = 'sneakfreaks';

/// Rewrites `sneakfreaks://product/sku-004` to `/product/sku-004`.
///
/// Returns null for ordinary in-app locations so the redirect chain falls
/// through to the auth gate.
String? _normalizeDeepLink(Uri uri) {
  if (uri.scheme != _scheme) return null;

  final segments = [
    if (uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments,
  ];
  if (segments.isEmpty) return Routes.home;

  return Uri(
    path: '/${segments.join('/')}',
    queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters,
  ).toString();
}

/// Browse routes, nested under the Home branch.
final List<RouteBase> _browseRoutes = [
  GoRoute(
    path: '${Routes.product}/:id',
    name: Routes.nameProduct,
    // Above the shell: a PDP is a focused conversion screen, and the bottom
    // nav both competes with the sticky Add to Bag and costs 68px of height.
    parentNavigatorKey: _rootKey,
    pageBuilder: (context, state) => _sharedAxis(
      context,
      state,
      DetailScreen(productId: state.pathParameters['id']!),
    ),
  ),
  GoRoute(
    path: '${Routes.collection}/:tag',
    name: Routes.nameCollection,
    builder: (context, state) =>
        CollectionScreen(tag: state.pathParameters['tag']!),
  ),
  GoRoute(
    path: Routes.search,
    name: Routes.nameSearch,
    builder: (context, state) => const SearchScreen(),
  ),
];

class _NotFound extends StatelessWidget {
  const _NotFound({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              const Icon(Icons.search_off, size: 48),
              Text(
                "We couldn't find $location",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Back to store'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
