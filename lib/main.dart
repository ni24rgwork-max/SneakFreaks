import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sneakers_app/data/preferences.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/theme_controller.dart';
import 'package:sneakers_app/view/navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      // Loaded once up front so the rest of the tree reads preferences
      // synchronously, instead of every consumer handling a loading state.
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sneakers Shop',
      theme: AppTheme.of(Brightness.light),
      darkTheme: AppTheme.of(Brightness.dark),
      themeMode: ref.watch(themeControllerProvider),
      home: const MainNavigator(),
    );
  }
}
