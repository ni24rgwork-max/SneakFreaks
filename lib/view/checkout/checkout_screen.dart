import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/typography.dart';

/// Checkout placeholder.
///
/// Full-screen above the shell — the bottom nav should not be reachable
/// mid-payment. Reached only when the router's auth guard passes.
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              Text('Payable now', style: context.text.labelLarge),
              Text(
                total.formatted,
                style: context.text.displaySmall
                    ?.copyWith(fontFeatures: AppTypography.tabular),
              ),
              const SizedBox(height: 6),
              Text(
                'Payments are not implemented. UPI, cards, netbanking and COD '
                'land here — UPI leaves the app and returns via deep link, '
                'which is why routing had to exist first.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
