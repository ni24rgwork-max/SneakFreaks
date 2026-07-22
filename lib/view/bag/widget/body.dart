import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/routing/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/models/cart_line.dart';
import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/typography.dart';
import 'package:sneakers_app/utils/money.dart';
import 'package:sneakers_app/view/bag/widget/empty_list.dart';

class BodyBagView extends ConsumerWidget {
  const BodyBagView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Every value below is derived from the provider on each build. The old
    // screen cached `itemsOnBag.length` in a State field, which froze the
    // count at whatever it was when the screen was first constructed.
    final lines = ref.watch(resolvedCartProvider);
    final count = ref.watch(cartCountProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('My Bag', style: context.text.displaySmall),
              const Spacer(),
              Text(
                count == 1 ? '1 item' : '$count items',
                style: context.text.labelLarge
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (lines.isEmpty)
          const Expanded(child: EmptyList())
        else ...[
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: lines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) => _CartTile(resolved: lines[i]),
            ),
          ),
          const _Summary(),
        ],
      ],
    );
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.resolved});
  final ResolvedCartLine resolved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = resolved.product;
    final line = resolved.line;
    final cart = ref.read(cartProvider.notifier);
    final index = ref.read(cartProvider).indexWhere((l) => l.key == line.key);

    return Dismissible(
      key: ValueKey(line.key),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        color: context.colors.error.withValues(alpha: 0.14),
        child: Icon(Icons.delete_outline, color: context.colors.error),
      ),
      onDismissed: (_) {
        cart.remove(line.key);
        // Destructive actions get an undo rather than a confirm dialog — fewer
        // taps in the common case, still recoverable in the rare one.
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${product.model} removed'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => cart.restore(line, index),
              ),
            ),
          );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          spacing: 14,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: product.modelColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(context.brand.cardRadius),
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(product.imgAddress, fit: BoxFit.contain),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    product.name,
                    style: context.text.labelMedium
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  Text(product.model, style: context.text.titleMedium),
                  Text(
                    'UK ${line.size}',
                    style: context.text.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        resolved.lineTotal.formatted,
                        style: context.text.titleMedium
                            ?.copyWith(fontFeatures: AppTypography.tabular),
                      ),
                      const Spacer(),
                      _QuantityStepper(line: line),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends ConsumerWidget {
  const _QuantityStepper({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.brand.hairline),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: line.quantity == 1
                ? Icons.delete_outline
                : Icons.remove_rounded,
            onTap: () => cart.decrement(line.key),
            tooltip: line.quantity == 1 ? 'Remove' : 'Decrease quantity',
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${line.quantity}',
              textAlign: TextAlign.center,
              style: context.text.titleSmall
                  ?.copyWith(fontFeatures: AppTypography.tabular),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: () => cart.increment(line.key),
            tooltip: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 17, color: context.colors.onSurface),
        ),
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final mrpTotal = ref.watch(cartMrpTotalProvider);
    final savings = ref.watch(cartSavingsProvider);
    final delivery = ref.watch(deliveryFeeProvider);
    final total = ref.watch(cartTotalProvider);
    final toFreeDelivery = Money(freeDeliveryThreshold.paise - subtotal.paise);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.brand.sheetRadius),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          if (delivery.paise > 0 && toFreeDelivery.paise > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add ${toFreeDelivery.formatted} more for free delivery',
                style: context.text.bodySmall
                    ?.copyWith(color: context.brand.accentText),
              ),
            ),
          // Starts from total MRP so the rows actually add up. Listing the
          // discounted subtotal first and then subtracting the discount again
          // double-counts it and reads as broken arithmetic.
          _SummaryRow(label: 'Total MRP', value: mrpTotal.formatted),
          if (savings.paise > 0)
            _SummaryRow(
              label: 'Discount',
              value: '− ${savings.formatted}',
              valueColor: context.brand.success,
            ),
          _SummaryRow(
            label: 'Delivery',
            value: delivery.paise == 0 ? 'FREE' : delivery.formatted,
            valueColor: delivery.paise == 0 ? context.brand.success : null,
          ),
          Divider(color: context.brand.hairline, height: 14),
          Row(
            children: [
              Text('Total', style: context.text.titleMedium),
              const Spacer(),
              Text(
                total.formatted,
                style: context.text.headlineSmall
                    ?.copyWith(fontFeatures: AppTypography.tabular),
              ),
            ],
          ),
          if (savings.paise > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'You saved ${savings.formatted}',
                style: context.text.labelMedium
                    ?.copyWith(color: context.brand.success),
              ),
            ),
          Text(
            'Inclusive of all taxes',
            style: context.text.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: () => context.push(Routes.checkout),
            child: const Text('Proceed to checkout'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: context.text.bodyMedium
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          value,
          style: context.text.bodyMedium?.copyWith(
            color: valueColor,
            fontFeatures: AppTypography.tabular,
          ),
        ),
      ],
    );
  }
}
