import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/data/dummy_data.dart';
import 'package:sneakers_app/models/shoe_model.dart';

/// The product catalogue.
///
/// Currently backed by the in-memory fixture. When a backend lands this becomes
/// an `AsyncNotifierProvider` returning `AsyncValue<List<ShoeModel>>` and every
/// consumer already goes through this provider, so the change is contained.
final catalogueProvider = Provider<List<ShoeModel>>((ref) => availableShoes);

/// Product lookup by id, used by the cart to resolve its lines.
final productByIdProvider = Provider.family<ShoeModel?, String>((ref, id) {
  final catalogue = ref.watch(catalogueProvider);
  for (final p in catalogue) {
    if (p.id == id) return p;
  }
  return null;
});

/// Distinct brands, for the multi-brand filter row.
final brandsProvider = Provider<List<String>>((ref) {
  final seen = <String>{};
  for (final p in ref.watch(catalogueProvider)) {
    seen.add(p.name);
  }
  return seen.toList();
});
