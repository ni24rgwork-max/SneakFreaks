import 'package:flutter/material.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/view/home/components/product_card.dart';

/// A horizontally scrolling row of [ProductCard]s.
class ProductRail extends StatelessWidget {
  const ProductRail({super.key, required this.products, this.cardWidth = 168});

  final List<ShoeModel> products;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Card is `cardWidth` wide with a 1:1 image plus three text lines.
      height: cardWidth + 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) =>
            ProductCard(product: products[i], width: cardWidth),
      ),
    );
  }
}
