import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/pdp_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/typography.dart';
import 'package:sneakers_app/widget/add_to_bag.dart';

/// Persistent purchase bar.
///
/// The old page put ADD TO BAG inline in the scroll column, so it left the
/// screen as soon as you read the description. On a page whose entire job is
/// converting, the primary action has to stay reachable.
class BuyBar extends ConsumerWidget {
  const BuyBar({super.key, required this.product});

  final ShoeModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSize = ref.watch(selectedSizeProvider(product.id));
    final upcoming = product.isUpcoming;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: context.brand.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            spacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (upcoming)
                    Text(
                      'Drops ${DateFormat('d MMM').format(product.dropsOn!)}',
                      style: context.text.titleMedium
                          ?.copyWith(fontFeatures: AppTypography.tabular),
                    )
                  else ...[
                    Text(
                      product.price.formatted,
                      style: context.text.titleLarge
                          ?.copyWith(fontFeatures: AppTypography.tabular),
                    ),
                    Text(
                      selectedSize == null ? 'Select a size' : 'UK $selectedSize',
                      style: context.text.bodySmall?.copyWith(
                        color: selectedSize == null
                            ? context.brand.accentText
                            : context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (upcoming) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                            content: Text("We'll notify you when it drops")));
                      return;
                    }
                    // Passing the chosen size through means the sheet only
                    // opens when nothing is selected yet.
                    addToBag(context, ref, product, size: selectedSize);
                  },
                  child: Text(upcoming ? 'NOTIFY ME' : 'ADD TO BAG'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
