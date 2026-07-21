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
/// The Locker is a *section* here, not the whole page — and which section leads
/// is the user's call via [ProfileShowcase]. A profile is the one screen a
/// person might reasonably want to arrange, so the hero is theirs to pick
/// rather than ours to assume.
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
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Profile', style: context.text.displaySmall),
                    ),
                    IconButton(
                      onPressed: () => showShowcasePicker(context),
                      icon: const Icon(Icons.tune),
                      tooltip: 'Choose showcase',
                      color: context.colors.onSurface,
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

            SliverToBoxAdapter(
              child:
                  _Identity(signedIn: signedIn, tier: tier, pairs: stats.owned),
            ),

            // ── Showcase: whichever the user chose ──
            if (showcase != ProfileShowcase.minimal)
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(child: ProfileShowcaseView()),

            // ── The Locker, as a section ──
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'The Locker',
                subtitle: stats.isEmpty
                    ? 'Cards you earn by buying'
                    : '${stats.owned} of ${stats.total} collected',
                onTap: () => context.push(Routes.lockerPath),
              ),
            ),
            // Never a rail of every card. The profile shows at most one — the
            // one the user picked — and the section reports what the binder
            // holds. The binder itself is a tap away.
            if (stats.isEmpty)
              const SliverToBoxAdapter(child: _LockerEmpty())
            else
              SliverToBoxAdapter(child: _BinderSummary(stats: stats)),

            // ── Activity ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
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
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
                child: Text(
                  'SneakFreaks · v0.1.0',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(
            spacing: 14,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: context.colors.primary,
                // No stock photo of a stranger standing in for the user.
                child: Icon(Icons.person, color: context.colors.onPrimary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Text(
                      signedIn ? tier.label : 'Not signed in',
                      style: context.text.titleLarge,
                    ),
                    Text(
                      signedIn
                          ? (toNext == null
                              ? 'Top tier'
                              : '$toNext more ${toNext == 1 ? 'pair' : 'pairs'} to '
                                  '${CollectorTier.values[tier.index + 1].label}')
                          : 'Sign in to keep your collection across devices',
                      style: context.text.bodySmall
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Full-width beneath the row rather than inline: the theme styles
          // buttons at full bleed, and a Row gives non-flex children unbounded
          // width, so an inline one asserts.
          if (!signedIn)
            FilledButton(
              onPressed: () => context.push(Routes.signIn),
              child: const Text('Sign in'),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(title, style: context.text.headlineSmall),
                Text(
                  subtitle,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Open $title',
            color: context.colors.onSurface,
          ),
        ],
      ),
    );
  }
}

/// The Locker section when the cards themselves are already the showcase.
///
/// Set completion, the rarest card held and the brand spread — the three things
/// a collector checks that a wall of card art does not answer at a glance.
class _BinderSummary extends StatelessWidget {
  const _BinderSummary({required this.stats});

  final LockerStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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

class _LockerEmpty extends StatelessWidget {
  const _LockerEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.brand.cardRadius),
        border: Border.all(color: context.brand.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text('No cards yet', style: context.text.titleSmall),
          Text(
            'Every pair you buy becomes a card. There are 8 in the set.',
            style: context.text.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          OutlinedButton(
            onPressed: () => context.go(Routes.home),
            child: const Text('Browse the store'),
          ),
        ],
      ),
    );
  }
}
