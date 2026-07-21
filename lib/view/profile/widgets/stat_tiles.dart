import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:intl/intl.dart';

import 'package:sneakers_app/providers/locker_provider.dart';
import 'package:sneakers_app/providers/orders_provider.dart';
import 'package:sneakers_app/providers/profile_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/typography.dart';
import 'package:sneakers_app/view/locker/widgets/scaled_sneaker_card.dart';
import 'package:sneakers_app/view/profile/widgets/featured_card_picker.dart';
import 'package:sneakers_app/view/profile/widgets/size_sheet.dart';

/// The profile's data at a glance.
///
/// A grid of small facts rather than one large ornament: the card already has a
/// whole screen of its own in the Locker, and a profile is supposed to answer
/// "who is this person" faster than it answers "what does their card look
/// like". Which tile leads is still the user's call — [ProfileShowcase] chooses
/// what fills the wide tile above the grid.
class ProfileTiles extends ConsumerWidget {
  const ProfileTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(lockerStatsProvider);
    final showcase = ref.watch(profileShowcaseProvider);
    final size = ref.watch(profileSizeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        spacing: 10,
        children: [
          if (!stats.isEmpty) ...[
            switch (showcase) {
              ProfileShowcase.locker => const _FeaturedTile(),
              ProfileShowcase.stats => _ProgressTile(stats: stats),
              ProfileShowcase.minimal => const SizedBox.shrink(),
            },
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: _Tile(
                    value: '${stats.owned}',
                    label: stats.owned == 1 ? 'pair' : 'pairs',
                  ),
                ),
                Expanded(
                  child: _Tile(
                    value: '${stats.brands}',
                    label: stats.brands == 1 ? 'brand' : 'brands',
                  ),
                ),
              ],
            ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: _Tile(
                    value: size == null ? '—' : 'UK $size',
                    label: 'usual size',
                    onTap: () => showSizeSheet(context),
                  ),
                ),
                Expanded(
                  child: _Tile(
                    value: stats.rarest?.label ?? '—',
                    label: 'rarest card',
                  ),
                ),
              ],
            ),
          ] else
            const _NothingYetTile(),
        ],
      ),
    );
  }
}

/// The wide tile: the card, and everything printed on it, beside it.
///
/// The card's own type runs at 6.5–8pt and is unreadable at thumbnail size, so
/// a thumbnail alone is a picture of information rather than the information.
/// The right column restates it at a legible size — same fields, same source,
/// no summary layer in between.
class _FeaturedTile extends ConsumerWidget {
  const _FeaturedTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(featuredCardProvider);
    if (card == null) return const SizedBox.shrink();

    final product = card.product;
    final palette = ref.watch(productPaletteProvider(product.imgAddress));
    final accent = (palette.value ?? seedPalette(product.modelColor)).accent;
    final isAutomatic = ref.watch(featuredCardIdProvider) == null;
    final owned = ref.watch(provenanceProvider(product.id));
    final swatches =
        ref.watch(productColorsProvider(product.imgAddress)).value ??
            const <Color>[];

    return _Panel(
      onTap: () => showFeaturedCardPicker(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isAutomatic ? 'YOUR RAREST' : 'YOUR CARD',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              Icon(Icons.swap_horiz,
                  size: 20, color: context.colors.onSurfaceVariant),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.32),
                      blurRadius: 24,
                      spreadRadius: -6,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 118,
                  child: ScaledSneakerCard(product: product, meta: card.meta),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          product.model,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMedium,
                        ),
                        Text(
                          '${product.name} · ${card.meta.rarity.label} · '
                          '${card.meta.setLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            fontFeatures: AppTypography.tabular,
                          ),
                        ),
                      ],
                    ),
                    _Line(
                      label: 'Price',
                      value: product.price.formatted,
                      trailing: product.discountPercent == null
                          ? null
                          : '${product.discountPercent}% off',
                    ),
                    if (owned != null) ...[
                      _Line(
                        label: 'Yours',
                        value: owned.sizes.isEmpty
                            ? '—'
                            : owned.sizes.map((s) => 'UK $s').join(', '),
                        trailing: owned.copies > 1 ? '×${owned.copies}' : null,
                      ),
                      _Line(
                        label: 'Got',
                        value: DateFormat('d MMM yyyy').format(owned.acquired),
                      ),
                    ],
                    if (swatches.length > 1)
                      Row(
                        spacing: 8,
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              'Colour',
                              style: context.text.labelSmall?.copyWith(
                                  color: context.colors.onSurfaceVariant),
                            ),
                          ),
                          for (final colour in swatches)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colour,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: context.brand.hairline),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One printed field, at a size a person can read.
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: context.text.labelSmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium
                ?.copyWith(fontFeatures: AppTypography.tabular),
          ),
        ),
        if (trailing case final t?)
          Text(
            t,
            style: context.text.labelSmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// The wide tile, stats variant: how far through the set, as a ring.
class _ProgressTile extends StatelessWidget {
  const _ProgressTile({required this.stats});

  final LockerStats stats;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        spacing: 18,
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: stats.completion,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: context.colors.surfaceContainerHigh,
                    valueColor:
                        AlwaysStoppedAnimation(context.colors.onSurface),
                  ),
                ),
                Text(
                  '${(stats.completion * 100).round()}%',
                  style: context.text.labelMedium
                      ?.copyWith(fontFeatures: AppTypography.tabular),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  'THE SET',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    letterSpacing: 1.3,
                  ),
                ),
                Text('${stats.owned} of ${stats.total} collected',
                    style: context.text.titleMedium),
                Text(
                  '${stats.total - stats.owned} left to find',
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

class _NothingYetTile extends StatelessWidget {
  const _NothingYetTile();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        spacing: 14,
        children: [
          Icon(Icons.style_outlined,
              size: 28, color: context.colors.onSurfaceVariant),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text('No pairs yet', style: context.text.titleSmall),
                Text(
                  'Your first pair starts the collection.',
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

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.headlineSmall
                ?.copyWith(fontFeatures: AppTypography.tabular),
          ),
          Row(
            spacing: 4,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
              if (onTap != null)
                Icon(Icons.edit_outlined,
                    size: 12, color: context.colors.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

/// One surface treatment for every tile, so the grid reads as a grid.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.brand.cardRadius),
        side: BorderSide(color: context.brand.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
