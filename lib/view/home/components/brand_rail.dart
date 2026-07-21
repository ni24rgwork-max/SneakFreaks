import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';

/// Brand filter.
///
/// Replaces the rotated New/Featured/Upcoming column and the static brand text
/// list. Both of those were decorative — neither changed a single product. This
/// one narrows the entire feed, and only lists brands with stock.
class BrandRail extends ConsumerWidget {
  const BrandRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brands = ref.watch(brandsProvider);
    final selected = ref.watch(brandFilterProvider);
    final controller = ref.read(brandFilterProvider.notifier);

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => controller.select(null),
          ),
          for (final brand in brands)
            _Chip(
              label: brand,
              selected: selected == brand,
              onTap: () => controller.toggle(brand),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? context.colors.primary
            : context.colors.surfaceContainer,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? context.colors.primary : context.brand.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: context.text.labelLarge?.copyWith(
                color: selected
                    ? context.colors.onPrimary
                    : context.colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
