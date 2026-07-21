import 'package:flutter/material.dart';

import 'package:sneakers_app/models/card_meta.dart';
import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/view/locker/widgets/sneaker_card.dart';

/// [SneakerCard] laid out at the size it was designed for, then scaled to fit
/// whatever space it is given.
///
/// The card's type sizes and paddings are absolute, not proportional, so below
/// roughly 180pt of width its info band overflows — which is exactly what
/// happens to a two-up grid on a 390pt phone. Scaling reproduces the design
/// identically at any tile size instead of reflowing it, which is the point:
/// a trading card has one layout, and it gets smaller, not different.
class ScaledSneakerCard extends StatelessWidget {
  const ScaledSneakerCard({
    super.key,
    required this.product,
    required this.meta,
  });

  /// The width the card's internals were tuned against.
  static const designWidth = 220.0;
  static const designHeight = designWidth * 88 / 63;

  final ShoeModel product;
  final CardMeta meta;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: designWidth,
        height: designHeight,
        child: SneakerCard(product: product, meta: meta),
      ),
    );
  }
}
