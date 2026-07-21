import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sneakers_app/data/dummy_data.dart';
import 'package:sneakers_app/data/preferences.dart';
import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/catalogue_provider.dart';

/// Overrides shared by every widget test.
///
/// The catalogue is asynchronous with a deliberate delay so skeleton states get
/// exercised in development. Tests override the two derived providers instead
/// of waiting on that delay — everything downstream reads through these, so the
/// data is real and only the latency is removed.
Future<List<Override>> testOverrides({
  List<ShoeModel>? catalogue,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    catalogueProvider.overrideWithValue(catalogue ?? availableShoes),
    catalogueLoadingProvider.overrideWithValue(false),
  ];
}
