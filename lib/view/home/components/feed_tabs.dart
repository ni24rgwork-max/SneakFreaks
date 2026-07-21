import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/brand_tokens.dart';

/// New / Featured / Upcoming — the hero's view selector.
///
/// Deliberately underline tabs rather than pills. Brand is already a row of
/// filled chips directly above, and two rows of identical-looking chips would
/// read as one long filter list instead of two independent axes. Different
/// control shape, different meaning.
class FeedTabs extends ConsumerWidget {
  const FeedTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(featuredTabProvider);
    final controller = ref.read(featuredTabProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          for (final tab in FeaturedTab.values)
            _Tab(
              label: tab.label,
              selected: tab == selected,
              onTap: () => controller.select(tab),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
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
      padding: const EdgeInsets.only(right: 24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: BrandTokens.motionFast,
              curve: BrandTokens.motionEmphasized,
              style: (selected
                      ? context.text.titleMedium
                      : context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w400,
                        )) ??
                  const TextStyle(),
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? context.colors.onSurface
                      : context.colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // The indicator keeps its footprint when inactive so the row does
            // not shift vertically as the selection moves.
            AnimatedContainer(
              duration: BrandTokens.motionFast,
              curve: BrandTokens.motionEmphasized,
              height: 2,
              width: selected ? 22 : 0,
              decoration: BoxDecoration(
                color: context.colors.onSurface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
