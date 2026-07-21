import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/typography.dart';

/// Adds [product] to the bag, asking for a size first.
///
/// Replaces `AppMethods.addToCart`, which had no size concept and used
/// `contains()` to reject an item that was already in the bag — meaning a
/// second pair could never be bought.
Future<void> addToBag(
  BuildContext context,
  WidgetRef ref,
  ShoeModel product, {
  String? size,
}) async {
  final chosen = size ?? await _pickSize(context, product);
  if (chosen == null || !context.mounted) return;

  final isNew = ref.read(cartProvider.notifier).add(product, size: chosen);
  // Haptic confirmation. On mid-range Android especially, this masks latency
  // and makes the action feel acknowledged before the frame lands.
  await HapticFeedback.selectionClick();
  if (!context.mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          isNew
              ? '${product.model} (UK $chosen) added to bag'
              : 'Quantity updated — ${product.model} (UK $chosen)',
        ),
        action: SnackBarAction(label: 'View bag', onPressed: () {}),
      ),
    );
}

Future<String?> _pickSize(BuildContext context, ShoeModel product) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Text('Select size', style: context.text.titleLarge),
            Text(
              // Indian listings quote UK sizing first.
              'UK sizing',
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final s in product.sizes)
                  ActionChip(
                    label: Text(
                      'UK $s',
                      style: context.text.labelLarge
                          ?.copyWith(fontFeatures: AppTypography.tabular),
                    ),
                    onPressed: () => Navigator.pop(context, s),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
