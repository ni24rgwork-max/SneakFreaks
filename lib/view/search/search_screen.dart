import 'package:flutter/material.dart';

import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/motion.dart';

/// Search — route and entry point only.
///
/// Intentionally unimplemented. Per docs/AI.md this becomes the conversational
/// search surface ("something for monsoon running under ₹12,000"), which needs
/// a backend holding the API key. The route exists now so the entry point is
/// addressable and deep-linkable before that lands.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Icon(Icons.auto_awesome_outlined,
                      size: 44, color: context.colors.onSurfaceVariant)
                  .enter(context),
              Text('Conversational search', style: context.text.titleLarge)
                  .enter(context, index: 1),
              Text(
                'Not built yet. This is where natural-language search will '
                'live — see docs/AI.md.',
                textAlign: TextAlign.center,
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ).enter(context, index: 2),
            ],
          ),
        ),
      ),
    );
  }
}
