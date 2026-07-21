import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:sneakers_app/providers/auth_provider.dart';
import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/providers/locker_provider.dart';
import 'package:sneakers_app/providers/orders_provider.dart';
import 'package:sneakers_app/providers/profile_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/locker/widgets/settings_sheet.dart';
import 'package:sneakers_app/view/profile/widget/account_tile.dart';
import 'package:sneakers_app/view/profile/widgets/showcase_picker.dart';
import 'package:sneakers_app/view/profile/widgets/size_sheet.dart';
import 'package:sneakers_app/view/profile/widgets/stat_tiles.dart';

/// Profile.
///
/// Identity, then the collection as a grid of small facts, then the account as
/// grouped rows. The card is one tile among several — it already has a whole
/// screen of its own at [Routes.lockerPath], and a profile should answer "who
/// is this person" before "what does their card look like".
///
/// Every figure is counted from the catalogue and this shopper's own order
/// history. Rows that need a backend say so plainly rather than showing a
/// convincing empty state that implies the feature exists.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider);
    final stats = ref.watch(lockerStatsProvider);
    final orders = ref.watch(ordersProvider);
    final cartCount = ref.watch(cartCountProvider);

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
                      tooltip: 'Choose what leads',
                      color: context.colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _Identity()),
            const SliverToBoxAdapter(child: ProfileTiles()),
            _Group(
              title: 'Collection',
              children: [
                AccountTile(
                  icon: Icons.style_outlined,
                  title: 'The Locker',
                  subtitle: stats.isEmpty
                      ? 'Cards you earn by buying'
                      : '${stats.owned} of ${stats.total} collected',
                  onTap: () => context.push(Routes.lockerPath),
                ),
                AccountTile(
                  icon: Icons.favorite_border,
                  title: 'Wishlist',
                  subtitle: signedIn ? 'Saved for later' : 'Sign in to save',
                  enabled: signedIn,
                  onTap: () {},
                ),
              ],
            ),
            _Group(
              title: 'Orders',
              children: [
                AccountTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Order history',
                  subtitle: orders.isEmpty
                      ? 'No orders yet'
                      : '${orders.length} placed',
                  enabled: signedIn && orders.isNotEmpty,
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
            _Group(
              title: 'Account',
              children: [
                AccountTile(
                  icon: Icons.straighten,
                  title: 'Size & fit',
                  subtitle: _sizeSubtitle(ref),
                  onTap: () => showSizeSheet(context),
                ),
                // Deliberately honest: these need a server, and a polished
                // "no saved addresses" screen would imply one exists.
                const AccountTile(
                  icon: Icons.location_on_outlined,
                  title: 'Addresses',
                  subtitle: 'Not set up yet',
                  enabled: false,
                ),
                const AccountTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payment',
                  subtitle: 'Not set up yet',
                  enabled: false,
                ),
                AccountTile(
                  icon: Icons.settings_outlined,
                  title: 'Preferences',
                  subtitle: 'Appearance and notifications',
                  onTap: () => showSettingsSheet(context),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
                child: Text(
                  'SneakFreaks · v0.1.0',
                  style: context.text.labelSmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sizeSubtitle(WidgetRef ref) {
    final size = ref.watch(profileSizeProvider);
    if (size == null) return 'Not set';
    return ref.watch(preferredSizeProvider) == null
        ? 'UK $size · from what you buy'
        : 'UK $size';
  }
}

/// Who you are, in one row.
///
/// The signed-out call to action is a chip beside the name rather than a
/// full-bleed slab: on a dark page a white button that wide becomes the loudest
/// thing on screen, and a profile is not a checkout.
class _Identity extends ConsumerWidget {
  const _Identity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider);
    final tier = ref.watch(collectorTierProvider);
    final since = ref.watch(memberSinceProvider);
    final size = ref.watch(profileSizeProvider);

    // Built from facts that exist. There is no handle until there is an
    // account, and inventing one is not a placeholder, it is a lie.
    final line = [
      if (signedIn) tier.label,
      if (size != null) 'UK $size',
      if (since != null) 'since ${DateFormat('MMM yyyy').format(since)}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        spacing: 14,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.surfaceContainerHigh,
              border: Border.all(color: context.brand.hairline),
            ),
            child: Icon(Icons.person_outline,
                color: context.colors.onSurfaceVariant),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  signedIn ? tier.label : 'Guest',
                  style: context.text.titleLarge,
                ),
                Text(
                  // No "not signed in" suffix: the button beside it already
                  // says that, and the pair together overran the row.
                  line.isEmpty ? 'Sign in to keep your collection' : line,
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
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: context.text.labelMedium,
              ),
              child: const Text('Sign in'),
            ),
        ],
      ),
    );
  }
}

/// A titled group of account rows.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                title.toUpperCase(),
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  letterSpacing: 1.3,
                ),
              ),
            ),
            Material(
              color: context.colors.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.brand.cardRadius),
                side: BorderSide(color: context.brand.hairline),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }
}
