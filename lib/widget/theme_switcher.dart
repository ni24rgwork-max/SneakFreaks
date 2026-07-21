import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/palette.dart';
import 'package:sneakers_app/theme/theme_controller.dart';

/// Temporary comparison control: flips between the two candidate brand
/// palettes and cycles light/dark/system.
///
/// This exists only to evaluate Direction A vs B on-device. Once a palette is
/// chosen, delete this widget and move the light/dark control into Profile.
class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    final modeIcon = switch (settings.mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };

    return Material(
      color: context.colors.surfaceContainerHigh.withValues(alpha: 0.92),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: controller.togglePalette,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.brand.hairline),
                    ),
                  ),
                  Text(
                    settings.palette.label,
                    style: context.text.labelMedium,
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 20, color: context.brand.hairline),
          InkWell(
            onTap: () {
              final next = switch (settings.mode) {
                ThemeMode.system => ThemeMode.light,
                ThemeMode.light => ThemeMode.dark,
                ThemeMode.dark => ThemeMode.system,
              };
              controller.setMode(next);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
              child: Icon(modeIcon, size: 16, color: context.colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
