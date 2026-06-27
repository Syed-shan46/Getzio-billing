import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getzio_billing/core/storage/hive_service.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _themeKey = 'selected_theme_mode';

  @override
  ThemeMode build() {
    final hiveService = ref.watch(hiveServiceProvider);
    final storedIndex = hiveService.getPreference(_themeKey, defaultValue: -1);
    if (storedIndex >= 0 && storedIndex < ThemeMode.values.length) {
      return ThemeMode.values[storedIndex];
    }
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    final hiveService = ref.read(hiveServiceProvider);
    hiveService.savePreference(_themeKey, mode.index);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
