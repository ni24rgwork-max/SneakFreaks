import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/theme_controller.dart';

/// Light / Dark / System appearance control, persisted across restarts.
///
/// System is the default and is offered explicitly rather than being implied by
/// "dark off" — a two-state switch cannot express "follow the OS".
class AppearanceTile extends ConsumerWidget {
  const AppearanceTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        spacing: 12,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: context.colors.surfaceContainerHigh,
            child: Icon(
              Icons.contrast,
              color: context.colors.onSurface,
            ),
          ),
          Expanded(
            child: Text('Appearance', style: context.text.titleMedium),
          ),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              textStyle: context.text.labelMedium,
              visualDensity: VisualDensity.compact,
            ),
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: 17),
                tooltip: 'Light',
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: 17),
                tooltip: 'Dark',
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined, size: 17),
                tooltip: 'System',
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => controller.setMode(s.first),
          ),
        ],
      ),
    );
  }
}
