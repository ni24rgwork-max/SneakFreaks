import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/providers/orders_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/motion.dart';
import 'package:sneakers_app/theme/typography.dart';

/// Checkout.
///
/// Full-screen above the shell — the bottom nav should not be reachable
/// mid-payment. Reached only once the router's auth guard passes.
///
/// ⚠️ **No payment is taken.** Placing an order here completes it directly.
/// That exists so the acquisition loop — bag → order → card — is real and
/// testable before a gateway is wired. Phase 7 replaces the button's action
/// with: authorise payment → server creates the order → client reads it back.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _placed = false;
  int _cardsEarned = 0;

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(cartTotalProvider);
    final count = ref.watch(cartCountProvider);

    if (_placed) return _Confirmation(cardsEarned: _cardsEarned);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text('Payable now', style: context.text.labelLarge),
              Text(
                total.formatted,
                style: context.text.displaySmall
                    ?.copyWith(fontFeatures: AppTypography.tabular),
              ),
              Text(
                count == 1 ? '1 item' : '$count items',
                style: context.text.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(context.brand.cardRadius),
                  border: Border.all(color: context.brand.hairline),
                ),
                child: Row(
                  spacing: 10,
                  children: [
                    Icon(Icons.style_outlined,
                        size: 20, color: context.brand.accentText),
                    Expanded(
                      child: Text(
                        'Each pair adds its card to your Locker.',
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Payments are not implemented. UPI, cards, netbanking and COD '
                'land here — UPI leaves the app and returns via deep link, '
                'which is why routing had to exist first.',
                style: context.text.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: count == 0 ? null : _place,
                child: const Text('PLACE ORDER'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _place() {
    // Counted before placing, since the bag is cleared as part of it.
    final earned =
        ref.read(cartProvider).map((l) => l.productId).toSet().length;

    // DateTime.now() lives at the call site rather than inside the notifier so
    // the store stays deterministic and testable.
    final order = ref
        .read(ordersProvider.notifier)
        .place(nowMillis: DateTime.now().millisecondsSinceEpoch);

    if (order == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _placed = true;
      _cardsEarned = earned;
    });
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.cardsEarned});

  final int cardsEarned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Icon(Icons.check_circle, size: 56, color: context.brand.success)
                    .enter(context),
                Text('Order placed', style: context.text.headlineSmall)
                    .enter(context, index: 1),
                Text(
                  cardsEarned == 1
                      ? '1 new card is in your Locker.'
                      : '$cardsEarned new cards are in your Locker.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ).enter(context, index: 2),
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: () => context.go(Routes.profile),
                  child: const Text('Open the Locker'),
                ).enter(context, index: 3),
                TextButton(
                  onPressed: () => context.go(Routes.home),
                  child: const Text('Keep shopping'),
                ).enter(context, index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
