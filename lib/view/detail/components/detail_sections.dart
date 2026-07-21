import 'package:flutter/material.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/theme/app_theme.dart';

/// Description, specs and policy, as accordions.
///
/// The previous page put the description in a fixed-height box that sliced the
/// text mid-sentence with no ellipsis. Collapsible sections let copy be any
/// length without either clipping it or burying the size selector below a wall
/// of text.
class DetailSections extends StatelessWidget {
  const DetailSections({super.key, required this.product});

  final ShoeModel product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Column(
        children: [
          _Section(
            title: 'Description',
            initiallyExpanded: true,
            child: Text(
              product.description ?? 'Description coming soon.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          if (product.specs.isNotEmpty)
            _Section(
              title: 'Product details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  for (final entry in product.specs.entries)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(entry.key,
                              style: context.text.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                        ),
                        Expanded(
                          child: Text(entry.value,
                              style: context.text.bodySmall),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          _Section(
            title: 'Delivery & returns',
            child: Text(
              'Free delivery on orders over ₹1,999. 14-day exchange on unworn '
              'items in original packaging. Cash on delivery available.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Strip the default ExpansionTile dividers; the hairline below does the
      // separating so spacing stays on the design system's terms.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Column(
        children: [
          ExpansionTile(
            title: Text(title, style: context.text.titleSmall),
            initiallyExpanded: initiallyExpanded,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [child],
          ),
          Divider(height: 1, color: context.brand.hairline),
        ],
      ),
    );
  }
}
