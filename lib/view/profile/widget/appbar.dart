import 'package:flutter/material.dart';

import 'package:sneakers_app/theme/app_theme.dart';

PreferredSizeWidget customAppBarProfile(BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: AppBar(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      title: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text('My Profile', style: context.text.titleLarge),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 5),
          child: Icon(Icons.more_vert, color: context.colors.onSurface),
        ),
      ],
    ),
  );
}
