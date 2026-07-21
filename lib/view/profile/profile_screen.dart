import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/providers/auth_provider.dart';
import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/profile/widget/account_tile.dart';
import 'package:sneakers_app/widget/appearance_tile.dart';

/// Account screen.
///
/// Rebuilt from a page that showed a hardcoded "John Doe", a stock avatar of a
/// stranger, and a presence picker (Away / Working / Gaming / Do not disturb)
/// carried over from a chat-app tutorial. None of that belongs in a storefront.
///
/// It now reflects the real session: signed out shows a sign-in prompt and only
/// the settings that work without an account. Showing a fake identity to a
/// signed-out user is worse than showing none.
class Profile extends ConsumerWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text('Account', style: context.text.displaySmall),
              ),
            ),
            SliverToBoxAdapter(
              child: signedIn
                  ? const _SignedInHeader()
                  : const _SignedOutHeader(),
            ),
            SliverToBoxAdapter(
              child: _Group(
                title: 'Shopping',
                children: [
                  AccountTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Orders',
                    subtitle: signedIn ? 'Track and return' : 'Sign in to view',
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
            SliverToBoxAdapter(
              child: _Group(
                title: 'Delivery & payment',
                children: [
                  AccountTile(
                    icon: Icons.location_on_outlined,
                    title: 'Addresses',
                    subtitle:
                        signedIn ? 'Manage delivery addresses' : 'Sign in to add',
                    enabled: signedIn,
                    onTap: () {},
                  ),
                  AccountTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Payment methods',
                    subtitle: 'UPI, cards, netbanking, COD',
                    enabled: signedIn,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(
              child: _Group(
                title: 'Preferences',
                children: [
                  AppearanceTile(),
                  AccountTile(
                    icon: Icons.translate,
                    title: 'Language',
                    subtitle: 'English (India)',
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _Group(
                title: 'Support',
                children: [
                  const AccountTile(
                    icon: Icons.help_outline,
                    title: 'Help centre',
                  ),
                  const AccountTile(
                    icon: Icons.description_outlined,
                    title: 'Terms & privacy',
                  ),
                  if (signedIn)
                    AccountTile(
                      icon: Icons.logout,
                      title: 'Sign out',
                      destructive: true,
                      onTap: () => ref.read(authProvider.notifier).signOut(),
                    ),
                ],
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

class _SignedOutHeader extends ConsumerWidget {
  const _SignedOutHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.brand.cardRadius),
        border: Border.all(color: context.brand.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text('You are not signed in', style: context.text.titleMedium),
          Text(
            'Sign in to track orders, save addresses and keep your wishlist '
            'across devices.',
            style: context.text.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          FilledButton(
            onPressed: () => context.push(Routes.signIn),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

class _SignedInHeader extends StatelessWidget {
  const _SignedInHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        spacing: 14,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: context.colors.primary,
            // No stock photo of a stranger standing in for the user.
            child: Icon(Icons.person, color: context.colors.onPrimary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text('Signed in', style: context.text.titleMedium),
                Text(
                  'Profile details arrive with the auth backend',
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

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                letterSpacing: 1.1,
              ),
            ),
          ),
          // Material rather than a decorated Container: ListTile paints its
          // ink splash on the nearest Material ancestor, and a coloured box in
          // between hides the ripple entirely.
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
    );
  }
}
