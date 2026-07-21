import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/providers/auth_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';

/// Sign-in placeholder.
///
/// Reached only via the router's guard. Real auth is a later phase; what this
/// proves today is that the guard fires and that intent survives it — sign in
/// and you land where you were headed, not on the home feed.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 14,
            children: [
              Icon(Icons.lock_outline,
                  size: 44, color: context.colors.onSurfaceVariant),
              Text('Sign in required', style: context.text.titleLarge),
              Text(
                'Auth is not implemented yet. This screen exists so the '
                'checkout guard is real rather than a TODO.',
                textAlign: TextAlign.center,
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              FilledButton(
                onPressed: () {
                  ref.read(authProvider.notifier).signIn();
                  // Hand the user back to what they were trying to reach.
                  context.go(returnTo ?? Routes.home);
                },
                child: const Text('Continue (simulate sign-in)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
