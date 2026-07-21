import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/providers/locker_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/motion.dart';
import 'package:sneakers_app/theme/typography.dart';
import 'package:sneakers_app/view/locker/widgets/card_detail_sheet.dart';
import 'package:sneakers_app/view/locker/widgets/settings_sheet.dart';
import 'package:sneakers_app/view/locker/widgets/sneaker_card.dart';

/// The Locker — cards for pairs the shopper actually bought.
///
/// There is no locked or browsable state. An unearned card is simply absent: a
/// binder showing everything you *could* own is a catalogue, and only a binder
/// showing what you *do* own is a collection.
///
/// Settings live in a sheet. They are something you occasionally need, not what
/// the page is about.
class LockerScreen extends ConsumerWidget {
  const LockerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(lockerProvider);
    final stats = ref.watch(lockerStatsProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          Text('The Locker', style: context.text.displaySmall),
                    ),
                    IconButton(
                      onPressed: () => showSettingsSheet(context),
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Settings',
                      color: context.colors.onSurface,
                    ),
                  ],
                ),
              ),
            ),

            if (stats.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyLocker(),
              )
            else ...[
              SliverToBoxAdapter(child: _StatsBar(stats: stats)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 18,
                    // Matches the card's own trading-card proportions.
                    childAspectRatio: 63 / 88,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final card = cards[i];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          showCardDetailSheet(context, card);
                        },
                        child: SneakerCard(
                          product: card.product,
                          meta: card.meta,
                        ).enter(context, index: i.clamp(0, 6)),
                      );
                    },
                    childCount: cards.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state.
///
/// Says plainly how cards are earned. An empty collection that does not explain
/// itself reads as a broken screen.
class _EmptyLocker extends StatelessWidget {
  const _EmptyLocker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 20, 36, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Icon(Icons.style_outlined,
                    size: 54, color: context.colors.onSurfaceVariant)
                .enter(context),
            Text('No cards yet', style: context.text.headlineSmall)
                .enter(context, index: 1),
            Text(
              'Every pair you buy becomes a card here. Rarity follows the '
              'price, and the set has 8 to collect.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ).enter(context, index: 2),
            const SizedBox(height: 4),
            FilledButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Browse the store'),
            ).enter(context, index: 3),
          ],
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.stats});

  final LockerStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.brand.cardRadius),
        border: Border.all(color: context.brand.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Row(
            children: [
              _Stat(value: '${stats.owned}', label: 'pairs'),
              _Stat(value: '${stats.brands}', label: 'brands'),
              _Stat(
                value: stats.rarest?.label ?? '—',
                label: 'rarest',
                wide: true,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Set completion',
                      style: context.text.bodySmall
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    '${stats.owned}/${stats.total}',
                    style: context.text.labelMedium
                        ?.copyWith(fontFeatures: AppTypography.tabular),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: stats.completion,
                  minHeight: 5,
                  backgroundColor: context.colors.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation(context.colors.onSurface),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.wide = false});

  final String value;
  final String label;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: wide ? 2 : 1,
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
          Text(
            label,
            style: context.text.labelSmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
