import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/typography.dart';
import 'package:sneakers_app/routing/routes.dart';

/// The compact product tile used by every rail and grid in the feed.
///
/// One widget rather than the three near-identical hand-built card layouts the
/// old home screen carried — those had already drifted apart in padding, radius
/// and price styling.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.width = 168});

  final ShoeModel product;
  final double width;

  @override
  Widget build(BuildContext context) {
    final discount = product.discountPercent;

    return GestureDetector(
      onTap: () => context.push(Routes.productPath(product.id)),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerLowest,
                  borderRadius:
                      BorderRadius.circular(context.brand.cardRadius),
                  border: Border.all(color: context.brand.hairline),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        // No Hero here: the same product renders in several
                        // rails at once, and duplicate tags in one subtree
                        // throw. The carousel is the single hero source.
                        // TODO(phase-6): OpenContainer transition per card.
                        child: Image.asset(
                          product.imgAddress,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (discount != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
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
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        onPressed: () {},
                        iconSize: 19,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.favorite_border),
                        color: context.colors.onSurfaceVariant,
                        tooltip: 'Save ${product.model}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(
                    product.name,
                    style: context.text.labelSmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  Text(
                    product.model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  Row(
                    spacing: 6,
                    children: [
                      Text(
                        product.price.formatted,
                        style: context.text.titleSmall
                            ?.copyWith(fontFeatures: AppTypography.tabular),
                      ),
                      if (product.mrp case final mrp?)
                        Flexible(
                          child: Text(
                            mrp.formatted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall?.copyWith(
                              color: context.brand.priceStrike,
                              decoration: TextDecoration.lineThrough,
                              fontFeatures: AppTypography.tabular,
                            ),
                          ),
                        ),
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
