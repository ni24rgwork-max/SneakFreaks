import 'package:flutter/material.dart';

import 'package:sneakers_app/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.headlineSmall),
                if (subtitle case final s?)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      s,
                      style: context.text.bodySmall
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
          if (onSeeAll != null)
            IconButton(
              onPressed: onSeeAll,
              icon: const Icon(Icons.arrow_forward),
              color: context.colors.onSurface,
              tooltip: 'See all $title',
            ),
        ],
      ),
    );
  }
}
