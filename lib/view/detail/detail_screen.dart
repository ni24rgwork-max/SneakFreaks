import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/providers/catalogue_provider.dart';
import 'package:sneakers_app/routing/routes.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/view/detail/components/app_bar.dart';
import 'package:sneakers_app/view/detail/components/body.dart';

/// Product detail.
///
/// Takes a **product id**, not a `ShoeModel`. A route has to be
/// reconstructable from a URL string, and an object cannot travel in one — so
/// `/product/sku-001` arriving from a push notification, a shared link or a
/// payment-gateway return resolves the product here.
class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId));

    // A deep link can name a product that has been delisted, or simply be
    // mistyped. Say so instead of throwing.
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 44, color: context.colors.onSurfaceVariant),
                Text('This product is no longer available',
                    textAlign: TextAlign.center,
                    style: context.text.titleMedium),
                FilledButton(
                  onPressed: () => context.go(Routes.home),
                  child: const Text('Browse the store'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: customAppBarDe(context, product.name),
        body: DetailsBody(model: product, isComeFromMoreSection: false),
      ),
    );
  }
}
