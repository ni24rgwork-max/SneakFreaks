import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/providers/auth_provider.dart';
import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/providers/locker_provider.dart';
import 'package:sneakers_app/providers/orders_provider.dart';
import 'package:sneakers_app/providers/profile_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/typography.dart';
import 'package:sneakers_app/view/locker/widgets/settings_sheet.dart';
import 'package:sneakers_app/view/profile/widget/account_tile.dart';
import 'package:sneakers_app/view/profile/widgets/showcase.dart';
import 'package:sneakers_app/view/profile/widgets/showcase_picker.dart';

/// Profile.
///
/// Four blocks, not six: who you are, the one card you chose, what your binder
/// holds, and what you can do. The Locker is a *section* here — the binder
/// itself lives at [Routes.lockerPath].
///
/// Which block leads is the user's call via [ProfileShowcase]. A profile is the
/// one screen a person might reasonably want to arrange, so the hero is theirs
/// to pick rather than ours to assume.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider);
    final tier = ref.watch(collectorTierProvider);
    final stats = ref.watch(lockerStatsProvider);
    final orders = ref.watch(ordersProvider);
    final cartCount = ref.watch(cartCountProvider);
    final showcase = ref.watch(profileShowcaseProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Profile', style: context.text.displaySmall),
                    ),
                    IconButton(
                      onPressed: () => showShowcasePicker(context),
                      icon: const Icon(Icons.tune),
                      tooltip: 'Choose showcase',
                      color: context.colors.onSurfaceVariant,
                    ),
                    IconButton(
                      onPressed: () => showSettingsSheet(context),
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Settings',
                      color: context.colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child:
                  _Identity(signedIn: signedIn, tier: tier, pairs: stats.owned),
            ),

            // ── Whichever block the user chose to lead ──
            const SliverToBoxAdapter(child: ProfileShowcaseView()),

            // ── The Locker, as a section ──
            SliverToBoxAdapter(child: _LockerSection(stats: stats)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Material(
                  color: context.colors.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(context.brand.cardRadius),
                    side: BorderSide(color: context.brand.hairline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      AccountTile(
                        icon: Icons.receipt_long_outlined,
                        title: 'Orders',
                        subtitle: orders.isEmpty
                            ? 'No orders yet'
                            : '${orders.length} placed',
                        enabled: signedIn,
                        onTap: () {},
                      ),
                      AccountTile(
                        icon: Icons.favorite_border,
                        title: 'Wishlist',
                        subtitle: 'Saved for later',
                        enabled: signedIn,
                        onTap: () {},
                      ),
                      AccountTile(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Bag',
                        subtitle: cartCount == 0
                            ? 'Empty'
                            : '$cartCount item${cartCount == 1 ? '' : 's'}',
                        onTap: () => context.go(Routes.bag),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                child: Text(
                  'SneakFreaks · v0.1.0',
                  style: context.text.labelSmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
            ),

            if (showcase == ProfileShowcase.minimal)
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }
}

/// Who you are, in one line.
///
/// The signed-out call to action is a chip beside the name rather than a
/// full-bleed slab: on a dark page a white button that wide becomes the loudest
/// thing on screen, which is not what a profile is about.
class _Identity extends StatelessWidget {
  const _Identity({
    required this.signedIn,
    required this.tier,
    required this.pairs,
  });

  final bool signedIn;
  final CollectorTier tier;
  final int pairs;

  @override
  Widget build(BuildContext context) {
    final toNext = tier.pairsToNext(pairs);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Row(
        spacing: 14,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.surfaceContainerHigh,
              border: Border.all(color: context.brand.hairline),
            ),
            // No stock photo of a stranger standing in for the user.
            child: Icon(Icons.person_outline,
                color: context.colors.onSurfaceVariant),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  signedIn ? tier.label : 'Guest',
                  style: context.text.titleMedium,
                ),
                Text(
                  signedIn
                      ? (toNext == null
                          ? 'Top tier'
                          : '$toNext more ${toNext == 1 ? 'pair' : 'pairs'} to '
                              '${CollectorTier.values[tier.index + 1].label}')
                      : 'Sign in to keep your collection',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (!signedIn)
            FilledButton(
              onPressed: () => context.push(Routes.signIn),
              // The theme styles buttons full-bleed; this one sits in a row.
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                textStyle: context.text.labelMedium,
              ),
              child: const Text('Sign in'),
            ),
        ],
      ),
    );
  }
}

/// The Locker in one tappable panel: what you hold, how far through the set,
/// and a way in. The binder itself is a screen, not a section.
class _LockerSection extends StatelessWidget {
  const _LockerSection({required this.stats});

  final LockerStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Material(
        color: context.colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.brand.cardRadius),
          side: BorderSide(color: context.brand.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(Routes.lockerPath),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          Text('The Locker', style: context.text.headlineSmall),
                    ),
                    Icon(Icons.arrow_forward,
                        size: 20, color: context.colors.onSurfaceVariant),
                    const SizedBox(width: 6),
                  ],
                ),
                if (stats.isEmpty)
                  Text(
                    'Every pair you buy becomes a card. There are '
                    '${stats.total} in the set.',
                    style: context.text.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  )
                else ...[
                  Text(
                    '${stats.owned} of ${stats.total} collected · '
                    '${stats.brands} ${stats.brands == 1 ? 'brand' : 'brands'}'
                    '${stats.rarest == null ? '' : ' · ${stats.rarest!.label} rarest'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: stats.completion,
                            minHeight: 5,
                            backgroundColor:
                                context.colors.surfaceContainerHigh,
                            valueColor: AlwaysStoppedAnimation(
                                context.colors.onSurface),
                          ),
                        ),
                      ),
                      Text(
                        '${stats.owned}/${stats.total}',
                        style: context.text.labelMedium
                            ?.copyWith(fontFeatures: AppTypography.tabular),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
