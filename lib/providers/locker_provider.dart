import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/models/card_meta.dart';
import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/providers/orders_provider.dart';

/// One card in the Locker.
class LockerCard {
  const LockerCard({required this.product, required this.meta});

  final ShoeModel product;
  final CardMeta meta;
}

/// The Locker holds **only cards the shopper has bought**.
///
/// There is no locked or browsable state: an unearned card is simply not there.
/// A binder showing everything you could own is a catalogue; a binder showing
/// what you do own is a collection, and only the second is worth keeping.
///
/// Card numbers stay tied to catalogue position, so `003/008` identifies the
/// same shoe whether or not you own it — a number that renumbered as you
/// collected would make the set meaningless.
final lockerProvider = Provider<List<LockerCard>>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final owned = ref.watch(ownedProductIdsProvider);

  return [
    for (var i = 0; i < catalogue.length; i++)
      if (owned.contains(catalogue[i].id))
        LockerCard(
          product: catalogue[i],
          meta: CardMeta.forProduct(
            catalogue[i],
            number: i + 1,
            setSize: catalogue.length,
          ),
        ),
  ];
});

/// Locker stats. All counted from owned cards, none invented.
class LockerStats {
  const LockerStats({
    required this.owned,
    required this.total,
    required this.brands,
    required this.rarest,
  });

  final int owned;
  final int total;
  final int brands;
  final CardRarity? rarest;

  bool get isEmpty => owned == 0;
  double get completion => total == 0 ? 0 : owned / total;
}

final lockerStatsProvider = Provider<LockerStats>((ref) {
  final cards = ref.watch(lockerProvider);

  CardRarity? rarest;
  final brands = <String>{};
  for (final c in cards) {
    brands.add(c.product.name);
    if (rarest == null || c.meta.rarity.index > rarest.index) {
      rarest = c.meta.rarity;
    }
  }

  return LockerStats(
    owned: cards.length,
    total: ref.watch(catalogueProvider).length,
    brands: brands.length,
    rarest: rarest,
  );
});
