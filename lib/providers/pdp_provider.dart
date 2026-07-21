import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected size, keyed by product id.
///
/// Keyed rather than global so opening a second product does not inherit the
/// first one's selection — a stale size is the kind of thing that silently
/// ships the wrong item.
class SelectedSize extends Notifier<String?> {
  SelectedSize(this.productId);

  /// The family argument arrives via the constructor in Riverpod 3.
  final String productId;

  @override
  String? build() => null;

  void select(String size) => state = size;
  void clear() => state = null;
}

final selectedSizeProvider =
    NotifierProvider.family<SelectedSize, String?, String>(SelectedSize.new);

/// Which sizing system the size row is displayed in.
///
/// Indian listings quote UK first, so that is the default. US is offered
/// because a lot of sneaker buyers know their US size from international
/// releases.
enum SizeSystem { uk, us }

class SizeSystemController extends Notifier<SizeSystem> {
  @override
  SizeSystem build() => SizeSystem.uk;

  void select(SizeSystem s) => state = s;
}

final sizeSystemProvider = NotifierProvider<SizeSystemController, SizeSystem>(
    SizeSystemController.new);

/// UK → US conversion for men's sneakers is UK + 1. Approximate and
/// brand-dependent; a real store maps this per brand from supplier data rather
/// than with arithmetic.
String convertSize(String ukSize, SizeSystem system) {
  if (system == SizeSystem.uk) return ukSize;
  final uk = double.tryParse(ukSize);
  if (uk == null) return ukSize;
  final us = uk + 1;
  return us == us.roundToDouble()
      ? us.toStringAsFixed(0)
      : us.toStringAsFixed(1);
}

/// Delivery estimate for a pincode.
///
/// Deliberately fake: it returns a plausible ETA for any 6-digit input. A real
/// implementation calls a serviceability API, and the difference matters —
/// this must not ship as-is.
class PincodeCheck extends Notifier<PincodeResult?> {
  @override
  PincodeResult? build() => null;

  void check(String pincode) {
    if (pincode.length != 6 || int.tryParse(pincode) == null) {
      state = const PincodeResult.invalid();
      return;
    }
    // TODO(backend): call the serviceability API. This is a stub.
    state = PincodeResult.serviceable(
      pincode: pincode,
      days: 2 + (pincode.hashCode.abs() % 4),
    );
  }

  void clear() => state = null;
}

final pincodeProvider =
    NotifierProvider<PincodeCheck, PincodeResult?>(PincodeCheck.new);

class PincodeResult {
  const PincodeResult.serviceable({required this.pincode, required this.days})
      : valid = true;
  const PincodeResult.invalid()
      : valid = false,
        pincode = '',
        days = 0;

  final bool valid;
  final String pincode;
  final int days;
}
