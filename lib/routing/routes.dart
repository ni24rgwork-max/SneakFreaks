/// Route paths and names in one place.
///
/// Every navigation call goes through these constants rather than a string
/// literal at the call site, so a renamed path is a compile error instead of a
/// runtime 404 discovered by a user.
abstract final class Routes {
  // Shell branches — one navigation stack each.
  static const home = '/';
  static const bag = '/bag';
  static const profile = '/profile';

  // Pushed on top of the active branch.
  static const product = 'product'; // relative: /product/:id
  static const collection = 'collection'; // relative: /collection/:tag
  static const search = 'search';

  // Auth-gated. Stubs today; the guard is already wired so checkout cannot
  // ship without one.
  static const checkout = '/checkout';
  static const signIn = '/sign-in';

  // Named routes, for `goNamed` / `pushNamed`.
  static const nameHome = 'home';
  static const nameBag = 'bag';
  static const nameProfile = 'profile';
  static const nameProduct = 'product';
  static const nameCollection = 'collection';
  static const nameSearch = 'search';
  static const nameCheckout = 'checkout';
  static const nameSignIn = 'signIn';

  static String productPath(String id) => '/product/$id';
  static String collectionPath(String tag) => '/collection/$tag';
}
