import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/providers/locker_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/motion.dart';
import 'package:sneakers_app/theme/typography.dart';
import 'package:sneakers_app/view/locker/widgets/card_detail_sheet.dart';
import 'package:sneakers_app/view/locker/widgets/settings_sheet.dart';
import 'package:sneakers_app/view/locker/widgets/sneaker_card.dart';

/// The Locker — a binder of collectible cards, one per product.
///
/// Replaces a grouped settings list that was indistinguishable from any other
/// e-commerce account screen. Settings still exist, demoted to a sheet: they
/// are something you occasionally need, not what the page is *about*.
///
/// Unowned cards render as locked slots showing only their set number. That
/// gap is the point — an incomplete set is what makes a set worth completing.
class LockerScreen extends ConsumerWidget {
  const LockerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(binderProvider);
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
                      child: Text('The Locker',
                          style: context.text.displaySmall),
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

            SliverToBoxAdapter(child: _StatsBar(stats: stats)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Collection', style: context.text.titleMedium),
                    ),
                    Text(
                      'tap a card to add it',
                      style: context.text.bodySmall
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 18,
                  // Matches the card's own 63:88 trading-card proportions.
                  childAspectRatio: 63 / 88,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final slot = slots[i];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        showCardDetailSheet(context, slot);
                      },
                      child: SneakerCard(
                        product: slot.product,
                        meta: slot.meta,
                        owned: slot.owned,
                      ).enter(context, index: i.clamp(0, 6)),
                    );
                  },
                  childCount: slots.length,
                ),
              ),
            ),
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
                  valueColor:
                      AlwaysStoppedAnimation(context.colors.onSurface),
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
