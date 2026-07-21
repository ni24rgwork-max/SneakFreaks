import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session state.
///
/// A deliberate stub: there is no auth implementation yet, but the router's
/// guard reads this, so the gate is in place before checkout is built rather
/// than bolted on afterwards. Replace with a real session (token, refresh,
/// secure storage) when auth lands.
class AuthController extends Notifier<bool> {
  @override
  bool build() => false;

  void signIn() => state = true;
  void signOut() => state = false;
}

final authProvider = NotifierProvider<AuthController, bool>(AuthController.new);
