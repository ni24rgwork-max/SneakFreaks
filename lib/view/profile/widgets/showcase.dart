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
///
/// Framed and captioned rather than floating: a caption naming what the card is
/// and a halo in its own type colour make it read as *placed* rather than left
/// there. The colour is the card's, not an invented accent.
class _LockerShowcase extends ConsumerWidget {
  const _LockerShowcase();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(featuredCardProvider);
    if (card == null) return const _NothingYet();

    final isAutomatic = ref.watch(featuredCardIdProvider) == null;
    final accent = card.meta.type.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isAutomatic ? 'YOUR RAREST' : 'YOUR CARD',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              _PickChip(
                label: isAutomatic ? 'Pick' : 'Change',
                onTap: () => showFeaturedCardPicker(context),
              ),
            ],
          ),
          Center(
            child: GestureDetector(
              onTap: () => showFeaturedCardPicker(context),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    // Halo in the card\'s own type colour — the thing that
                    // makes it read as displayed rather than dropped.
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 44,
                      spreadRadius: -6,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 232,
                  child:
                      ScaledSneakerCard(product: card.product, meta: card.meta),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '${card.meta.rarity.label} · ${card.meta.type.label} · '
              '${card.meta.setLabel}',
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontFeatures: AppTypography.tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small, quiet affordance. A full-width button here would compete with the
/// card, which is the only thing on this block worth looking at.
class _PickChip extends StatelessWidget {
  const _PickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerHigh,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(Icons.swap_horiz, size: 15, color: context.colors.onSurface),
              Text(label, style: context.text.labelMedium),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        spacing: 10,
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
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
