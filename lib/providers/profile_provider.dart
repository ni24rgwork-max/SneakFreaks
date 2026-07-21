import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/data/preferences.dart';
import 'package:sneakers_app/providers/locker_provider.dart';

/// What occupies the top of the profile.
///
/// A profile is the one screen a user might reasonably want to arrange, so the
/// hero is theirs to choose rather than ours to assume. Collectors want cards
/// on top; someone who just buys shoes wants their numbers or nothing at all.
enum ProfileShowcase {
  locker('Locker', 'Your rarest cards, front and centre'),
  stats('Stats', 'Collection numbers at a glance'),
  minimal('Minimal', 'Just the essentials');

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
