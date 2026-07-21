import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/routing/routes.dart';

import 'package:sneakers_app/theme/app_theme.dart';

PreferredSizeWidget customAppBar(BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(70),
    child: AppBar(
      backgroundColor: Colors.transparent,
      title: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text('SneakFreaks', style: context.text.displaySmall),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: IconButton(
            icon: const Icon(CupertinoIcons.search, size: 25),
            color: context.colors.onSurface,
            onPressed: () => context.push('/${Routes.search}'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 4),
          child: IconButton(
            icon: const Icon(CupertinoIcons.bell, size: 25),
            color: context.colors.onSurface,
            onPressed: () {},
          ),
        ),
      ],
    ),
  );
}
