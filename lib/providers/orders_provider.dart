import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/data/preferences.dart';
import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/utils/money.dart';

/// A completed order.
///
/// Stores product ids and sizes rather than product objects, for the same
/// reason the cart does: an order has to survive the catalogue being replaced
/// by a backend response, and it has to serialize without touching UI types.
class Order {
  const Order({
    required this.id,
    required this.lines,
    required this.totalPaise,
    required this.placedAtMillis,
  });

  final String id;

  /// `productId#size` keys, matching the cart's line identity.
  final List<String> lines;
  final int totalPaise;
  final int placedAtMillis;

  Money get total => Money(totalPaise);
  DateTime get placedAt => DateTime.fromMillisecondsSinceEpoch(placedAtMillis);

  /// Product ids without the size suffix — what the Locker cares about.
  Iterable<String> get productIds => lines.map((l) => l.split('#').first);

  Map<String, dynamic> toJson() => {
        'id': id,
        'lines': lines,
        'totalPaise': totalPaise,
        'placedAtMillis': placedAtMillis,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        lines: (json['lines'] as List<dynamic>).cast<String>(),
        totalPaise: json['totalPaise'] as int,
        placedAtMillis: json['placedAtMillis'] as int,
      );
}

/// Order history — the sole source of truth for what a shopper owns.
///
/// ⚠️ `place` currently completes an order **without taking payment**. It
/// exists so the acquisition loop (bag → checkout → card) is real and testable
/// before a gateway is wired. In Phase 7 this becomes: authorise payment →
/// server creates the order → client reads it back. Nothing else in the app
/// needs to change, because everything already reads orders rather than
/// inferring ownership.
class OrdersController extends Notifier<List<Order>> {
  static const _key = 'orders_v1';

  @override
  List<Order> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  void _commit(List<Order> orders) {
    state = List.unmodifiable(orders);
    ref.read(sharedPreferencesProvider).setString(
          _key,
          jsonEncode(orders.map((o) => o.toJson()).toList()),
        );
  }

  /// Completes the current bag as an order and empties it.
  ///
  /// Returns null when the bag is empty — an order with no lines is not a
  /// thing, and silently creating one would put a phantom card in the Locker.
  Order? place({required int nowMillis}) {
    final lines = ref.read(cartProvider);
    if (lines.isEmpty) return null;

    final order = Order(
      id: 'ord-${nowMillis.toRadixString(36)}',
      lines: lines.map((l) => l.key).toList(growable: false),
      totalPaise: ref.read(cartTotalProvider).paise,
      placedAtMillis: nowMillis,
    );

    _commit([order, ...state]);
    ref.read(cartProvider.notifier).clear();
    return order;
  }
}

final ordersProvider =
    NotifierProvider<OrdersController, List<Order>>(OrdersController.new);

/// The record of one shopper's copy of one product.
///
/// This is what makes a card a collectible rather than a catalogue listing with
/// a border: brand, price and size run describe the *product*, and every owner
/// of it sees the same values. Size bought, date acquired and copies held
/// describe *this* copy, and are the only things on the card that are yours.
///
/// All of it is already in the order lines. None of it is new data.
class Provenance {
  const Provenance({
    required this.sizes,
    required this.acquired,
    required this.copies,
  });

  /// Sizes actually bought, smallest first.
  final List<String> sizes;

  /// When the first pair was bought.
  final DateTime acquired;

  /// Pairs held — a second size is a second pair, and reads as one.
  final int copies;
}

final provenanceProvider =
    Provider.family<Provenance?, String>((ref, productId) {
  final sizes = <String>[];
  DateTime? earliest;

  for (final order in ref.watch(ordersProvider)) {
    for (final line in order.lines) {
      final parts = line.split('#');
      if (parts.first != productId) continue;
      if (parts.length > 1 && parts[1].isNotEmpty) sizes.add(parts[1]);
      if (earliest == null || order.placedAt.isBefore(earliest)) {
        earliest = order.placedAt;
      }
    }
  }

  if (earliest == null) return null;

  final distinct = sizes.toSet().toList()
    ..sort(
        (a, b) => (double.tryParse(a) ?? 0).compareTo(double.tryParse(b) ?? 0));

  return Provenance(
    sizes: distinct,
    acquired: earliest,
    copies: sizes.length,
  );
});

/// The size the shopper buys most, or null before there is enough to say.
///
/// Read off the order lines, which already carry `productId#size`. A sneaker
/// collection is partly a statement about a foot, and this is the one number a
/// collector would actually put on a profile. Ties break towards the size
/// bought most recently, since orders are stored newest-first.
final usualSizeProvider = Provider<String?>((ref) {
  final counts = <String, int>{};
  for (final order in ref.watch(ordersProvider)) {
    for (final line in order.lines) {
      final parts = line.split('#');
      if (parts.length < 2 || parts[1].isEmpty) continue;
      counts[parts[1]] = (counts[parts[1]] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) return null;

  var best = counts.entries.first;
  for (final entry in counts.entries) {
    if (entry.value > best.value) best = entry;
  }
  return best.key;
});

/// Product ids the shopper owns, derived from order history.
///
/// Distinct: buying the same model twice is still one card. The card
/// represents the shoe, not the receipt.
final ownedProductIdsProvider = Provider<Set<String>>((ref) {
  return {
    for (final order in ref.watch(ordersProvider)) ...order.productIds,
  };
});
