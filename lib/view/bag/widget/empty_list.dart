import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/motion.dart';

/// Empty bag.
///
/// Built with the shared motion helper rather than the project's original
/// `FadeAnimation` widget, which wrapped `simple_animations` around a hardcoded
/// 500ms and ignored the reduced-motion setting entirely.
class EmptyList extends StatelessWidget {
  const EmptyList({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 56,
              color: context.colors.onSurfaceVariant,
            ).enter(context),
            Text('Your bag is empty', style: context.text.headlineSmall)
                .enter(context, index: 1),
            Text(
              'Saved something you liked? It will be waiting here.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ).enter(context, index: 2),
            const SizedBox(height: 6),
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
