import 'package:flutter/material.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/utils/money.dart';

/// Collectible-card metadata for a product.
///
/// Everything here is **derived from real catalogue fields** — price, tags,
/// stock. Nothing is invented. A card never asserts a performance figure about
/// a real product; the only numbers on it are the ones the store already
/// publishes.
///
/// The `specs` map on [ShoeModel] is deliberately *not* surfaced yet: those
/// values are placeholders until supplier data lands, and a spec zone is
/// exactly where a reader assumes they are looking at manufacturer facts.
enum CardRarity {
  common('Common', 0),
  uncommon('Uncommon', 900000), // ₹9,000
  rare('Rare', 1200000), // ₹12,000
  ultraRare('Ultra Rare', 1500000); // ₹15,000

  const CardRarity(this.label, this.thresholdPaise);

  final String label;
  final int thresholdPaise;

  /// Rarity follows price, as configured.
  ///
  /// Worth knowing the tradeoff: a price-derived rarity means the rarest cards
  /// belong to whoever spent most. If that ever starts feeling like a spend
  /// badge, scarcity signals — limited sizes, drop-day acquisition — are the
  /// alternative, and switching means changing only this method.
  static CardRarity forPrice(Money price) {
    var result = CardRarity.common;
    for (final r in CardRarity.values) {
      if (price.paise >= r.thresholdPaise) result = r;
    }
    return result;
  }

  /// How many rarity pips the footer shows.
  int get pips => index + 1;
}

/// Card type, in the sense a Pokémon card has an energy type: it colours the
/// frame and gives the set a visual grammar.
///
/// Derived from the product's own tags — not assigned arbitrarily.
enum CardType {
  running('Running', Color(0xFFE0533D), Icons.directions_run),
  court('Court', Color(0xFF3D6FE0), Icons.sports_basketball),
  lifestyle('Lifestyle', Color(0xFF7B5FD6), Icons.nightlife),
  training('Training', Color(0xFF2E9E6B), Icons.fitness_center),
  unclassified('Unclassified', Color(0xFF6B7280), Icons.help_outline);

  const CardType(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  static CardType forProduct(ShoeModel product) {
    for (final tag in product.tags) {
      switch (tag) {
        case 'running':
          return CardType.running;
        case 'court':
          return CardType.court;
        case 'lifestyle':
          return CardType.lifestyle;
        case 'training':
          return CardType.training;
      }
    }
    return CardType.unclassified;
  }
}

/// Everything the card renderer needs, resolved once.
@immutable
class CardMeta {
  const CardMeta({
    required this.rarity,
    required this.type,
    required this.number,
    required this.setSize,
  });

  final CardRarity rarity;
  final CardType type;

  /// Position in the set, e.g. 3 of 8 — printed as `003/008`.
  final int number;
  final int setSize;

  String get setLabel =>
      '${number.toString().padLeft(3, '0')}/${setSize.toString().padLeft(3, '0')}';

  /// Foil intensity rises with rarity. Common cards stay matte, which is what
  /// makes the rare ones read as rare.
  bool get hasFoil => rarity.index >= CardRarity.rare.index;
  bool get hasFullArt => rarity == CardRarity.ultraRare;

  static CardMeta forProduct(
    ShoeModel product, {
    required int number,
    required int setSize,
  }) {
    return CardMeta(
      rarity: CardRarity.forPrice(product.price),
      type: CardType.forProduct(product),
      number: number,
      setSize: setSize,
    );
  }
}
