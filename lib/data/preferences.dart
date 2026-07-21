import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main` once [SharedPreferences] has loaded, so the rest of the
/// app reads it synchronously instead of threading a FutureProvider through
/// every consumer.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);
