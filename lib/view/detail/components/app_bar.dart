import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/theme/app_theme.dart';

/// [brand] is passed in rather than hardcoded to "Nike" — this is a
/// multi-brand storefront, so the detail header must follow the product.
PreferredSizeWidget customAppBarDe(BuildContext context, String brand) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: AppBar(
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Text(brand, style: context.text.titleLarge),
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
        color: context.colors.onSurface,
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.favorite_border),
          color: context.colors.onSurface,
        ),
      ],
    ),
  );
}
