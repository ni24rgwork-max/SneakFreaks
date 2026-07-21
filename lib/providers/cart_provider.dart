import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/data/preferences.dart';
import 'package:sneakers_app/models/cart_line.dart';
import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/utils/money.dart';

/// The bag.
///
/// Replaces the previous `List<ShoeModel> itemsOnBag` global. That design made
/// three things impossible: observing the cart (so no badge), holding more than
/// one of an item (`contains` rejected duplicates), and surviving a restart.
/// It also produced a live bug — the bag header cached `itemsOnBag.length` in a
/// `State` field, so the count froze at whatever it was when the screen was
/// first built.
class CartController extends Notifier<List<CartLine>> {
  static const _key = 'cart_lines_v1';

  @override
  List<CartLine> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => CartLine.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      // Corrupt or schema-changed payload: start clean rather than crash on
      // launch. The `_v1` key suffix is how a real migration would be handled.
      return const [];
    }
  }

  void _commit(List<CartLine> lines) {
    state = List.unmodifiable(lines);
    ref.read(sharedPreferencesProvider).setString(
          _key,
          jsonEncode(lines.map((l) => l.toJson()).toList()),
        );
  }

  /// Adds one of [product] in [size], merging into an existing line if the same
  /// product+size is already in the bag.
  ///
  /// Returns true if a new line was created, false if an existing line was
  /// incremented — callers use this to word the confirmation.
  bool add(ShoeModel product, {required String size, int quantity = 1}) {
    final lines = [...state];
    final key = '${product.id}#$size';
    final i = lines.indexWhere((l) => l.key == key);
    if (i >= 0) {
      lines[i] = lines[i].copyWith(quantity: lines[i].quantity + quantity);
      _commit(lines);
      return false;
    }
    lines.add(CartLine(
      productId: product.id,
      size: size,
      quantity: quantity,
    ));
    _commit(lines);
    return true;
  }

  void setQuantity(String lineKey, int quantity) {
    if (quantity <= 0) {
      remove(lineKey);
      return;
    }
    _commit([
      for (final l in state)
        if (l.key == lineKey) l.copyWith(quantity: quantity) else l,
    ]);
  }

  void increment(String lineKey) {
    final line = state.firstWhere((l) => l.key == lineKey);
    setQuantity(lineKey, line.quantity + 1);
  }

  void decrement(String lineKey) {
    final line = state.firstWhere((l) => l.key == lineKey);
    setQuantity(lineKey, line.quantity - 1);
  }

  void remove(String lineKey) =>
      _commit([...state.where((l) => l.key != lineKey)]);

  /// Puts a removed line back at its original position, for undo.
  void restore(CartLine line, int index) {
    final lines = [...state];
    lines.insert(index.clamp(0, lines.length), line);
    _commit(lines);
  }

  void clear() => _commit(const []);
}

final cartProvider =
    NotifierProvider<CartController, List<CartLine>>(CartController.new);

/// A cart line joined to its product. Nothing in the UI resolves products
/// itself.
class ResolvedCartLine {
  const ResolvedCartLine({required this.line, required this.product});
  final CartLine line;
  final ShoeModel product;

  Money get lineTotal => product.price * line.quantity;
  Money? get lineMrp {
    final mrp = product.mrp;
    return mrp == null ? null : mrp * line.quantity;
  }
}

final resolvedCartProvider = Provider<List<ResolvedCartLine>>((ref) {
  final lines = ref.watch(cartProvider);
  return [
    for (final l in lines)
      if (ref.watch(productByIdProvider(l.productId)) case final p?)
        ResolvedCartLine(line: l, product: p),
  ];
});

/// Total number of items — the sum of quantities, not the number of lines.
/// This is what the nav badge shows.
final cartCountProvider = Provider<int>((ref) {
  var n = 0;
  for (final l in ref.watch(cartProvider)) {
    n += l.quantity;
  }
  return n;
});

final cartSubtotalProvider = Provider<Money>((ref) {
  var sum = Money.zero;
  for (final r in ref.watch(resolvedCartProvider)) {
    sum += r.lineTotal;
  }
  return sum;
});

/// Total MRP, for the "you save" line. Falls back to the selling price for
/// products with no MRP so the saving is never overstated.
final cartMrpTotalProvider = Provider<Money>((ref) {
  var sum = Money.zero;
  for (final r in ref.watch(resolvedCartProvider)) {
    sum += r.lineMrp ?? r.lineTotal;
  }
  return sum;
});

final cartSavingsProvider = Provider<Money>((ref) {
  final mrp = ref.watch(cartMrpTotalProvider);
  final sub = ref.watch(cartSubtotalProvider);
  return Money(mrp.paise - sub.paise);
});

/// Free delivery over ₹1,999 — a common threshold in Indian e-commerce and a
/// deliberate nudge toward a larger basket.
const freeDeliveryThreshold = Money(199900);
const deliveryFee = Money(9900);

final deliveryFeeProvider = Provider<Money>((ref) {
  final sub = ref.watch(cartSubtotalProvider);
  if (sub.paise == 0) return Money.zero;
  return sub.paise >= freeDeliveryThreshold.paise ? Money.zero : deliveryFee;
});

final cartTotalProvider = Provider<Money>((ref) {
  return ref.watch(cartSubtotalProvider) + ref.watch(deliveryFeeProvider);
});
