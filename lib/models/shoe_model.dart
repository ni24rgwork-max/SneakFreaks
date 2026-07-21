import 'package:flutter/material.dart';

import 'package:sneakers_app/utils/money.dart';

class ShoeModel {
  ShoeModel({
    required this.name,
    required this.model,
    required this.price,
    required this.imgAddress,
    required this.modelColor,
    this.mrp,
  });

  final String name;
  final String model;

  /// Selling price. See [Money] — integer paise, never double.
  final Money price;

  /// Optional struck-through MRP. Indian listings lead with the % off, so a
  /// product without an MRP simply shows no discount badge.
  final Money? mrp;

  final String imgAddress;

  // TODO(phase-3): `Color` is a UI concern and is not serializable — it has to
  // leave this model before a backend supplies the catalogue.
  final Color modelColor;

  int? get discountPercent {
    final m = mrp;
    if (m == null || m.paise <= price.paise) return null;
    return (((m.paise - price.paise) / m.paise) * 100).round();
  }
}
