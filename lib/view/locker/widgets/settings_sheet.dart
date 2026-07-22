import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/providers/auth_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/profile/widget/account_tile.dart';
import 'package:sneakers_app/widget/appearance_tile.dart';

/// Account and settings, demoted to a sheet.
///
/// These still matter — they are just not what an account page should be
/// *about*. Same honesty rules as before: rows that need an account are
/// visibly disabled rather than silently inert.
void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const _Settings(),
  );
}

class _Settings extends ConsumerWidget {
  const _Settings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: context.text.titleLarge),
              const SizedBox(height: 14),
              if (!signedIn)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        'Sign in to track orders, save addresses and sync your '
                        'collection across devices.',
                        style: context.text.bodySmall
                            ?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push(Routes.signIn);
                        },
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              AccountTile(
                icon: Icons.receipt_long_outlined,
                title: 'Orders',
                subtitle: signedIn ? 'Track and return' : 'Sign in to view',
                enabled: signedIn,
                onTap: () {},
              ),
              AccountTile(
                icon: Icons.location_on_outlined,
                title: 'Addresses',
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
              const Divider(height: 24),
              const AppearanceTile(),
              const AccountTile(
                icon: Icons.translate,
                title: 'Language',
                subtitle: 'English (India)',
              ),
              const AccountTile(
                icon: Icons.help_outline,
                title: 'Help centre',
              ),
              if (signedIn)
                AccountTile(
                  icon: Icons.logout,
                  title: 'Sign out',
                  destructive: true,
                  onTap: () {
                    ref.read(authProvider.notifier).signOut();
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'SneakFreaks · v0.1.0',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
