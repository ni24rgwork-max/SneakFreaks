import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/providers/pdp_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/brand_tokens.dart';
import 'package:sneakers_app/theme/typography.dart';

/// Size picker.
///
/// The previous version put "UK" and "USA" in two fixed-width text buttons
/// sized `width / 9` — too narrow for the label, so "UK" wrapped onto two
/// lines. A `SegmentedButton` sizes to its content and reads as a toggle rather
/// than two unrelated links.
class SizeSelector extends ConsumerWidget {
  const SizeSelector({super.key, required this.product});

  final ShoeModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final system = ref.watch(sizeSystemProvider);
    final selected = ref.watch(selectedSizeProvider(product.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Select size', style: context.text.titleMedium)),
              SegmentedButton<SizeSystem>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  textStyle: context.text.labelMedium,
                  visualDensity: VisualDensity.compact,
                ),
                segments: const [
                  ButtonSegment(value: SizeSystem.uk, label: Text('UK')),
                  ButtonSegment(value: SizeSystem.us, label: Text('US')),
                ],
                selected: {system},
                onSelectionChanged: (s) =>
                    ref.read(sizeSystemProvider.notifier).select(s.first),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final size in product.sizes)
                _SizeChip(
                  label: convertSize(size, system),
                  selected: selected == size,
                  available: product.isSizeAvailable(size),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(selectedSizeProvider(product.id).notifier).select(size);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _showSizeChart(context, product),
            icon: const Icon(Icons.straighten, size: 17),
            label: const Text('Size chart'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }

  void _showSizeChart(BuildContext context, ShoeModel product) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text('Size chart', style: context.text.titleLarge),
              Text(
                'UK sizing is what Indian listings quote. US is roughly UK + 1, '
                'though it varies by brand — a real chart comes from supplier '
                'data per brand.',
                style: context.text.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              for (final size in product.sizes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text('UK $size',
                            style: context.text.bodyMedium?.copyWith(
                                fontFeatures: AppTypography.tabular)),
                      ),
                      Text('US ${convertSize(size, SizeSystem.us)}',
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            fontFeatures: AppTypography.tabular,
                          )),
                      const Spacer(),
                      if (!product.isSizeAvailable(size))
                        Text('Sold out',
                            style: context.text.labelSmall
                                ?.copyWith(color: context.colors.error)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Sold-out sizes are shown struck through rather than hidden: a shopper can
    // see their size exists at all, which is the difference between "not for
    // me" and "out of stock right now".
    final fg = !available
        ? context.colors.onSurfaceVariant
        : selected
            ? context.colors.onPrimary
            : context.colors.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      enabled: available,
      label: available ? 'Size $label' : 'Size $label, sold out',
      child: AnimatedContainer(
        duration: BrandTokens.motionFast,
        curve: BrandTokens.motionEmphasized,
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primary
              : context.colors.surfaceContainerLow,
          border: Border.all(
            color: selected
                ? context.colors.primary
                : context.brand.interactiveBorder,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: available ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              label,
              style: context.text.titleSmall?.copyWith(
                color: fg,
                fontFeatures: AppTypography.tabular,
                decoration: available ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
