import 'package:flutter/material.dart';

import 'package:sneakers_app/animation/fadeanimation.dart';
import 'package:sneakers_app/theme/app_theme.dart';

class EmptyList extends StatelessWidget {
  const EmptyList({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 56,
              color: context.colors.onSurfaceVariant,
            ),
            FadeAnimation(
              delay: 0.5,
              child: Text('No shoes added!', style: context.text.headlineSmall),
            ),
            FadeAnimation(
              delay: 0.5,
              child: Text(
                'Once you have added, come back:)',
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
