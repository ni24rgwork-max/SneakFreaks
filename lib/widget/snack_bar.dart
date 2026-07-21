import 'package:flutter/material.dart';

import 'package:sneakers_app/theme/app_theme.dart';

SnackBar successSnackBar(BuildContext context) => SnackBar(
      content: const Text('Successfully added to your bag'),
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'View bag',
        textColor: context.brand.success,
        onPressed: () {},
      ),
    );

SnackBar failedSnackBar(BuildContext context) => SnackBar(
      content: const Text('This item is already in your bag'),
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'Got it',
        textColor: context.colors.inversePrimary,
        onPressed: () {},
      ),
    );
