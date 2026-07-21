import 'package:flutter/material.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/typography.dart';

/// Brand, name, price and — critically — the discount.
///
/// The previous page showed a bare selling price. The feed it was opened from
/// showed "24% OFF" with a struck MRP, so the strongest purchase signal
/// vanished at exactly the moment the decision gets made.
class PriceBlock extends StatelessWidget {
  const PriceBlock({super.key, required this.product});

  final ShoeModel product;

  @override
  Widget build(BuildContext context) {
    final discount = product.discountPercent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            product.name,
            style: context.text.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          Text(product.model, style: context.text.headlineMedium),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10,
            children: [
              Text(
                product.price.formatted,
                style: context.text.headlineSmall
                    ?.copyWith(fontFeatures: AppTypography.tabular),
              ),
              if (product.mrp case final mrp?)
                Text(
                  mrp.formatted,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.brand.priceStrike,
                    decoration: TextDecoration.lineThrough,
                    fontFeatures: AppTypography.tabular,
                  ),
                ),
              if (discount != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.brand.sale,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$discount% OFF',
                    style: context.text.labelSmall
                        ?.copyWith(color: context.brand.onSale),
                  ),
                ),
            ],
          ),
          Text(
            'Inclusive of all taxes',
            style: context.text.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          // Indicative only — a real figure comes from the gateway.
          Text(
            'EMI from ${product.emiPerMonth.formatted}/month',
            style: context.text.bodySmall
                ?.copyWith(color: context.brand.accentText),
          ),
        ],
      ),
    );
  }
}
