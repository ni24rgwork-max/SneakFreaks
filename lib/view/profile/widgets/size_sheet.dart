import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/providers/orders_provider.dart';
import 'package:sneakers_app/providers/profile_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';

/// Set the size shown on the profile.
Future<void> showSizeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _SizeSheet(),
  );
}

class _SizeSheet extends ConsumerWidget {
  const _SizeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizes = <String>{
      for (final product in ref.watch(catalogueProvider)) ...product.sizes,
    }.toList()
      ..sort((a, b) =>
          (double.tryParse(a) ?? 0).compareTo(double.tryParse(b) ?? 0));

    final chosen = ref.watch(preferredSizeProvider);
    final usual = ref.watch(usualSizeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text('Your size', style: context.text.headlineSmall),
            Text(
              chosen == null && usual != null
                  ? 'Taken from what you buy. Set it yourself if that is wrong.'
                  : 'Shown on your profile.',
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final size in sizes)
                  _SizeChip(
                    label: 'UK $size',
                    selected: size == chosen,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(preferredSizeProvider.notifier).select(size);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            if (chosen != null && usual != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () {
                  ref.read(preferredSizeProvider.notifier).clear();
                  Navigator.of(context).pop();
                },
                child: Text('Use what I buy (UK $usual)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.colors.onSurface
          : context.colors.surfaceContainerHigh,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color:
                  selected ? context.colors.surface : context.colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
