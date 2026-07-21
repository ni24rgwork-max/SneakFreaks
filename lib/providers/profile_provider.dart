import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/data/preferences.dart';
import 'package:sneakers_app/providers/locker_provider.dart';
import 'package:sneakers_app/providers/orders_provider.dart';

/// What fills the wide tile at the top of the profile grid.
///
/// A profile is the one screen a user might reasonably want to arrange, so the
/// hero is theirs to choose rather than ours to assume. Collectors want cards
/// on top; someone who just buys shoes wants their numbers or nothing at all.
enum ProfileShowcase {
  locker('My card', 'The card you picked, with what it is'),
  stats('Set progress', 'How far through the set you are'),
  minimal('Neither', 'Just the numbers');

  const ProfileShowcase(this.label, this.blurb);

  final String label;
  final String blurb;
}

class ProfileShowcaseController extends Notifier<ProfileShowcase> {
  static const _key = 'profile_showcase_v1';

  @override
  ProfileShowcase build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    return ProfileShowcase.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => ProfileShowcase.locker,
    );
  }

  Future<void> select(ProfileShowcase showcase) async {
    state = showcase;
    await ref.read(sharedPreferencesProvider).setString(_key, showcase.name);
  }
}

final profileShowcaseProvider =
    NotifierProvider<ProfileShowcaseController, ProfileShowcase>(
        ProfileShowcaseController.new);

/// The one card the shopper puts on their profile.
///
/// Stores a product id, not a card: cards are derived from the catalogue and
/// order history, so persisting one would go stale the moment either changed.
///
/// Selecting nothing is a legitimate state and stays that way. The *display*
/// falls back to the rarest card held (see [featuredCardProvider]) — a
/// showcase with nothing in it is a broken-looking page, but silently writing
/// a choice the user never made would then be indistinguishable from one they
/// did, and the picker could never show "no pick yet".
class FeaturedCardController extends Notifier<String?> {
  static const _key = 'profile_featured_card_v1';

  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(_key);

  Future<void> select(String productId) async {
    state = productId;
    await ref.read(sharedPreferencesProvider).setString(_key, productId);
  }

  /// Back to the automatic pick.
  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final featuredCardIdProvider =
    NotifierProvider<FeaturedCardController, String?>(
        FeaturedCardController.new);

/// The card actually shown on the profile.
///
/// Resolves the stored id against what is *currently* owned, so a card that
/// leaves the collection cannot linger on the profile. Falls back to the rarest
/// card held, then to the first — an explicit pick always wins.
final featuredCardProvider = Provider<LockerCard?>((ref) {
  final cards = ref.watch(lockerProvider);
  if (cards.isEmpty) return null;

  final chosen = ref.watch(featuredCardIdProvider);
  for (final card in cards) {
    if (card.product.id == chosen) return card;
  }

  return cards.reduce(
    (a, b) => b.meta.rarity.index > a.meta.rarity.index ? b : a,
  );
});

/// When the collection started, from the earliest order.
///
/// Not an account-creation date — there is no account yet, and inventing one
/// would be the kind of small lie that is impossible to walk back once it has
/// been shown to someone. Null until there is a first order to point at.
final memberSinceProvider = Provider<DateTime?>((ref) {
  final orders = ref.watch(ordersProvider);
  if (orders.isEmpty) return null;
  // Stored newest-first.
  return orders.last.placedAt;
});

/// A size the shopper set by hand, overriding what their orders imply.
///
/// [usualSizeProvider] is an inference — accurate for most people and wrong for
/// anyone who buys gifts, or whose size differs by silhouette. An inference
/// presented as fact with no way to correct it is worse than no fact at all.
class PreferredSizeController extends Notifier<String?> {
  static const _key = 'profile_size_v1';

  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(_key);

  Future<void> select(String size) async {
    state = size;
    await ref.read(sharedPreferencesProvider).setString(_key, size);
  }

  /// Back to whatever the orders say.
  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final preferredSizeProvider =
    NotifierProvider<PreferredSizeController, String?>(
        PreferredSizeController.new);

/// The size to show: what was set by hand, else what the orders imply.
final profileSizeProvider = Provider<String?>(
    (ref) => ref.watch(preferredSizeProvider) ?? ref.watch(usualSizeProvider));

/// Collector standing, derived from how many cards are held.
///
/// Counted from real ownership, never from spend — a tier that rises with
/// money spent is a sales quota wearing a badge, and reads as one.
enum CollectorTier {
  newcomer('New here', 0),
  rookie('Rookie', 1),
  runner('Runner', 2),
  collector('Collector', 5),
  curator('Curator', 10),
  archivist('Archivist', 20);

  const CollectorTier(this.label, this.minimumPairs);

  final String label;
  final int minimumPairs;

  static CollectorTier forPairs(int pairs) {
    var tier = CollectorTier.newcomer;
    for (final t in CollectorTier.values) {
      if (pairs >= t.minimumPairs) tier = t;
    }
    return tier;
  }

  /// Pairs still needed for the next tier, or null at the top.
  int? pairsToNext(int pairs) {
    final next = CollectorTier.values.skip(index + 1).firstOrNull;
    return next == null ? null : next.minimumPairs - pairs;
  }
}

final collectorTierProvider = Provider<CollectorTier>(
    (ref) => CollectorTier.forPairs(ref.watch(lockerStatsProvider).owned));
