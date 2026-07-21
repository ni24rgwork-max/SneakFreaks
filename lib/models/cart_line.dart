import 'package:flutter/foundation.dart';

/// One line in the bag.
///
/// Stores a product *id* rather than a [ShoeModel]. The product is looked up
/// from the catalogue at read time, so lines survive the catalogue being
/// replaced by a backend response and can be persisted as plain JSON without
/// serializing UI types.
@immutable
class CartLine {
  const CartLine({
    required this.productId,
    required this.size,
    this.quantity = 1,
  });

  final String productId;

  /// UK size code, e.g. "8" or "7.5". Part of the line's identity — the same shoe in two sizes is two
  /// lines, not one with quantity 2.
  final String size;

  final int quantity;

  /// Identity for merge/lookup. Two lines are the same line iff both the
  /// product and the size match.
  String get key => '$productId#$size';

  CartLine copyWith({int? quantity}) => CartLine(
        productId: productId,
        size: size,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() =>
      {'productId': productId, 'size': size, 'quantity': quantity};

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
        productId: json['productId'] as String,
        size: json['size'] as String,
        quantity: json['quantity'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is CartLine &&
      other.productId == productId &&
      other.size == size &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(productId, size, quantity);
}
