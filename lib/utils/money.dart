import 'package:intl/intl.dart';

/// Money as integer paise.
///
/// Never use `double` for currency: binary floating point cannot represent 0.1
/// exactly, so totals drift once quantities, discounts and tax are applied —
/// and payment gateways reject amounts that disagree by a paisa.
extension type const Money(int paise) implements Object {
  factory Money.rupees(num rupees) => Money((rupees * 100).round());

  Money operator +(Money other) => Money(paise + other.paise);
  Money operator -(Money other) => Money(paise - other.paise);
  Money operator *(int qty) => Money(paise * qty);

  static const Money zero = Money(0);

  double get rupees => paise / 100;

  /// `₹12,999` — note Indian 2,2,3 digit grouping comes from the `en_IN`
  /// locale, not from any custom logic. Whole rupees: Indian retail does not
  /// quote paise, and `₹12,999.00` reads foreign.
  String get formatted => _inr.format(rupees);

  /// `₹1.5L` / `₹1.25Cr` — lakh/crore suffixes, also locale-supplied.
  String get compact => _inrCompact.format(rupees);
}

final NumberFormat _inr =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

final NumberFormat _inrCompact = NumberFormat.compactCurrency(
    locale: 'en_IN', symbol: '₹', decimalDigits: 1);
