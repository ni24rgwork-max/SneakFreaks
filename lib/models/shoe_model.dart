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
