import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/home/components/product_card.dart';

/// Editorial collection listing — the destination for the home banner's
/// "Explore" action, which until now went nowhere.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(collectionProvider(tag));
    final title = tag[0].toUpperCase() + tag.substring(1);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.isEmpty
          ? Center(
              child: Text(
                'Nothing in this collection yet',
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 14,
                childAspectRatio: 0.64,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => ProductCard(product: items[i]),
            ),
    );
  }
}
