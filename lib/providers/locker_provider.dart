import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/data/preferences.dart';
import 'package:sneakers_app/models/card_meta.dart';
import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';

/// Pairs the user owns.
///
/// Deliberately **not** limited to purchases from this store. Sneakerheads
/// already catalogue what they own, so letting them add existing pairs makes
/// the binder populated on day one — and it is the richest taste signal the
/// recommendation layer could be handed.
///
/// TODO(backend): merge with order history once purchasing exists, and mark
/// which entries were bought here versus added manually.
class OwnedPairsController extends Notifier<List<String>> {
  static const _key = 'owned_pairs_v1';

  @override
  List<String> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  void _commit(List<String> ids) {
    state = List.unmodifiable(ids);
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(ids));
  }

  void add(String productId) {
    if (state.contains(productId)) return;
    _commit([...state, productId]);
  }

  void remove(String productId) =>
      _commit([...state.where((id) => id != productId)]);

  void toggle(String productId) =>
      state.contains(productId) ? remove(productId) : add(productId);
}

final ownedPairsProvider =
    NotifierProvider<OwnedPairsController, List<String>>(
        OwnedPairsController.new);

/// One binder slot: the product, its card metadata, and whether it is owned.
class BinderSlot {
  const BinderSlot({
    required this.product,
    required this.meta,
    required this.owned,
  });

  final ShoeModel product;
  final CardMeta meta;
  final bool owned;
}

/// The full set, in catalogue order, with stable card numbers.
///
/// Numbering is positional and fixed so `003/008` means the same card every
/// time — a set whose numbers shuffle is not a set.
final binderProvider = Provider<List<BinderSlot>>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final owned = ref.watch(ownedPairsProvider);

  return [
    for (var i = 0; i < catalogue.length; i++)
      BinderSlot(
        product: catalogue[i],
        meta: CardMeta.forProduct(
          catalogue[i],
          number: i + 1,
          setSize: catalogue.length,
        ),
        owned: owned.contains(catalogue[i].id),
      ),
  ];
});

/// Collection stats for the binder header. All counted, none invented.
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

  double get completion => total == 0 ? 0 : owned / total;
}

final lockerStatsProvider = Provider<LockerStats>((ref) {
  final slots = ref.watch(binderProvider);
  final mine = slots.where((s) => s.owned).toList();

  CardRarity? rarest;
  final brands = <String>{};
  for (final s in mine) {
    brands.add(s.product.name);
    if (rarest == null || s.meta.rarity.index > rarest.index) {
      rarest = s.meta.rarity;
    }
  }

  return LockerStats(
    owned: mine.length,
    total: slots.length,
    brands: brands.length,
    rarest: rarest,
  );
});
