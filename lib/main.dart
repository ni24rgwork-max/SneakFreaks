import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/theme_controller.dart';
import 'package:sneakers_app/data/dummy_data.dart';
import 'package:sneakers_app/view/detail/detail_screen.dart';
import 'package:sneakers_app/view/dev/token_preview.dart';
import 'package:sneakers_app/view/navigator.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sneakers Shop',
      theme: AppTheme.of(settings.palette, Brightness.light),
      darkTheme: AppTheme.of(settings.palette, Brightness.dark),
      themeMode: settings.mode,
      // Demo affordance: --dart-define=SCREEN=detail opens a PDP directly so
      // the primary-CTA colour can be compared across palettes. Delete with
      // the ThemeSwitcher.
      home: switch (const String.fromEnvironment('SCREEN')) {
        'detail' => DetailScreen(
            model: availableShoes.first,
            isComeFromMoreSection: false,
          ),
        'tokens' => const TokenPreview(),
        _ => const MainNavigator(),
      },
    );
  }
}
