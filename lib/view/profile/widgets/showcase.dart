import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sneakers_app/providers/locker_provider.dart';
import 'package:sneakers_app/providers/profile_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/typography.dart';
import 'package:sneakers_app/view/locker/widgets/scaled_sneaker_card.dart';
import 'package:sneakers_app/view/profile/widgets/featured_card_picker.dart';

/// The user-chosen hero of the profile.
class ProfileShowcaseView extends ConsumerWidget {
  const ProfileShowcaseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showcase = ref.watch(profileShowcaseProvider);
    final stats = ref.watch(lockerStatsProvider);

    // With nothing collected there is nothing to showcase, whichever mode is
    // selected. Prompting beats rendering an ornate empty frame.
    if (stats.isEmpty && showcase != ProfileShowcase.minimal) {
      return const _NothingYet();
    }

    return switch (showcase) {
      ProfileShowcase.locker => const _LockerShowcase(),
      ProfileShowcase.stats => const _StatsShowcase(),
      ProfileShowcase.minimal => const SizedBox.shrink(),
    };
  }
}

/// **One** card, the one the user chose.
///
/// A rail of everything owned is the Locker's job, and putting it here made the
/// profile a second binder. A single card is a pick — it says something about
/// the person, which is what a profile is for.
class _LockerShowcase extends ConsumerWidget {
  const _LockerShowcase();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(featuredCardProvider);
    if (card == null) return const _NothingYet();

    final isAutomatic = ref.watch(featuredCardIdProvider) == null;

    return Column(
      spacing: 12,
      children: [
        // Sized against the card's own 220pt design width, centred: the hero
        // of the page, not an item in a list.
        GestureDetector(
          onTap: () => showFeaturedCardPicker(context),
          child: SizedBox(
            width: 240,
            child: ScaledSneakerCard(product: card.product, meta: card.meta),
          ),
        ),
        TextButton.icon(
          onPressed: () => showFeaturedCardPicker(context),
          icon: const Icon(Icons.swap_horiz, size: 18),
          label: Text(isAutomatic ? 'Pick your card' : 'Change card'),
        ),
      ],
    );
  }
}

class _StatsShowcase extends ConsumerWidget {
  const _StatsShowcase();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(lockerStatsProvider);
    final tier = ref.watch(collectorTierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        spacing: 12,
        children: [
          _Tile(value: '${stats.owned}', label: 'pairs'),
          _Tile(value: '${stats.brands}', label: 'brands'),
          _Tile(value: '${stats.owned}/${stats.total}', label: 'of the set'),
          _Tile(value: tier.label, label: 'tier', wide: true),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label, this.wide = false});

  final String value;
  final String label;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: wide ? 2 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(context.brand.cardRadius),
          border: Border.all(color: context.brand.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleLarge
                  ?.copyWith(fontFeatures: AppTypography.tabular),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _NothingYet extends StatelessWidget {
  const _NothingYet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.brand.cardRadius),
        border: Border.all(color: context.brand.hairline),
      ),
      child: Row(
        spacing: 14,
        children: [
          Icon(Icons.style_outlined,
              size: 30, color: context.colors.onSurfaceVariant),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text('Nothing to showcase yet', style: context.text.titleSmall),
                Text(
                  'Your first pair earns your first card.',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
