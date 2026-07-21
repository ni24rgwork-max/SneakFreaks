import 'package:flutter/material.dart';

import 'package:sneakers_app/utils/money.dart';

class ShoeModel {
  const ShoeModel({
    required this.id,
    required this.name,
    required this.model,
    required this.price,
    required this.imgAddress,
    required this.modelColor,
    this.mrp,
    this.sizes = const ['6', '7.5', '8', '9.5', '10'],
    this.isNew = false,
    this.dropsOn,
    this.description,
    this.specs = const {},
    this.soldOutSizes = const [],
    this.images = const [],
    this.tags = const [],
  });

  /// Stable identity. The cart stores ids rather than product objects, so a
  /// line survives the catalogue being replaced by a backend response.
  final String id;

  /// Brand — Nike, Adidas, Jordan, Puma. This is a multi-brand storefront, so
  /// brand is data, never hardcoded in a screen.
  final String name;

  final String model;

  /// Selling price. See [Money] — integer paise, never double.
  final Money price;

  /// Optional struck-through MRP. Indian listings lead with the % off, so a
  /// product without an MRP simply shows no discount badge.
  final Money? mrp;

  final String imgAddress;

  /// UK sizing, which is what Indian listings quote.
  final List<String> sizes;

  /// Drives the New Arrivals rail and the NEW badge.
  final bool isNew;

  /// Release date for an unreleased drop. Non-null means the product is
  /// announced but not yet purchasable — it appears under Upcoming and is
  /// excluded from every buyable rail.
  final DateTime? dropsOn;

  bool get isUpcoming => dropsOn != null;

  /// Marketing copy. Null renders a "description coming soon" state rather
  /// than the lorem ipsum the old detail page hardcoded — a placeholder that
  /// admits it is one beats prose that looks real and isn't.
  final String? description;

  /// Spec rows (material, closure, use case). Populated at catalogue
  /// ingestion — see docs/AI.md.
  final Map<String, String> specs;

  /// Sizes announced but unavailable. Rendered struck through rather than
  /// hidden, so a shopper can see their size exists and set a notification.
  final List<String> soldOutSizes;

  /// Gallery images. Falls back to the single [imgAddress] when a product has
  /// only one shot — the previous page faked four thumbnails of the same photo.
  final List<String> images;

  List<String> get gallery => images.isEmpty ? [imgAddress] : images;

  bool isSizeAvailable(String size) => !soldOutSizes.contains(size);

  /// Indicative EMI over 12 months, no interest assumed. Display-only — a real
  /// figure comes from the payment gateway at checkout.
  Money get emiPerMonth => Money((price.paise / 12).round());

  /// Editorial collection membership, e.g. 'monsoon'. Free-form so a backend
  /// can add collections without a client release.
  final List<String> tags;

  // TODO(backend): `Color` is a UI concern and is not serializable — it has to
  // leave this model before a backend supplies the catalogue.
  final Color modelColor;

  int? get discountPercent {
    final m = mrp;
    if (m == null || m.paise <= price.paise) return null;
    return (((m.paise - price.paise) / m.paise) * 100).round();
  }
}
