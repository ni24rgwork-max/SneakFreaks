import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'palette.dart';

@immutable
class ThemeSettings {
  const ThemeSettings({
    this.palette = AppPalette.ink,
    this.mode = ThemeMode.system,
  });

  final AppPalette palette;
  final ThemeMode mode;

  ThemeSettings copyWith({AppPalette? palette, ThemeMode? mode}) =>
      ThemeSettings(palette: palette ?? this.palette, mode: mode ?? this.mode);
}

class ThemeController extends Notifier<ThemeSettings> {
  // Launch-time overrides so the palette/brightness combinations can be
  // captured deterministically:
  //   flutter run --dart-define=PALETTE=saffron --dart-define=MODE=dark
  // Demo affordance only — delete with the ThemeSwitcher.
  static const _paletteOverride = String.fromEnvironment('PALETTE');
  static const _modeOverride = String.fromEnvironment('MODE');

  @override
  ThemeSettings build() => ThemeSettings(
        palette: switch (_paletteOverride) {
          'saffron' => AppPalette.saffron,
          'ink' => AppPalette.ink,
          _ => AppPalette.ink,
        },
        mode: switch (_modeOverride) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
      );

  void setPalette(AppPalette palette) =>
      state = state.copyWith(palette: palette);

  void setMode(ThemeMode mode) => state = state.copyWith(mode: mode);

  void togglePalette() => setPalette(
        state.palette == AppPalette.ink ? AppPalette.saffron : AppPalette.ink,
      );
}

/// `ThemeMode.system` is the default on purpose — ignoring the OS setting reads
/// as a broken app on both platforms.
///
/// TODO(phase-3): persist to shared_preferences/hive so the choice survives a
/// restart. Left in memory while the palettes are still being compared.
final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);
